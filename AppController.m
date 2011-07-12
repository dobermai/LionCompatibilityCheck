#import "AppController.h"
#import "App.h"
#import "FileScanner.h"
#import "Parser.h"


@implementation AppController

@synthesize installedApplications;

- (IBAction)scanApps:(id)sender {
    FileScanner *scanner = [[FileScanner alloc] init];
    //Remove all old objects
    [[controller mutableArrayValueForKey:@"content"] removeAllObjects];
    [self setInstalledApplications:[scanner allApplications]];

    Parser *parser = [[Parser alloc] init];
    [parser check];

}

- (void)receiveAppArray:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"RequestsFinishedNotification"]) {
        NSLog(@"Successfully received the test notification!");
        NSArray *allApplications = [notification object];

        for (NSString *installedApp in installedApplications) {

//Uaaah, this is very dirty. We need a better way, iterating through this HUGE list is not that sexy...
            for (App *app in allApplications) {
                if ([installedApp isEqualToString:[app appName]]) {
                    [controller addObject:app];
                }
            }
            //Add al apps which are not in the list
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveAppArray:)
                                                     name:@"RequestsFinishedNotification"
                                                   object:nil];
    }

    return self;
//To change the template use AppCode | Preferences | File Templates.
}

- (void)dealloc {
    [installedApplications release];
    [super dealloc];
}


@end
