//
//  MPDocument_Private.h
//  MacDown
//
//  Private implementation details shared across MPDocument categories.
//

#import "MPDocument.h"

@class HGMarkdownHighlighter;
@class MPRenderer;
@class MPDocumentSplitView;
@class MPEditorView;
@class MPScrollSyncController;
@class MPToolbarController;
@class WebView;

typedef NS_ENUM(NSUInteger, MPWordCountType)
{
    MPWordCountTypeWord,
    MPWordCountTypeCharacter,
    MPWordCountTypeCharacterNoSpaces,
};

@interface MPDocument ()

@property (weak) IBOutlet NSToolbar *toolbar;
@property (weak) IBOutlet MPDocumentSplitView *splitView;
@property (weak) IBOutlet NSView *editorContainer;
@property (unsafe_unretained) IBOutlet MPEditorView *editor;
@property (weak) IBOutlet NSLayoutConstraint *editorPaddingBottom;
@property (weak) IBOutlet WebView *preview;
@property (weak) IBOutlet NSPopUpButton *wordCountWidget;
@property (strong) IBOutlet MPToolbarController *toolbarController;
@property (strong) HGMarkdownHighlighter *highlighter;
@property (strong) MPRenderer *renderer;
@property CGFloat previousSplitRatio;
@property BOOL manualRender;
@property BOOL copying;
@property BOOL printing;
@property BOOL shouldHandleBoundsChange;
@property BOOL isPreviewReady;
@property (strong) NSURL *currentBaseUrl;
@property CGFloat lastPreviewScrollTop;
@property (nonatomic, readonly) BOOL needsHtml;
@property (nonatomic) NSUInteger totalWords;
@property (nonatomic) NSUInteger totalCharacters;
@property (nonatomic) NSUInteger totalCharactersNoSpaces;
@property (strong) NSMenuItem *wordsMenuItem;
@property (strong) NSMenuItem *charMenuItem;
@property (strong) NSMenuItem *charNoSpacesMenuItem;
@property (nonatomic) BOOL needsToUnregister;
@property (nonatomic) BOOL alreadyRenderingInWeb;
@property (nonatomic) BOOL renderToWebPending;
@property (strong) MPScrollSyncController *scrollSyncController;
@property (nonatomic) BOOL inLiveScroll;

// Store file content in initializer until nib is loaded.
@property (copy) NSString *loadedString;

- (void)setupEditor:(NSString *)changedKey;
- (NSString *)presumedFileName;
- (void)scaleWebview;
- (void)updateWordCount;

@end
