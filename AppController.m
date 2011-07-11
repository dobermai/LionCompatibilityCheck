

#import "AppController.h"
#import "App.h"
#import "FileScanner.h"
#import "Parser.h"


@implementation AppController

- (IBAction)scanApps:(id)sender {
    FileScanner *scanner = [[FileScanner alloc] init];
    //Remove all old objects
    [[controller mutableArrayValueForKey:@"content"] removeAllObjects];
    NSArray *installedApplications = [scanner allApplications];

    Parser *parser = [[Parser alloc] init];
    NSArray *allApplications = [parser check];

    for (NSString *installedApp in installedApplications) {

        //Uaaah, this is very dirty. We need a better way, iterating through this HUGE list is not that sexy...
        for(App *app in allApplications)
        {
            if([installedApp isEqualToString:[app appName]])
            {
                [controller addObject:app];
            }
        }
    }

}


@end
