//
//  MPPreferencesMigrationTests.m
//  MacDownTests
//

#import <XCTest/XCTest.h>

#import "MPPreferences+Migration.h"

@interface MPPreferencesMigrationTests : XCTestCase
@property (copy) NSString *suiteName;
@property (strong) NSUserDefaults *defaults;
@end

@implementation MPPreferencesMigrationTests

- (void)setUp
{
    [super setUp];

    NSString *uuidString = [NSUUID UUID].UUIDString;
    self.suiteName = [NSString stringWithFormat:@"MacDownTests.%@", uuidString];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.defaults removePersistentDomainForName:self.suiteName];
}

- (void)tearDown
{
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.defaults = nil;
    self.suiteName = nil;

    [super tearDown];
}

- (void)testMigratesSuppressesUntitledDocumentOnLaunchKey
{
    [self.defaults setObject:@YES forKey:@"supressesUntitledDocumentOnLaunch"];
    [self.defaults removeObjectForKey:@"suppressesUntitledDocumentOnLaunch"];

    [MPPreferences migrateLegacyKeysIfNeededInUserDefaults:self.defaults];

    XCTAssertEqualObjects(
        [self.defaults objectForKey:@"suppressesUntitledDocumentOnLaunch"],
        @YES);
    XCTAssertNil(
        [self.defaults objectForKey:@"supressesUntitledDocumentOnLaunch"]);
}

- (void)testCanonicalSuppressesUntitledDocumentOnLaunchWinsWhenBothPresent
{
    [self.defaults setObject:@NO forKey:@"supressesUntitledDocumentOnLaunch"];
    [self.defaults setObject:@YES forKey:@"suppressesUntitledDocumentOnLaunch"];

    [MPPreferences migrateLegacyKeysIfNeededInUserDefaults:self.defaults];

    XCTAssertEqualObjects(
        [self.defaults objectForKey:@"suppressesUntitledDocumentOnLaunch"],
        @YES);
    XCTAssertNil(
        [self.defaults objectForKey:@"supressesUntitledDocumentOnLaunch"]);
}

- (void)testMigratesExtensionStrikethroughKey
{
    [self.defaults setObject:@YES forKey:@"extensionStrikethough"];
    [self.defaults removeObjectForKey:@"extensionStrikethrough"];

    [MPPreferences migrateLegacyKeysIfNeededInUserDefaults:self.defaults];

    XCTAssertEqualObjects(
        [self.defaults objectForKey:@"extensionStrikethrough"],
        @YES);
    XCTAssertNil([self.defaults objectForKey:@"extensionStrikethough"]);
}

- (void)testCanonicalExtensionStrikethroughWinsWhenBothPresent
{
    [self.defaults setObject:@NO forKey:@"extensionStrikethough"];
    [self.defaults setObject:@YES forKey:@"extensionStrikethrough"];

    [MPPreferences migrateLegacyKeysIfNeededInUserDefaults:self.defaults];

    XCTAssertEqualObjects(
        [self.defaults objectForKey:@"extensionStrikethrough"],
        @YES);
    XCTAssertNil([self.defaults objectForKey:@"extensionStrikethough"]);
}

@end
