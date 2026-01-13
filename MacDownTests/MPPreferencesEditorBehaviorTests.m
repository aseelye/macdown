//
//  MPPreferencesEditorBehaviorTests.m
//  MacDownTests
//

#import <XCTest/XCTest.h>

#import "MPPreferences+EditorBehavior.h"

@interface MPDummyEditorBehaviorObject : NSObject
@property (nonatomic) BOOL automaticDashSubstitutionEnabled;
@property (nonatomic) BOOL automaticDataDetectionEnabled;
@property (nonatomic) BOOL automaticQuoteSubstitutionEnabled;
@property (nonatomic) BOOL automaticSpellingCorrectionEnabled;
@property (nonatomic) BOOL automaticTextReplacementEnabled;
@property (nonatomic) BOOL continuousSpellCheckingEnabled;
@property (nonatomic) NSUInteger enabledTextCheckingTypes;
@property (nonatomic) BOOL grammarCheckingEnabled;
@end

@implementation MPDummyEditorBehaviorObject
@end

@interface MPPreferencesEditorBehaviorTests : XCTestCase
@property (copy) NSString *suiteName;
@property (strong) NSUserDefaults *defaults;
@end

@implementation MPPreferencesEditorBehaviorTests

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

- (void)testAppliesDefaultValuesWhenNoPersistedValuesExist
{
    MPDummyEditorBehaviorObject *editor =
        [[MPDummyEditorBehaviorObject alloc] init];
    [MPPreferences applyEditorBehaviorDefaultsToEditor:editor
                                         userDefaults:self.defaults];

    XCTAssertEqual(editor.automaticDashSubstitutionEnabled, NO);
    XCTAssertEqual(editor.automaticDataDetectionEnabled, NO);
    XCTAssertEqual(editor.automaticQuoteSubstitutionEnabled, NO);
    XCTAssertEqual(editor.automaticSpellingCorrectionEnabled, NO);
    XCTAssertEqual(editor.automaticTextReplacementEnabled, NO);
    XCTAssertEqual(editor.continuousSpellCheckingEnabled, NO);
    XCTAssertEqual(editor.enabledTextCheckingTypes,
                   (NSUInteger)NSTextCheckingAllTypes);
    XCTAssertEqual(editor.grammarCheckingEnabled, NO);
}

- (void)testPersistsAndAppliesValueRoundTrip
{
    [MPPreferences persistEditorBehaviorValue:@YES
                                       forKey:@"automaticDashSubstitutionEnabled"
                                 userDefaults:self.defaults];

    XCTAssertEqualObjects(
        [self.defaults objectForKey:@"editorAutomaticDashSubstitutionEnabled"],
        @YES);

    MPDummyEditorBehaviorObject *editor =
        [[MPDummyEditorBehaviorObject alloc] init];
    [MPPreferences applyEditorBehaviorDefaultsToEditor:editor
                                         userDefaults:self.defaults];

    XCTAssertEqual(editor.automaticDashSubstitutionEnabled, YES);
    XCTAssertEqual(editor.automaticQuoteSubstitutionEnabled, NO);
}

@end
