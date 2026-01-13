//
//  MPDocument+Observers.m
//  MacDown
//

#import "MPDocument_Private.h"

#import <WebKit/WebKit.h>

#import "HGMarkdownHighlighter.h"
#import "MPDocument+Actions.h"
#import "MPEditorView.h"
#import "MPRenderer.h"
#import "MPScrollSyncController.h"

#import "MPPreferences.h"
#import "MPPreferences+Hoedown.h"
#import "MPPreferencesViewController.h"
#import "MPEditorPreferencesViewController.h"

@implementation MPDocument (Observers)

#pragma mark - Observers

- (void)registerObservers
{
    MPPreferences *preferences = self.preferences;
    for (NSString *key in MPPreferencesKeysToObserve())
    {
        [preferences addObserver:self forKeyPath:key
                         options:NSKeyValueObservingOptionNew context:NULL];
    }
    for (NSString *key in MPEditorKeysToObserve())
    {
        [self.editor addObserver:self forKeyPath:key
                         options:NSKeyValueObservingOptionNew context:NULL];
    }

    NSScrollView *editorScrollView = self.editor.enclosingScrollView;
    NSClipView *editorClipView = editorScrollView.contentView;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(editorTextDidChange:)
                   name:NSTextDidChangeNotification object:self.editor];
    [center addObserver:self selector:@selector(editorBoundsDidChange:)
                   name:NSViewBoundsDidChangeNotification
                 object:editorClipView];
    [center addObserver:self selector:@selector(editorFrameDidChange:)
                   name:NSViewFrameDidChangeNotification object:self.editor];
    [center addObserver:self selector:@selector(didRequestEditorReload:)
                   name:MPDidRequestEditorSetupNotification object:nil];
    [center addObserver:self selector:@selector(didRequestPreviewReload:)
                   name:MPDidRequestPreviewRenderNotification object:nil];
    [center addObserver:self selector:@selector(willStartLiveScroll:)
                   name:NSScrollViewWillStartLiveScrollNotification
                 object:editorScrollView];
    [center addObserver:self selector:@selector(didEndLiveScroll:)
                   name:NSScrollViewDidEndLiveScrollNotification
                 object:editorScrollView];
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9)
    {
        NSScrollView *previewScrollView = self.preview.enclosingScrollView;
        [center addObserver:self selector:@selector(previewDidLiveScroll:)
                       name:NSScrollViewDidEndLiveScrollNotification
                     object:previewScrollView];
    }
}

- (void)unregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    MPPreferences *preferences = self.preferences;
    for (NSString *key in MPPreferencesKeysToObserve())
        [preferences removeObserver:self forKeyPath:key];
    for (NSString *key in MPEditorKeysToObserve())
        [self.editor removeObserver:self forKeyPath:key];
}

#pragma mark - Notification handlers

- (void)editorTextDidChange:(NSNotification *)notification
{
    if (self.needsHtml)
        [self.renderer parseAndRenderLater];
}

- (void)renderingPreferencesDidChange
{
    MPRenderer *renderer = self.renderer;
    if (!renderer)
        return;

    // Force update if we're switching from manual to auto, or renderer settings
    // changed.
    int rendererFlags = self.preferences.rendererFlags;
    if ((!self.preferences.markdownManualRender && self.manualRender)
            || renderer.rendererFlags != rendererFlags)
    {
        renderer.rendererFlags = rendererFlags;
        [renderer parseAndRenderLater];
    }
    else
    {
        [renderer parseAndRenderIfNeeded];
    }
}

- (void)editorFrameDidChange:(NSNotification *)notification
{
    if (self.preferences.editorWidthLimited)
        [self adjustEditorInsets];
}

- (void)willStartLiveScroll:(NSNotification *)notification
{
    [self.scrollSyncController updateHeaderLocations];
    self.inLiveScroll = YES;
}

- (void)didEndLiveScroll:(NSNotification *)notification
{
    self.inLiveScroll = NO;
}

- (void)editorBoundsDidChange:(NSNotification *)notification
{
    if (!self.shouldHandleBoundsChange)
        return;

    if (self.preferences.editorSyncScrolling)
    {
        @synchronized(self)
        {
            self.shouldHandleBoundsChange = NO;
            if (!self.inLiveScroll)
            {
                [self.scrollSyncController updateHeaderLocations];
            }

            [self.scrollSyncController syncScrollers];
            self.shouldHandleBoundsChange = YES;
        }
    }
}

- (void)didRequestEditorReload:(NSNotification *)notification
{
    NSString *key =
        notification.userInfo[MPDidRequestEditorSetupNotificationKeyName];
    [self setupEditor:key];
}

- (void)didRequestPreviewReload:(NSNotification *)notification
{
    [self render:nil];
}

- (void)previewDidLiveScroll:(NSNotification *)notification
{
    NSClipView *contentView = self.preview.enclosingScrollView.contentView;
    self.lastPreviewScrollTop = contentView.bounds.origin.y;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (object == self.editor)
    {
        if (!self.highlighter.isActive)
            return;
        id value = change[NSKeyValueChangeNewKey];
        NSString *preferenceKey = MPEditorPreferenceKeyWithValueKey(keyPath);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:value forKey:preferenceKey];
    }
    else if (object == self.preferences)
    {
        if (self.highlighter.isActive)
            [self setupEditor:keyPath];

        if (MPPreferenceKeyAffectsDivider(keyPath))
            [self redrawDivider];

        if ([MPPreviewPreferencesToObserve() containsObject:keyPath])
            [self scaleWebview];

        if ([MPRendererPreferencesToObserve() containsObject:keyPath])
            [self renderingPreferencesDidChange];
    }
}

@end
