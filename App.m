
#import "App.h"


@implementation App


@synthesize appName;
@synthesize status;
@synthesize description;
@synthesize url;


-(id)init
{
	[super init];
	status = @"Unknown";
	
	return self;
	
}

-(void)dealloc
{
	[status release];
    [appName release];
    [description release];
    [url release];
    [super dealloc];
}
@end
