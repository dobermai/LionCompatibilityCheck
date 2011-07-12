

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
	
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *controller;
    NSArray *installedApplications;

}

@property(nonatomic, retain) NSArray *installedApplications;

-(IBAction) scanApps:(id)sender;


@end
