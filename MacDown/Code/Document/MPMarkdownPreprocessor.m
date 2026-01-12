//
//  MPMarkdownPreprocessor.m
//  MacDown
//
//  Created by OpenAI on 2026/01/12.
//

#import "MPMarkdownPreprocessor.h"

NS_INLINE NSString *MPLineByStrippingUpTo3LeadingSpaces(NSString *line)
{
    NSUInteger spaceCount = 0;
    while (spaceCount < 3 && spaceCount < line.length
        && [line characterAtIndex:spaceCount] == ' ')
    {
        spaceCount++;
    }

    if (spaceCount == 0)
        return line;
    return [line substringFromIndex:spaceCount];
}

NS_INLINE BOOL MPLineIsTopLevelUnorderedListItem(NSString *line)
{
    line = MPLineByStrippingUpTo3LeadingSpaces(line);
    if (line.length < 2)
        return NO;

    unichar marker = [line characterAtIndex:0];
    if (marker != '-' && marker != '+' && marker != '*')
        return NO;

    unichar space = [line characterAtIndex:1];
    return (space == ' ' || space == '\t');
}

NS_INLINE BOOL MPLineIsTopLevelOrderedListItem(NSString *line)
{
    line = MPLineByStrippingUpTo3LeadingSpaces(line);
    if (line.length < 3)
        return NO;

    NSUInteger index = 0;
    while (index < line.length)
    {
        unichar c = [line characterAtIndex:index];
        if (c < '0' || c > '9')
            break;
        index++;
    }

    if (index == 0)
        return NO;

    if (index + 1 >= line.length)
        return NO;

    unichar delimiter = [line characterAtIndex:index];
    if (delimiter != '.' && delimiter != ')')
        return NO;

    unichar space = [line characterAtIndex:index + 1];
    return (space == ' ' || space == '\t');
}

NS_INLINE BOOL MPLineIsTopLevelListItem(NSString *line)
{
    return MPLineIsTopLevelUnorderedListItem(line)
        || MPLineIsTopLevelOrderedListItem(line);
}

NS_INLINE BOOL MPLineIsAtxHeading(NSString *line)
{
    line = MPLineByStrippingUpTo3LeadingSpaces(line);
    if (!line.length)
        return NO;

    NSUInteger hashCount = 0;
    while (hashCount < 6 && hashCount < line.length
        && [line characterAtIndex:hashCount] == '#')
    {
        hashCount++;
    }
    if (hashCount == 0)
        return NO;

    if (hashCount == line.length)
        return YES;

    unichar nextChar = [line characterAtIndex:hashCount];
    return (nextChar == ' ' || nextChar == '\t');
}

NS_INLINE BOOL MPLineIsSetextHeadingUnderline(
    NSString *line, unichar *outMarker)
{
    line = MPLineByStrippingUpTo3LeadingSpaces(line);
    if (line.length < 1)
        return NO;

    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    NSUInteger index = 0;
    while (index < line.length
        && [whitespace characterIsMember:[line characterAtIndex:index]])
    {
        index++;
    }
    if (index >= line.length)
        return NO;

    unichar marker = [line characterAtIndex:index];
    if (marker != '-' && marker != '=')
        return NO;

    NSUInteger count = 0;
    while (index < line.length)
    {
        unichar c = [line characterAtIndex:index];
        if (c == marker)
            count++;
        else if (![whitespace characterIsMember:c])
            return NO;
        index++;
    }

    if (count == 0)
        return NO;

    if (outMarker)
        *outMarker = marker;
    return YES;
}

NS_INLINE BOOL MPLineIsFencedCodeBlockMarker(NSString *line,
                                             unichar expectedMarker,
                                             unichar *outMarker)
{
    line = MPLineByStrippingUpTo3LeadingSpaces(line);
    if (line.length < 3)
        return NO;

    unichar marker = [line characterAtIndex:0];
    if (expectedMarker && marker != expectedMarker)
        return NO;

    if (marker != '`' && marker != '~')
        return NO;

    NSUInteger count = 0;
    while (count < line.length && [line characterAtIndex:count] == marker)
        count++;
    if (count < 3)
        return NO;

    if (outMarker)
        *outMarker = marker;
    return YES;
}

@implementation MPMarkdownPreprocessor

+ (NSString *)markdownForRenderingFromMarkdown:(NSString *)markdown
{
    if (!markdown.length)
        return @"";

    NSString *normalized =
        [markdown stringByReplacingOccurrencesOfString:@"\r\n"
                                            withString:@"\n"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"\r"
                                                       withString:@"\n"];

    NSArray<NSString *> *lines = [normalized componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *output =
        [NSMutableArray arrayWithCapacity:lines.count];

    BOOL inFencedCodeBlock = NO;
    unichar fenceMarker = 0;

    for (NSUInteger i = 0; i < lines.count; i++)
    {
        NSString *line = lines[i];
        [output addObject:line];

        if (inFencedCodeBlock)
        {
            if (MPLineIsFencedCodeBlockMarker(line, fenceMarker, NULL))
                inFencedCodeBlock = NO;
            continue;
        }

        if (MPLineIsFencedCodeBlockMarker(line, 0, &fenceMarker))
        {
            inFencedCodeBlock = YES;
            continue;
        }

        if (i + 1 >= lines.count)
            continue;

        NSString *nextLine = lines[i + 1];
        if (!MPLineIsTopLevelListItem(nextLine))
            continue;

        BOOL shouldInsertBlankLine = NO;
        if (MPLineIsAtxHeading(line))
        {
            shouldInsertBlankLine = YES;
        }
        else if (i > 0 && MPLineIsSetextHeadingUnderline(line, NULL))
        {
            NSString *previousLine = lines[i - 1];
            shouldInsertBlankLine =
                [[previousLine stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceCharacterSet]] length] > 0;
        }

        if (!shouldInsertBlankLine)
            continue;

        [output addObject:@""];
    }

    return [output componentsJoinedByString:@"\n"];
}

@end
