#!/usr/bin/env python3

import os
import shlex
import subprocess


XCODEBUILD = '/usr/bin/xcodebuild'

XLIFF_URL = 'urn:oasis:names:tc:xliff:document:1.2'

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class CommandError(Exception):
    pass


def execute(*args, cwd=None):
    proc = subprocess.run(
        args,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding='utf-8',
    )
    if proc.returncode:
        if hasattr(shlex, 'join'):
            cmd = shlex.join(args)
        else:
            cmd = ' '.join(map(str, args))
        raise CommandError(
            '"{cmd}" failed with error {code}.\n {output}'.format(
                cmd=cmd,
                code=proc.returncode,
                output=proc.stderr,
            )
        )
    return proc.stdout
