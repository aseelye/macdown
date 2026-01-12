//
//  MPScrollSyncController.m
//  MacDown
//

#import "MPScrollSyncController.h"

#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

#import "MPEditorView.h"

@interface MPScrollSyncController ()
@property (weak) MPEditorView *editor;
@property (weak) WebView *preview;
@property (copy) NSArray<NSNumber *> *webViewHeaderLocations;
@property (copy) NSArray<NSNumber *> *editorHeaderLocations;
@end

@implementation MPScrollSyncController

- (instancetype)initWithEditor:(MPEditorView *)editor preview:(WebView *)preview
{
    self = [super init];
    if (!self)
        return nil;

    self.editor = editor;
    self.preview = preview;
    self.webViewHeaderLocations = @[];
    self.editorHeaderLocations = @[];
    return self;
}

- (void)updateHeaderLocations
{
    WebView *preview = self.preview;
    MPEditorView *editor = self.editor;
    if (!preview || !editor)
        return;

    CGFloat offset = NSMinY(preview.enclosingScrollView.contentView.bounds);
    NSMutableArray<NSNumber *> *locations = [NSMutableArray array];

    static NSString *script =
        @"var arr = Array.prototype.slice.call("
        @"document.querySelectorAll(\"h1, h2, h3, h4, h5, h6, img:only-child\")"
        @");"
        @"arr.map(function(n) { return n.getBoundingClientRect().top; })";
    NSArray<NSNumber *> *headerOffsets =
        [[preview.mainFrame.javaScriptContext evaluateScript:script] toArray];

    for (NSNumber *location in headerOffsets)
        [locations addObject:@([location floatValue] + offset)];

    self.webViewHeaderLocations = [locations copy];

    NSInteger characterCount = 0;
    NSLayoutManager *layoutManager = editor.layoutManager;
    NSArray<NSString *> *documentLines =
        [editor.string componentsSeparatedByString:@"\n"];
    [locations removeAllObjects];

    static NSRegularExpression *dashRegex = nil;
    static NSRegularExpression *headerRegex = nil;
    static NSRegularExpression *imgRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dashRegex =
            [NSRegularExpression regularExpressionWithPattern:@"^([-]+)$"
                                                     options:0 error:NULL];
        headerRegex =
            [NSRegularExpression regularExpressionWithPattern:@"^(#+)\\s"
                                                     options:0 error:NULL];
        imgRegex =
            [NSRegularExpression regularExpressionWithPattern:
                @"^!\\[[^\\]]*\\]\\([^)]*\\)$"
                                                   options:0 error:NULL];
    });
    BOOL previousLineHadContent = NO;

    CGFloat editorContentHeight =
        ceilf(NSHeight(editor.enclosingScrollView.documentView.bounds));
    CGFloat editorVisibleHeight =
        ceilf(NSHeight(editor.enclosingScrollView.contentView.bounds));

    for (NSInteger lineNumber = 0; lineNumber < documentLines.count; lineNumber++)
    {
        NSString *line = documentLines[lineNumber];
        NSRange lineRange = NSMakeRange(0, line.length);

        BOOL isSetextUnderline =
            [dashRegex numberOfMatchesInString:line options:0 range:lineRange];
        BOOL isSetextHeader =
            previousLineHadContent
            && isSetextUnderline;
        BOOL isImageOnly =
            [imgRegex numberOfMatchesInString:line options:0 range:lineRange];
        BOOL isAtxHeader =
            [headerRegex numberOfMatchesInString:line options:0 range:lineRange];

        if (isSetextHeader || isImageOnly || isAtxHeader)
        {
            NSRange glyphRange =
                [layoutManager glyphRangeForCharacterRange:NSMakeRange(characterCount, line.length)
                                      actualCharacterRange:nil];
            NSRect topRect =
                [layoutManager boundingRectForGlyphRange:glyphRange
                                         inTextContainer:editor.textContainer];
            CGFloat headerY = NSMidY(topRect);

            if (headerY <= editorContentHeight - editorVisibleHeight)
                [locations addObject:@(headerY)];
        }

        previousLineHadContent =
            line.length && !isSetextUnderline;
        characterCount += line.length + 1;
    }

    self.editorHeaderLocations = [locations copy];
}

- (void)syncScrollers
{
    WebView *preview = self.preview;
    MPEditorView *editor = self.editor;
    if (!preview || !editor)
        return;

    CGFloat editorContentHeight =
        ceilf(NSHeight(editor.enclosingScrollView.documentView.bounds));
    CGFloat editorVisibleHeight =
        ceilf(NSHeight(editor.enclosingScrollView.contentView.bounds));
    CGFloat previewContentHeight =
        ceilf(NSHeight(preview.enclosingScrollView.documentView.bounds));
    CGFloat previewVisibleHeight =
        ceilf(NSHeight(preview.enclosingScrollView.contentView.bounds));

    NSInteger relativeHeaderIndex = -1;
    CGFloat currY = NSMinY(editor.enclosingScrollView.contentView.bounds);
    CGFloat minY = 0;
    CGFloat maxY = 0;

    CGFloat topTaper = MAX(0, MIN(1.0, currY / editorVisibleHeight));
    CGFloat bottomTaper =
        1.0 - MAX(0, MIN(1.0,
            (currY - editorContentHeight + 2 * editorVisibleHeight)
            / editorVisibleHeight));
    CGFloat adjustmentForScroll =
        topTaper * bottomTaper * editorVisibleHeight / 2;

    for (NSNumber *headerYNum in self.editorHeaderLocations)
    {
        CGFloat headerY = headerYNum.floatValue;
        headerY -= adjustmentForScroll;

        if (headerY < currY)
        {
            relativeHeaderIndex += 1;
            minY = headerY;
        }
        else if (maxY == 0 && headerY < editorContentHeight - editorVisibleHeight)
        {
            maxY = headerY;
        }
    }

    BOOL interpolateToEndOfDocument = NO;
    if (maxY == 0)
    {
        maxY = editorContentHeight - editorVisibleHeight + adjustmentForScroll;
        interpolateToEndOfDocument = YES;
    }

    currY = MAX(0, currY - minY);
    maxY -= minY;
    minY = 0;
    CGFloat percentScrolledBetweenHeaders = MAX(0, MIN(1.0, currY / maxY));

    CGFloat topHeaderY = 0;
    CGFloat bottomHeaderY = previewContentHeight - previewVisibleHeight;

    NSInteger topIndex = relativeHeaderIndex;
    NSInteger bottomIndex = relativeHeaderIndex + 1;

    if (topIndex >= 0
        && (NSUInteger)topIndex < self.webViewHeaderLocations.count)
    {
        topHeaderY =
            floorf(self.webViewHeaderLocations[topIndex].doubleValue)
            - adjustmentForScroll;
    }
    if (!interpolateToEndOfDocument
        && bottomIndex >= 0
        && (NSUInteger)bottomIndex < self.webViewHeaderLocations.count)
    {
        bottomHeaderY =
            ceilf(self.webViewHeaderLocations[bottomIndex].doubleValue)
            - adjustmentForScroll;
    }

    CGFloat previewY =
        topHeaderY + (bottomHeaderY - topHeaderY) * percentScrolledBetweenHeaders;
    NSRect contentBounds = preview.enclosingScrollView.contentView.bounds;
    contentBounds.origin.y = previewY;
    preview.enclosingScrollView.contentView.bounds = contentBounds;
}

@end
