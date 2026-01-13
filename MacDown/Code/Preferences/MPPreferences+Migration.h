//
//  MPPreferences+Migration.h
//  MacDown
//

#import "MPPreferences.h"

@interface MPPreferences (Migration)

+ (void)migrateLegacyKeysIfNeededInUserDefaults:(NSUserDefaults *)defaults;
- (void)migrateLegacyKeysIfNeeded;

@end

