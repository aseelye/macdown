//
//  MPScrollSyncController.h
//  MacDown
//

#import <Foundation/Foundation.h>

@class MPEditorView;
@class WebView;

@interface MPScrollSyncController : NSObject

- (instancetype)initWithEditor:(MPEditorView *)editor preview:(WebView *)preview;

- (void)updateHeaderLocations;
- (void)syncScrollers;

@end

