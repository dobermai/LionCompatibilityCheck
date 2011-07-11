

#import <Foundation/Foundation.h>


@interface App : NSObject {
	
	NSString *appName;
	NSString *status;
    NSString *description;
    NSString *url;

}
@property(nonatomic, copy) NSString *appName;
@property(nonatomic, copy) NSString *status;
@property(nonatomic, copy) NSString *description;
@property(nonatomic, copy) NSString *url;


@end
