//
//  MPToolbarControllerTests.m
//  MacDownTests
//

#import <XCTest/XCTest.h>

#import "MPToolbarController.h"

@interface MPToolbarController (Testing)
- (void)selectedToolbarItemGroupItem:(NSSegmentedControl *)sender;
@end

@interface MPToolbarControllerActionSpyDocument : MPDocument
@property SEL lastAction;
@property (strong) id lastSender;
@end

@implementation MPToolbarControllerActionSpyDocument

- (IBAction)indent:(id)sender
{
    self.lastAction = _cmd;
    self.lastSender = sender;
}

- (IBAction)unindent:(id)sender
{
    self.lastAction = _cmd;
    self.lastSender = sender;
}

@end

@interface MPToolbarControllerTests : XCTestCase
@end

@implementation MPToolbarControllerTests

- (void)testSegmentedToolbarInvokesUnindentWithSender
{
    MPToolbarController *controller = [[MPToolbarController alloc] init];
    MPToolbarControllerActionSpyDocument *doc =
        [[MPToolbarControllerActionSpyDocument alloc] init];
    controller.document = doc;

    NSSegmentedControl *segmented = [[NSSegmentedControl alloc] init];
    segmented.identifier = @"indent-group";
    segmented.selectedSegment = 0;

    [controller selectedToolbarItemGroupItem:segmented];

    XCTAssertEqual(doc.lastAction, @selector(unindent:));
    XCTAssertEqual(doc.lastSender, segmented);
}

- (void)testSegmentedToolbarInvokesIndentWithSender
{
    MPToolbarController *controller = [[MPToolbarController alloc] init];
    MPToolbarControllerActionSpyDocument *doc =
        [[MPToolbarControllerActionSpyDocument alloc] init];
    controller.document = doc;

    NSSegmentedControl *segmented = [[NSSegmentedControl alloc] init];
    segmented.identifier = @"indent-group";
    segmented.selectedSegment = 1;

    [controller selectedToolbarItemGroupItem:segmented];

    XCTAssertEqual(doc.lastAction, @selector(indent:));
    XCTAssertEqual(doc.lastSender, segmented);
}

- (void)testSegmentedToolbarDoesNothingWhenDocumentIsNil
{
    MPToolbarController *controller = [[MPToolbarController alloc] init];

    NSSegmentedControl *segmented = [[NSSegmentedControl alloc] init];
    segmented.identifier = @"indent-group";
    segmented.selectedSegment = 0;

    XCTAssertNoThrow([controller selectedToolbarItemGroupItem:segmented]);
}

@end
