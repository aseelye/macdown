//
//  MPWebKitWorkarounds.h
//  MacDown
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class WebView;

void MPDisableLegacyWebViewCacheIfPossible(void);
void MPSetLegacyWebViewPageScaleMultiplier(WebView *webView, CGFloat scale);
