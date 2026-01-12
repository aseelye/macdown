//
//  MPUserDefaultsSuiteTests.m
//  MacDown
//

#import <XCTest/XCTest.h>
#import "NSUserDefaults+Suite.h"

@interface MPUserDefaultsSuiteTests : XCTestCase
@end

@implementation MPUserDefaultsSuiteTests

- (NSString *)uniqueSuiteName
{
    return [NSString stringWithFormat:@"com.uranusjr.macdown.tests.suite.%@",
                                      [NSProcessInfo processInfo].globallyUniqueString];
}

- (void)testSuiteReadWriteRoundTrip
{
    NSString *suiteName = [self uniqueSuiteName];
    NSString *key = @"testKey";
    NSString *value = @"testValue";

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteNamed:suiteName];
    [defaults setObject:value forKey:key inSuiteNamed:suiteName];

    id read = [defaults objectForKey:key inSuiteNamed:suiteName];
    XCTAssertEqualObjects(read, value);
}

- (void)testSuiteReadMissingIsNil
{
    NSString *suiteName = [self uniqueSuiteName];
    NSString *missingKey = @"missingKey";

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteNamed:suiteName];
    id read = [defaults objectForKey:missingKey inSuiteNamed:suiteName];
    XCTAssertNil(read);
}

@end
