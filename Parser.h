
#import <Cocoa/Cocoa.h>

@class ASINetworkQueue;


@interface Parser : NSObject {

    ASINetworkQueue *networkQueue;
    NSMutableArray *apps;
    NSInteger maxPage;

}

@property(nonatomic, retain) ASINetworkQueue *networkQueue;
@property(nonatomic, retain) NSMutableArray *apps;
@property(nonatomic) NSInteger maxPage;



-(void)check;

@end
