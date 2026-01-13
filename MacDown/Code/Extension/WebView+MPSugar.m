//
//  WebView+MPSugar.m
//  MacDown
//

#import "WebView+MPSugar.h"

@implementation WebView (MPSugar)

- (NSScrollView *)enclosingScrollView
{
    return self.mainFrame.frameView.documentView.enclosingScrollView;
}

@end

