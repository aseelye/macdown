//
//  MPPreferencesTests.m
//  MPPreferencesTests
//
//  Created by Tzu-ping Chung  on 6/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPPreferences.h"

static void * const MPPreferencesKVOContext = (void *)&MPPreferencesKVOContext;

@interface MPPreferencesTests : XCTestCase
@property MPPreferences *preferences;
@property NSDictionary *oldFontInfo;
@property XCTestExpectation *kvoExpectation;
@end


@implementation MPPreferencesTests

- (void)setUp
{
    [super setUp];
    self.preferences = [MPPreferences sharedInstance];
    self.oldFontInfo = [self.preferences.editorBaseFontInfo copy];

}

- (void)tearDown
{
    self.preferences.editorBaseFontInfo = self.oldFontInfo;
    [self.preferences synchronize];
    [super tearDown];
}

- (void)testFont
{
    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    self.preferences.editorBaseFont = font;

    XCTAssertTrue([self.preferences synchronize],
                  @"Failed to synchronize user defaults.");

    NSFont *result = [self.preferences.editorBaseFont copy];
    XCTAssertEqualObjects(font, result,
                          @"Preferences not preserving font info correctly.");
}

- (void)testKVOFiresForDynamicPreferences
{
    MPPreferences *preferences = self.preferences;
    CGFloat oldInset = preferences.editorHorizontalInset;

    XCTestExpectation *expectation =
        [self expectationWithDescription:@"KVO should fire for dynamic properties"];
    self.kvoExpectation = expectation;

    [preferences addObserver:self forKeyPath:@"editorHorizontalInset"
                     options:NSKeyValueObservingOptionNew
                     context:MPPreferencesKVOContext];

    @try
    {
        preferences.editorHorizontalInset = oldInset + 1.0;
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
    }
    @finally
    {
        [preferences removeObserver:self forKeyPath:@"editorHorizontalInset"
                            context:MPPreferencesKVOContext];
        preferences.editorHorizontalInset = oldInset;
        [preferences synchronize];
        self.kvoExpectation = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == MPPreferencesKVOContext)
    {
        XCTAssertEqualObjects(keyPath, @"editorHorizontalInset");
        XCTAssertEqual(object, self.preferences);
        XCTAssertNotNil(self.kvoExpectation);
        [self.kvoExpectation fulfill];
        self.kvoExpectation = nil;
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
}

@end
