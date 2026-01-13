//
//  MPRendererHTMLFlagsTests.m
//  MacDownTests
//

#import <XCTest/XCTest.h>

#import <hoedown/html.h>

#import "MPRenderer.h"

@interface MPRendererHTMLFlagsTestDriver : NSObject <MPRendererDataSource, MPRendererDelegate>
@property (copy) NSString *markdown;
@property int htmlFlags;
@property (strong) XCTestExpectation *expectation;
@end

@implementation MPRendererHTMLFlagsTestDriver

- (BOOL)rendererLoading
{
    return NO;
}

- (NSString *)rendererMarkdown:(MPRenderer *)renderer
{
    return self.markdown;
}

- (NSString *)rendererHTMLTitle:(MPRenderer *)renderer
{
    return @"";
}

- (int)rendererExtensions:(MPRenderer *)renderer
{
    return 0;
}

- (int)rendererHTMLFlags:(MPRenderer *)renderer
{
    return self.htmlFlags;
}

- (BOOL)rendererHasSmartyPants:(MPRenderer *)renderer
{
    return NO;
}

- (BOOL)rendererRendersTOC:(MPRenderer *)renderer
{
    return NO;
}

- (NSString *)rendererTemplateName:(MPRenderer *)renderer
{
    return @"Default";
}

- (NSString *)rendererStyleName:(MPRenderer *)renderer
{
    return nil;
}

- (BOOL)rendererDetectsFrontMatter:(MPRenderer *)renderer
{
    return NO;
}

- (BOOL)rendererHasSyntaxHighlighting:(MPRenderer *)renderer
{
    return NO;
}

- (BOOL)rendererHasMermaid:(MPRenderer *)renderer
{
    return NO;
}

- (BOOL)rendererHasGraphviz:(MPRenderer *)renderer
{
    return NO;
}

- (MPCodeBlockAccessoryType)rendererCodeBlockAccessory:(MPRenderer *)renderer
{
    return MPCodeBlockAccessoryNone;
}

- (BOOL)rendererHasMathJax:(MPRenderer *)renderer
{
    return NO;
}

- (NSString *)rendererHighlightingThemeName:(MPRenderer *)renderer
{
    return @"";
}

- (void)renderer:(MPRenderer *)renderer didProduceHTMLOutput:(NSString *)html
{
    [self.expectation fulfill];
}

@end

@interface MPRendererHTMLFlagsTests : XCTestCase
@end

@implementation MPRendererHTMLFlagsTests

- (void)testHardWrapFlagChangesRenderedMarkdownHTML
{
    MPRendererHTMLFlagsTestDriver *driver =
        [[MPRendererHTMLFlagsTestDriver alloc] init];
    driver.markdown = @"a\nb";

    MPRenderer *renderer = [[MPRenderer alloc] init];
    renderer.dataSource = driver;
    renderer.delegate = driver;

    driver.htmlFlags = 0;
    driver.expectation = [self expectationWithDescription:@"initial render"];
    [renderer parseAndRenderNow];
    [self waitForExpectations:@[driver.expectation] timeout:2.0];

    NSString *withoutHardWrap = renderer.currentHtml;
    XCTAssertNotNil(withoutHardWrap);
    XCTAssertFalse([withoutHardWrap containsString:@"<br"]);

    driver.htmlFlags = HOEDOWN_HTML_HARD_WRAP;
    driver.expectation = [self expectationWithDescription:@"hard wrap render"];
    [renderer parseAndRenderIfNeeded];
    [self waitForExpectations:@[driver.expectation] timeout:2.0];

    NSString *withHardWrap = renderer.currentHtml;
    XCTAssertNotNil(withHardWrap);
    XCTAssertTrue([withHardWrap containsString:@"<br"]);
    XCTAssertNotEqualObjects(withHardWrap, withoutHardWrap);
}

@end
