#import "Parser.h"
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "App.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"


@implementation Parser


@synthesize networkQueue;
@synthesize apps;
@synthesize maxPage;


// Does all the checking action
- (void)check {
    if (![self networkQueue]) {
        [self setNetworkQueue:[[[ASINetworkQueue alloc] init] autorelease]];
    }
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];

    if (![self apps]) {
        apps = [[NSMutableArray alloc] init];
    }

    NSURL *url = [[NSURL alloc] initWithString:@"http://roaringapps.com/apps:table/p/1"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(firstRequestFinished:)];
    [request startAsynchronous];
}

//Creates an application Object with a given status and parses the relevant Stuff out of a HTML Node
- (void)createApp:(NSString *)status withArray:(NSMutableArray *)receivedApps forNode:(HTMLNode *)trNode {
    App *app = [[App alloc] init];

    //Parse Appname and URL
    NSArray *pNodes = [trNode findChildTags:@"p"];
    [app setStatus:status];

    for (HTMLNode *pNode in pNodes) {
        HTMLNode *child = [pNode findChildTag:@"a"];
        if (child != nil) {

            NSString *appName = [pNode allContents];
            [app setAppName:appName];
            NSLog(@"Appname: %@", appName);

            NSString *url = [child getAttributeNamed:@"href"];
            [app setUrl:url];
            NSLog(@"URL: %@", url);
        }

    }

    //Lets find the description
    NSArray *tdNodes = [trNode findChildTags:@"td"];
    for (HTMLNode *tdNode in tdNodes) {


        if ([[tdNode getAttributeNamed:@"class"] isEqualToString:@"notes"]) {
            NSString *appDesc = [tdNode allContents];
            [app setDescription:appDesc];
        }
    }
    [receivedApps addObject:app];

    app = [[App alloc] init];
}

// Delegates to the right method for the parsed out status
- (void)parsePage:(HTMLNode *)bodyNode withArray:(NSMutableArray *)receivedApps {
    NSArray *trNodes = [bodyNode findChildTags:@"tr"];
    for (HTMLNode *trNode in trNodes) {
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status1"]) {
            [self createApp:@"Unknown" withArray:receivedApps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status2"]) {
            [self createApp:@"works" withArray:receivedApps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status3"]) {
            [self createApp:@"does not work" withArray:receivedApps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status4"]) {
            [self createApp:@"has some problems" withArray:receivedApps forNode:trNode];
        }
    }
}

- (void)parseNextPages {
    NSString *urlTemplate = @"http://roaringapps.com/apps:table/p/";
	
    for (int i = 2; i <= maxPage; i++) {
        NSString *completeUrl = [NSString stringWithFormat:@"%@%d", urlTemplate, i];
        NSURL *url = [[NSURL alloc] initWithString:completeUrl];
		
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [[self networkQueue] addOperation:request];
    }
	
    [[self networkQueue] go];
}


- (void)requestFinished:(ASIHTTPRequest *)request {
	
    NSString *response = [request responseString];
	
    NSError *parserError = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:response error:&parserError];
    HTMLNode *bodyNode = [parser body];
	
	if (parserError) {
        NSLog(@"Error: %@", parserError);
        return;
    }
	
    [self parsePage:bodyNode withArray:apps];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
	
    NSLog(@"%@", error);
}

- (void)queueFinished:(ASINetworkQueue *)queue {
    if ([[self networkQueue] requestsCount] == 0) {
        [self setNetworkQueue:nil];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RequestsFinishedNotification" object:apps];
    NSLog(@"Finished with Parsing all pages");
}

- (void)firstRequestFinished:(ASIHTTPRequest *)request {
    NSError *parserError = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:[request responseString] error:&parserError];

    if (parserError) {
        NSLog(@"Error: %@", parserError);
        return;
    }

    HTMLNode *bodyNode = [parser body];
    NSArray *inputNodes = [bodyNode findChildTags:@"span"];

    //Find out page Number
    for (HTMLNode *spanNode in inputNodes) {
        if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"pager-no"]) {
            NSString *completePagerSpan = [spanNode rawContents];
            NSLog(@"%@", completePagerSpan);
            NSArray *substrArr = [completePagerSpan componentsSeparatedByString:@" "];

            for (NSString *substr in substrArr) {
                NSInteger maxPageNr = (NSInteger) [substr integerValue];

                if ((maxPageNr != 0) && (maxPageNr != 1)) {
                    maxPage = maxPageNr;
                    NSLog(@"Found max Pages: %d", maxPage);
                }
            }

            break; //Found, we can break out
        }
    }
    //We parsed the Pagenumber, now parse out the rest
    [self requestFinished:request];

    //Since we have all information needed (pageNumber), we can continue with all the other pages
    [self parseNextPages];
}

- (id)init {
    self = [super init];
    if (self) {

        maxPage = 0;
    }

    return self;
}


- (void)dealloc {
    [networkQueue release];
    [apps release];
    [super dealloc];
}

@end
