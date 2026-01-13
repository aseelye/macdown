//
//  MPPreferences+Migration.m
//  MacDown
//

#import "MPPreferences+Migration.h"

static NSString * const kMPLegacySuppressesUntitledDocumentOnLaunchKey =
    @"supressesUntitledDocumentOnLaunch";
static NSString * const kMPCanonicalSuppressesUntitledDocumentOnLaunchKey =
    @"suppressesUntitledDocumentOnLaunch";

static NSString * const kMPLegacyExtensionStrikethroughKey =
    @"extensionStrikethough";
static NSString * const kMPCanonicalExtensionStrikethroughKey =
    @"extensionStrikethrough";

NS_INLINE void MPPreferencesMigrateValueToCanonicalKey(
    NSUserDefaults *defaults, NSString *legacyKey, NSString *canonicalKey)
{
    id legacyValue = [defaults objectForKey:legacyKey];
    if (!legacyValue)
        return;

    id canonicalValue = [defaults objectForKey:canonicalKey];
    NSDictionary *registrationDomain =
        [defaults volatileDomainForName:NSRegistrationDomain];
    id registeredCanonicalValue = registrationDomain[canonicalKey];
    BOOL shouldPreserveCanonicalValue = NO;
    if (canonicalValue)
    {
        if (!registeredCanonicalValue)
        {
            shouldPreserveCanonicalValue = YES;
        }
        else if (![canonicalValue isEqual:registeredCanonicalValue])
        {
            shouldPreserveCanonicalValue = YES;
        }
    }

    if (!shouldPreserveCanonicalValue)
        [defaults setObject:legacyValue forKey:canonicalKey];

    [defaults removeObjectForKey:legacyKey];
}

@implementation MPPreferences (Migration)

+ (void)migrateLegacyKeysIfNeededInUserDefaults:(NSUserDefaults *)defaults
{
    MPPreferencesMigrateValueToCanonicalKey(
        defaults,
        kMPLegacySuppressesUntitledDocumentOnLaunchKey,
        kMPCanonicalSuppressesUntitledDocumentOnLaunchKey);
    MPPreferencesMigrateValueToCanonicalKey(
        defaults,
        kMPLegacyExtensionStrikethroughKey,
        kMPCanonicalExtensionStrikethroughKey);
}

- (BOOL)supressesUntitledDocumentOnLaunch
{
    return self.suppressesUntitledDocumentOnLaunch;
}

- (void)setSupressesUntitledDocumentOnLaunch:(BOOL)value
{
    self.suppressesUntitledDocumentOnLaunch = value;
}

- (BOOL)extensionStrikethough
{
    return self.extensionStrikethrough;
}

- (void)setExtensionStrikethough:(BOOL)value
{
    self.extensionStrikethrough = value;
}

- (void)migrateLegacyKeysIfNeeded
{
    [[self class] migrateLegacyKeysIfNeededInUserDefaults:self.userDefaults];
}

@end
