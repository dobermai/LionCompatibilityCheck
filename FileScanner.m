
#import "FileScanner.h"


@implementation FileScanner

NSFileManager *filemgr;

- (NSArray*) allApplications
{
	NSArray *appList;
	
	NSError *error = nil;
	
	appList = [filemgr contentsOfDirectoryAtPath:@"/Applications" error:&error];
	
	if(error)
	{
		NSLog(@"A fatal error occured: %@",*error);
	}
	
	
	return [self parseAppNames:appList];
	
}

- (NSArray*) parseAppNames:(NSArray*) appNameArray
{
	NSMutableArray *resultArr = [[NSMutableArray alloc]init];
	for(NSString *string in appNameArray)
	{
		NSRange end = [string rangeOfString:@"."];
		if((end.location != 0) && (end.length != 0))
		{
		NSString *newString = [NSString stringWithString:[string substringWithRange:NSMakeRange(0, end.location)]];
		NSLog(@"%@",newString);
		[resultArr addObject:newString];
			
		}
	}
	return [NSArray arrayWithArray:resultArr];
}

- (IBAction) action:(id)sender
{
	[self allApplications];
}

- (id)init
{
	[super init];
	filemgr = [NSFileManager defaultManager];
	
	return self;
	
}
@end
