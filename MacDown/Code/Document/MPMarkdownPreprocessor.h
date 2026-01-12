//
//  MPMarkdownPreprocessor.h
//  MacDown
//
//  Created by OpenAI on 2026/01/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPMarkdownPreprocessor : NSObject

+ (NSString *)markdownForRenderingFromMarkdown:(NSString *)markdown;

@end

NS_ASSUME_NONNULL_END

