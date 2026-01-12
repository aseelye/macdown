//
//  MPWebKitWorkarounds.m
//  MacDown
//

#import "MPWebKitWorkarounds.h"

#import <WebKit/WebKit.h>

void MPDisableLegacyWebViewCacheIfPossible(void)
{
    // Uses private API [WebCache setDisabled:YES] to disable WebView's cache.
    Class webCacheClass = NSClassFromString(@"WebCache");
    if (!webCacheClass)
        return;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(setDisabled:);
    if (![webCacheClass respondsToSelector:selector])
        return;

    BOOL disabled = YES;
    NSMethodSignature *signature = [webCacheClass methodSignatureForSelector:selector];
    if (!signature)
        return;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = selector;
    invocation.target = webCacheClass;
    [invocation setArgument:&disabled atIndex:2];
    [invocation invoke];
#pragma clang diagnostic pop
}

void MPSetLegacyWebViewPageScaleMultiplier(WebView *webView, CGFloat scale)
{
    // Uses private WebKit API and is not App Store safe.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(setPageSizeMultiplier:);
    if (![webView respondsToSelector:selector])
        return;

    NSMethodSignature *signature = [webView methodSignatureForSelector:selector];
    if (!signature)
        return;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = selector;
    invocation.target = webView;
    [invocation setArgument:&scale atIndex:2];
    [invocation invoke];
#pragma clang diagnostic pop
}
