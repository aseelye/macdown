//
//  MPPreferences+EditorBehavior.m
//  MacDown
//

#import "MPPreferences+EditorBehavior.h"

static NSString *MPUserDefaultsKeyForEditorBehaviorKey(NSString *key)
{
    if (!key.length)
        return nil;
    NSString *first = [[key substringToIndex:1] uppercaseString];
    NSString *rest = [key substringFromIndex:1];
    return [NSString stringWithFormat:@"editor%@%@", first, rest];
}

@implementation MPPreferences (EditorBehavior)

+ (NSDictionary<NSString *, id> *)editorBehaviorKeysAndDefaultValues
{
    static NSDictionary *keys = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        keys = @{
            @"automaticDashSubstitutionEnabled": @NO,
            @"automaticDataDetectionEnabled": @NO,
            @"automaticQuoteSubstitutionEnabled": @NO,
            @"automaticSpellingCorrectionEnabled": @NO,
            @"automaticTextReplacementEnabled": @NO,
            @"continuousSpellCheckingEnabled": @NO,
            @"enabledTextCheckingTypes": @(NSTextCheckingAllTypes),
            @"grammarCheckingEnabled": @NO
        };
    });
    return keys;
}

+ (NSString *)userDefaultsKeyForEditorBehaviorKey:(NSString *)key
{
    return MPUserDefaultsKeyForEditorBehaviorKey(key);
}

+ (void)applyEditorBehaviorDefaultsToEditor:(id)editor
                               userDefaults:(NSUserDefaults *)defaults
{
    if (!editor)
        return;

    NSDictionary *keysAndDefaults = [self editorBehaviorKeysAndDefaultValues];
    for (NSString *key in keysAndDefaults)
    {
        NSString *defaultsKey = [self userDefaultsKeyForEditorBehaviorKey:key];
        id value = [defaults objectForKey:defaultsKey];
        if (!value)
            value = keysAndDefaults[key];
        [editor setValue:value forKey:key];
    }
}

+ (void)persistEditorBehaviorValue:(id)value
                            forKey:(NSString *)key
                      userDefaults:(NSUserDefaults *)defaults
{
    NSString *defaultsKey = [self userDefaultsKeyForEditorBehaviorKey:key];
    if (!defaultsKey.length)
        return;

    if (!value || value == [NSNull null])
    {
        [defaults removeObjectForKey:defaultsKey];
        return;
    }
    [defaults setObject:value forKey:defaultsKey];
}

- (void)applyEditorBehaviorDefaultsToEditor:(id)editor
{
    NSUserDefaults *defaults = self.userDefaults;
    if (!defaults)
        defaults = [NSUserDefaults standardUserDefaults];

    [[self class] applyEditorBehaviorDefaultsToEditor:editor
                                         userDefaults:defaults];
}

- (void)persistEditorBehaviorValue:(id)value forKey:(NSString *)key
{
    NSUserDefaults *defaults = self.userDefaults;
    if (!defaults)
        defaults = [NSUserDefaults standardUserDefaults];

    [[self class] persistEditorBehaviorValue:value
                                      forKey:key
                                userDefaults:defaults];
}

@end
