//
//  MPMarkdownPreprocessorTests.m
//  MacDownTests
//
//  Created by OpenAI on 2026/01/12.
//

#import <XCTest/XCTest.h>
#import "MPMarkdownPreprocessor.h"

@interface MPMarkdownPreprocessorTests : XCTestCase
@end

@implementation MPMarkdownPreprocessorTests

- (void)testDoesNotDuplicateExistingBlankLine
{
    NSString *markdown = @"# Heading\n\n- item\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        markdown);
}

- (void)testInsertsBlankLineBetweenAtxHeadingAndList
{
    NSString *markdown = @"# Heading\n- item\n";
    NSString *expected = @"# Heading\n\n- item\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        expected);
}

- (void)testInsertsBlankLineBetweenSetextHeadingAndList
{
    NSString *markdown = @"Heading\n-----\n- item\n";
    NSString *expected = @"Heading\n-----\n\n- item\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        expected);
}

- (void)testInsertsBlankLineBetweenHeadingAndOrderedList
{
    NSString *markdown = @"# Heading\n1. item\n";
    NSString *expected = @"# Heading\n\n1. item\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        expected);
}

- (void)testDoesNotInsertInsideFencedCodeBlock
{
    NSString *markdown = @"```\n# Heading\n- item\n```\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        markdown);
}

- (void)testDoesNotInsertBetweenListItems
{
    NSString *markdown = @"- item\n- next\n";
    XCTAssertEqualObjects(
        [MPMarkdownPreprocessor markdownForRenderingFromMarkdown:markdown],
        markdown);
}

@end
