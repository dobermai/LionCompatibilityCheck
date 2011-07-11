

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
	
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *controller;

}

-(IBAction) scanApps:(id)sender;


@end
