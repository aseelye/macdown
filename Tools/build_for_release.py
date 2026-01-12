#!/usr/bin/env python3

import argparse
import os
import plistlib
import re
import shutil
import subprocess
import zipfile

from macdown_utils import ROOT_DIR, XCODEBUILD, execute


OPENSSL = '/usr/bin/openssl'
OSASCRIPT = '/usr/bin/osascript'

BUILD_DIR = os.path.join(ROOT_DIR, 'Build')
APP_NAME = 'MacDown.app'
ZIP_NAME = 'MacDown.app.zip'


def print_value(key, value):
    print(f'{key}:\n{value}\n')


def archive_dir(zip_f, root_dir, directory):
    contents = os.listdir(directory)
    if not contents:    # Empty directory.
        archive_name = os.path.relpath(directory, root_dir)
        if not archive_name.endswith('/'):
            archive_name += '/'
        info = zipfile.ZipInfo(archive_name)
        zip_f.writestr(info, '')
    for item in contents:
        full_path = os.path.join(directory, item)
        archive_name = os.path.relpath(full_path, root_dir)
        if os.path.islink(full_path):
            info = zipfile.ZipInfo(archive_name)
            info.create_system = 3
            info.external_attr = 2716663808
            zip_f.writestr(info, os.readlink(full_path))
        elif os.path.isdir(full_path):
            archive_dir(zip_f, root_dir, full_path)
        else:
            zip_f.write(full_path, arcname=archive_name)


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('path_to_pem', help='path to .pem private key')
    return parser.parse_args(argv)


def main(argv=None):
    options = parse_args(argv)
    cert_path = options.path_to_pem
    if not os.path.isfile(cert_path):
        raise SystemExit('Certificate file not found: {}'.format(cert_path))
    cert_path = os.path.abspath(cert_path)
    workspace_path = os.path.join(ROOT_DIR, 'MacDown.xcworkspace')

    print('Pre-build cleaning...')
    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    os.makedirs(BUILD_DIR, exist_ok=True)
    execute(
        XCODEBUILD, 'clean', '-workspace', workspace_path,
        '-scheme', 'MacDown',
        cwd=ROOT_DIR,
    )

    print('Running external scripts...')
    execute(
        'make',
        cwd=os.path.join(ROOT_DIR, 'Dependency', 'peg-markdown-highlight'),
    )

    print('Building application archive...')
    output = execute(
        XCODEBUILD, 'archive', '-workspace', workspace_path,
        '-scheme', 'MacDown',
        cwd=BUILD_DIR,
    )
    match = re.search(
        r'^\s*ARCHIVE_PATH: (.+)$',
        output,
        re.MULTILINE,
    )
    if not match:
        raise RuntimeError('Could not find ARCHIVE_PATH in xcodebuild output.')
    archive_path = match.group(1)

    print('Exporting application bundle...')
    source_app_path = os.path.join(
        archive_path, 'Products', 'Applications', APP_NAME,
    )
    exported_app_path = os.path.join(BUILD_DIR, APP_NAME)
    shutil.copytree(source_app_path, exported_app_path)

    # Zip.
    zip_path = os.path.join(BUILD_DIR, ZIP_NAME)
    with zipfile.ZipFile(zip_path, 'w') as f:
        archive_dir(f, BUILD_DIR, exported_app_path)

    input(
        'Build finished. Press Return to display bundle information and '
        'reveal ZIP archive.'
    )

    print()
    print('DSA signature:')
    command = (
        '{openssl} dgst -sha1 -binary < "{zip_name}" | '
        '{openssl} dgst -dss1 -sign "{cert}" | '
        '{openssl} enc -base64'
    ).format(openssl=OPENSSL, zip_name=zip_path, cert=cert_path)
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        raise SystemExit(
            'OpenSSL signature generation failed (exit {}).'.format(
                e.returncode
            )
        )
    print()

    print_value('Archive size', os.path.getsize(zip_path))

    info_plist_path = os.path.join(exported_app_path, 'Contents', 'Info.plist')
    with open(info_plist_path, 'rb') as plist_file:
        info = plistlib.load(plist_file)
    print_value('Bundle version', info.get('CFBundleVersion'))
    print_value('Short version', info.get('CFBundleShortVersionString'))

    script = 'tell application "Finder" to reveal POSIX file "{zip}"'.format(
        zip=zip_path
    )
    execute(OSASCRIPT, '-e', script)


if __name__ == '__main__':
    main()
