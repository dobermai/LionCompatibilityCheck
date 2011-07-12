
#import <Cocoa/Cocoa.h>

@class ASINetworkQueue;


@interface Parser : NSObject {

    ASINetworkQueue *networkQueue;
    NSMutableArray *apps;

}

@property(nonatomic, retain) ASINetworkQueue *networkQueue;
@property(nonatomic, retain) NSMutableArray *apps;


-(id) initWithArr:(NSArray*)arr;

-(void)check;

@end
