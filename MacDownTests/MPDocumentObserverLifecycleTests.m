//
//  MPDocumentObserverLifecycleTests.m
//  MacDownTests
//

#import <XCTest/XCTest.h>

#import "HGMarkdownHighlighter.h"
#import "MPDocument_Private.h"
#import "MPPreferences.h"
#import "MPEditorView.h"

@interface MPDocumentObserverLifecycleTestDocument : MPDocument
@property (strong) NSScrollView *editorScrollView;
@end

@implementation MPDocumentObserverLifecycleTestDocument
@end

@interface MPDocumentObserverLifecycleTests : XCTestCase
@end

@implementation MPDocumentObserverLifecycleTests

- (MPDocument *)makeDocumentWithEditorAndActiveHighlighter
{
    MPDocumentObserverLifecycleTestDocument *document =
        [[MPDocumentObserverLifecycleTestDocument alloc] init];

    NSRect frame = NSMakeRect(0.0, 0.0, 400.0, 400.0);
    MPEditorView *editor = [[MPEditorView alloc] initWithFrame:frame];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    scrollView.documentView = editor;
    document.editorScrollView = scrollView;

    document.editor = editor;

    HGMarkdownHighlighter *highlighter =
        [[HGMarkdownHighlighter alloc] initWithTextView:editor waitInterval:0.0];
    [highlighter activate];
    document.highlighter = highlighter;

    return document;
}

- (void)testRegisterObserversIsIdempotent
{
    MPDocument *document = [self makeDocumentWithEditorAndActiveHighlighter];

    XCTAssertNoThrow([document registerObservers]);
    XCTAssertNoThrow([document registerObservers]);

    XCTAssertNoThrow([document unregisterObservers]);
}

- (void)testUnregisterObserversIsIdempotent
{
    MPDocument *document = [self makeDocumentWithEditorAndActiveHighlighter];

    XCTAssertNoThrow([document registerObservers]);
    XCTAssertNoThrow([document unregisterObservers]);
    XCTAssertNoThrow([document unregisterObservers]);
}

- (void)testPreferenceToggleDoesNotThrowWhileObserversRegistered
{
    MPDocument *document = [self makeDocumentWithEditorAndActiveHighlighter];
    MPPreferences *preferences = document.preferences;

    CGFloat oldInset = preferences.editorHorizontalInset;

    XCTAssertNoThrow([document registerObservers]);
    @try
    {
        preferences.editorHorizontalInset = oldInset + 1.0;
        preferences.editorHorizontalInset = oldInset;
    }
    @finally
    {
        [preferences synchronize];
        [document unregisterObservers];
    }
}

@end
