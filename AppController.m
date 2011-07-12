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
    [progressBar setHidden:NO];
    [progressBar setIndeterminate:YES];
    [progressBar displayIfNeeded];
    [progressBar startAnimation:self];
    [progressBar setToolTip:@"Preparing Download of Compatibility Data"];


    [parser check];

}

- (void)receiveAppArray:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"RequestsFinishedNotification"]) {
        NSArray *allApplications = [notification object];

        for (NSString *installedApp in installedApplications) {

            //Uaaah, this is very dirty. We need a better way, iterating through this HUGE list is not that sexy...
            //Perhaps we should use a dictionary?
            for (App *app in allApplications) {
                if ([installedApp isEqualToString:[app appName]]) {
                    [controller addObject:app];
                }
            }
            //Add all apps which are not in the list
        }
        [progressBar stopAnimation:self];
        [progressBar setHidden:YES];
    }
}

- (void)updateProgress {
    [progressBar setDoubleValue:[progressBar doubleValue] + 1];
    double d = (100 / [progressBar maxValue] * [progressBar doubleValue]);
    [progressBar setToolTip:[NSString stringWithFormat:@"Downloaded %.f%%", d]];
}

- (void)setProgressSize:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"ProgressSize"]) {

        NSNumber *progressSize = [notification object];
        if ([progressBar isIndeterminate]) {
            [progressBar setIndeterminate:NO];
        }
        [progressBar setDoubleValue:0];
        [progressBar setMaxValue:[progressSize doubleValue]];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveAppArray:)
                                                     name:@"RequestsFinishedNotification"
                                                   object:nil];
        //Let's notify when there was a progress update
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateProgress)
                                                     name:@"UpdateProgressStatus"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressSize:)
                                                     name:@"ProgressSize"
                                                   object:nil];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [progressBar setHidden:YES];
}


- (void)dealloc {
    [installedApplications release];
    [super dealloc];
}


@end
