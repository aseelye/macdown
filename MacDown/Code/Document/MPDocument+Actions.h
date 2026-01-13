//
//  MPDocument+Actions.h
//  MacDown
//

#import "MPDocument.h"

@interface MPDocument (Actions)

- (IBAction)copyHtml:(id)sender;
- (IBAction)exportHtml:(id)sender;
- (IBAction)exportPdf:(id)sender;

- (IBAction)convertToH1:(id)sender;
- (IBAction)convertToH2:(id)sender;
- (IBAction)convertToH3:(id)sender;
- (IBAction)convertToH4:(id)sender;
- (IBAction)convertToH5:(id)sender;
- (IBAction)convertToH6:(id)sender;
- (IBAction)convertToParagraph:(id)sender;

- (IBAction)toggleStrong:(id)sender;
- (IBAction)toggleEmphasis:(id)sender;
- (IBAction)toggleInlineCode:(id)sender;
- (IBAction)toggleStrikethrough:(id)sender;
- (IBAction)toggleUnderline:(id)sender;
- (IBAction)toggleHighlight:(id)sender;
- (IBAction)toggleComment:(id)sender;
- (IBAction)toggleLink:(id)sender;
- (IBAction)toggleImage:(id)sender;

- (IBAction)toggleOrderedList:(id)sender;
- (IBAction)toggleUnorderedList:(id)sender;
- (IBAction)toggleBlockquote:(id)sender;

- (IBAction)indent:(id)sender;
- (IBAction)unindent:(id)sender;

- (IBAction)insertNewParagraph:(id)sender;

- (IBAction)setEditorOneQuarter:(id)sender;
- (IBAction)setEditorThreeQuarters:(id)sender;
- (IBAction)setEqualSplit:(id)sender;

- (IBAction)toggleToolbar:(id)sender;
- (IBAction)togglePreviewPane:(id)sender;
- (IBAction)toggleEditorPane:(id)sender;

- (IBAction)render:(id)sender;

@end

