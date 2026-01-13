//
//  MPDocument+Preview.m
//  MacDown
//

#import "MPDocument_Private.h"

#import <WebKit/WebKit.h>

#import "MPEditorView.h"
#import "MPMathJaxListener.h"
#import "MPPreferences.h"
#import "MPPreferences+Hoedown.h"
#import "MPWebKitWorkarounds.h"
#import "MPScrollSyncController.h"
#import "MPRenderer.h"
#import "WebView+MPSugar.h"
#import "NSDocumentController+Document.h"
#import "NSPasteboard+Types.h"
#import "DOMNode+Text.h"
#import "NSString+Lookup.h"

@implementation MPDocument (Preview)

NS_INLINE NSString *MPAbsoluteBaseURLString(NSURL *url)
{
    // Remove fragment (#anchor) and query string.
    NSString *base = url.absoluteString;
    base = [base componentsSeparatedByString:@"?"].firstObject;
    base = [base componentsSeparatedByString:@"#"].firstObject;
    return base;
}

static void (^MPGetPreviewLoadingCompletionHandler(MPDocument *doc))()
{
    __weak MPDocument *weakObj = doc;
    return ^{
        WebView *webView = weakObj.preview;
        NSWindow *window = webView.window;
        @synchronized(window)
        {
            if (window.isFlushWindowDisabled)
                [window enableFlushWindow];
        }
        [weakObj scaleWebview];
        if (weakObj.preferences.editorSyncScrolling)
        {
            [weakObj.scrollSyncController updateHeaderLocations];
            [weakObj.scrollSyncController syncScrollers];
        }
        else
        {
            NSClipView *contentView = webView.enclosingScrollView.contentView;
            NSRect bounds = contentView.bounds;
            bounds.origin.y = weakObj.lastPreviewScrollTop;
            contentView.bounds = bounds;
        }
    };
}

#define OPEN_FAIL_ALERT_INFORMATIVE NSLocalizedString( \
@"Please check the path of your link is correct. Turn on \
“Automatically create link targets” If you want MacDown to \
create nonexistent link targets for you.", \
@"preview navigation error information")

#define AUTO_CREATE_FAIL_ALERT_INFORMATIVE NSLocalizedString( \
@"MacDown can’t create a file for the clicked link because \
the current file is not saved anywhere yet. Save the \
current file somewhere to enable this feature.", \
@"preview navigation error information")

#pragma mark - WebFrameLoadDelegate

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
    NSWindow *window = sender.window;
    @synchronized(window)
    {
        if (!window.isFlushWindowDisabled)
            [window disableFlushWindow];
    }

    // If MathJax is off, the on-completion callback will be invoked directly
    // when loading is done (in -webView:didFinishLoadForFrame:).
    if (self.preferences.htmlMathJax)
    {
        MPMathJaxListener *listener = [[MPMathJaxListener alloc] init];
        [listener addCallback:MPGetPreviewLoadingCompletionHandler(self)
                       forKey:@"End"];
        [sender.windowScriptObject setValue:listener forKey:@"MathJaxListener"];
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [self handlePreviewLoadDidComplete];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    [self handlePreviewLoadDidComplete];
}

- (void)handlePreviewLoadDidComplete
{
    // If MathJax is on, the on-completion callback will be invoked by the
    // JavaScript handler injected in -webView:didCommitLoadForFrame:.
    if (!self.preferences.htmlMathJax)
    {
        id callback = MPGetPreviewLoadingCompletionHandler(self);
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        [queue addOperationWithBlock:callback];
    }

    self.isPreviewReady = YES;

    if (self.preferences.editorShowWordCount)
        [self updateWordCount];

    self.alreadyRenderingInWeb = NO;

    if (self.renderToWebPending)
        [self.renderer render];

    self.renderToWebPending = NO;
}

#pragma mark - Preview utilities

- (void)updateWordCount
{
    DOMNodeTextCount count = self.preview.mainFrame.DOMDocument.textCount;

    self.totalWords = count.words;
    self.totalCharacters = count.characters;
    self.totalCharactersNoSpaces = count.characterWithoutSpaces;

    if (self.isPreviewReady)
        self.wordCountWidget.enabled = YES;
}

- (void)scaleWebview
{
    if (!self.preferences.previewZoomRelativeToBaseFontSize)
        return;

    CGFloat fontSize = self.preferences.editorBaseFontSize;
    if (fontSize <= 0.0)
        return;

    static const CGFloat defaultSize = 14.0;
    CGFloat scale = fontSize / defaultSize;

    // Warning: this is private webkit API and NOT App Store-safe!
    MPSetLegacyWebViewPageScaleMultiplier(self.preview, scale);
}

#pragma mark - WebPolicyDelegate

- (void)webView:(WebView *)webView
                decidePolicyForNavigationAction:(NSDictionary *)information
        request:(NSURLRequest *)request frame:(WebFrame *)frame
                decisionListener:(id<WebPolicyDecisionListener>)listener
{
    switch ([information[WebActionNavigationTypeKey] integerValue])
    {
        case WebNavigationTypeLinkClicked:
            // If the target is exactly as the current one, ignore.
            if ([self.currentBaseUrl isEqual:request.URL])
            {
                [listener ignore];
                return;
            }
            // If this is a different page, intercept and handle ourselves.
            else if (![self isCurrentBaseUrl:request.URL])
            {
                [listener ignore];
                [self openOrCreateFileForUrl:request.URL];
                return;
            }
            // Otherwise this is somewhere else on the same page. Jump there.
            break;
        default:
            break;
    }
    [listener use];
}

#pragma mark - WebEditingDelegate

- (BOOL)webView:(WebView *)webView doCommandBySelector:(SEL)selector
{
    if (selector == @selector(copy:))
    {
        NSString *html = webView.selectedDOMRange.markupString;

        // Inject the HTML content later so that it doesn't get cleared during
        // the native copy operation.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSPasteboard *pb = [NSPasteboard generalPasteboard];
            if (![pb stringForType:@"public.html"])
                [pb setString:html forType:@"public.html"];
        }];
    }
    return NO;
}

#pragma mark - WebUIDelegate

- (NSUInteger)webView:(WebView *)webView
        dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)info
{
    return WebDragDestinationActionNone;
}

#pragma mark - MPRendererDataSource

- (BOOL)rendererLoading
{
    return self.preview.loading;
}

- (NSString *)rendererMarkdown:(MPRenderer *)renderer
{
    return self.editor.string;
}

- (NSString *)rendererHTMLTitle:(MPRenderer *)renderer
{
    NSString *n = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
    return n ? n : @"";
}

#pragma mark - MPRendererDelegate

- (int)rendererExtensions:(MPRenderer *)renderer
{
    return self.preferences.extensionFlags;
}

- (int)rendererHTMLFlags:(MPRenderer *)renderer
{
    return self.preferences.rendererFlags;
}

- (BOOL)rendererHasSmartyPants:(MPRenderer *)renderer
{
    return self.preferences.extensionSmartyPants;
}

- (BOOL)rendererRendersTOC:(MPRenderer *)renderer
{
    return self.preferences.htmlRendersTOC;
}

- (NSString *)rendererTemplateName:(MPRenderer *)renderer
{
    NSString *name = self.preferences.htmlTemplateName;
    return name.length ? name : @"Default";
}

- (NSString *)rendererStyleName:(MPRenderer *)renderer
{
    return self.preferences.htmlStyleName;
}

- (BOOL)rendererDetectsFrontMatter:(MPRenderer *)renderer
{
    return self.preferences.htmlDetectFrontMatter;
}

- (BOOL)rendererHasSyntaxHighlighting:(MPRenderer *)renderer
{
    return self.preferences.htmlSyntaxHighlighting;
}

- (BOOL)rendererHasMermaid:(MPRenderer *)renderer
{
    return self.preferences.htmlMermaid;
}

- (BOOL)rendererHasGraphviz:(MPRenderer *)renderer
{
    return self.preferences.htmlGraphviz;
}

- (MPCodeBlockAccessoryType)rendererCodeBlockAccessory:(MPRenderer *)renderer
{
    return self.preferences.htmlCodeBlockAccessory;
}

- (BOOL)rendererHasMathJax:(MPRenderer *)renderer
{
    return self.preferences.htmlMathJax;
}

- (NSString *)rendererHighlightingThemeName:(MPRenderer *)renderer
{
    return self.preferences.htmlHighlightingThemeName;
}

- (void)renderer:(MPRenderer *)renderer didProduceHTMLOutput:(NSString *)html
{
    if (self.alreadyRenderingInWeb)
    {
        self.renderToWebPending = YES;
        return;
    }

    if (self.printing)
        return;

    self.alreadyRenderingInWeb = YES;

    // Delayed copying for -copyHtml.
    if (self.copying)
    {
        self.copying = NO;
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[self.renderer.currentHtml]];
    }

    NSURL *baseUrl = self.fileURL;
    if (!baseUrl)   // Unsaved document; just use the default URL.
        baseUrl = self.preferences.htmlDefaultDirectoryUrl;

    self.manualRender = self.preferences.markdownManualRender;

    // Reload the page if there's not valid tree to work with.
    [self.preview.mainFrame loadHTMLString:html baseURL:baseUrl];
    self.currentBaseUrl = baseUrl;
}

- (BOOL)isCurrentBaseUrl:(NSURL *)another
{
    NSString *mine = MPAbsoluteBaseURLString(self.currentBaseUrl);
    NSString *theirs = MPAbsoluteBaseURLString(another);
    return mine == theirs || [mine isEqualToString:theirs];
}

- (void)openOrCreateFileForUrl:(NSURL *)url
{
    // Simply open the file if it is not local, or exists already.
    BOOL file = url.isFileURL;
    BOOL reachable = !file || [url checkResourceIsReachableAndReturnError:NULL];

    // If the file is local but doesn't exist, check if a file with
    // the .md extension exists.
    if (file && !reachable && [url.pathExtension isEqualToString:@""])
    {
        NSURL *markdownURL = [url URLByAppendingPathExtension:@"md"];
        if ([markdownURL checkResourceIsReachableAndReturnError:NULL])
        {
            reachable = YES;
            url = markdownURL;
        }
    }

    if (reachable)
    {
        [[NSWorkspace sharedWorkspace] openURL:url];
        return;
    }

    // Show an error if the user doesn't want us to create it automatically.
    if (!self.preferences.createFileForLinkTarget)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        NSString *template = NSLocalizedString(
            @"File not found at path:\n%@",
            @"preview navigation error message");
        alert.messageText = [NSString stringWithFormat:template, url.path];
        alert.informativeText = OPEN_FAIL_ALERT_INFORMATIVE;
        [alert runModal];
        return;
    }

    // We can only create a file if the current file is saved. (Why?)
    if (!self.fileURL)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        NSString *template = NSLocalizedString(
            @"Can’t create file:\n%@", @"preview navigation error message");
        alert.messageText = [NSString stringWithFormat:template,
                             url.lastPathComponent];
        alert.informativeText = AUTO_CREATE_FAIL_ALERT_INFORMATIVE;
        [alert runModal];
    }

    // Try to created the file.
    NSDocumentController *controller =
        [NSDocumentController sharedDocumentController];

    NSError *error = nil;
    id doc = [controller createNewEmptyDocumentForURL:url
                                            display:YES error:&error];
    if (!doc)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        NSString *template = NSLocalizedString(
            @"Can’t create file:\n%@",
            @"preview navigation error message");
        alert.messageText =
            [NSString stringWithFormat:template, url.lastPathComponent];
        template = NSLocalizedString(
            @"An error occurred while creating the file:\n%@",
            @"preview navigation error information");
        alert.informativeText =
            [NSString stringWithFormat:template, error.localizedDescription];
        [alert runModal];
    }
}

@end
