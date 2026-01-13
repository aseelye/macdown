//
//  MPPreferences+EditorBehavior.h
//  MacDown
//

#import "MPPreferences.h"

@interface MPPreferences (EditorBehavior)

+ (NSDictionary<NSString *, id> *)editorBehaviorKeysAndDefaultValues;
+ (NSString *)userDefaultsKeyForEditorBehaviorKey:(NSString *)key;

+ (void)applyEditorBehaviorDefaultsToEditor:(id)editor
                               userDefaults:(NSUserDefaults *)defaults;
+ (void)persistEditorBehaviorValue:(id)value
                            forKey:(NSString *)key
                      userDefaults:(NSUserDefaults *)defaults;

- (void)applyEditorBehaviorDefaultsToEditor:(id)editor;
- (void)persistEditorBehaviorValue:(id)value forKey:(NSString *)key;

@end
