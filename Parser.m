#import "Parser.h"
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "App.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"


@implementation Parser


@synthesize networkQueue;
@synthesize apps;


- (void)createApp:(NSString *)status withArray:(NSMutableArray *)apps forNode:(HTMLNode *)trNode {
    App *app = [[App alloc] init];
    NSString *worksFine = [trNode rawContents];
    //NSLog(@"%@", worksFine);
    //Parse Appname out

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

    NSArray *tdNodes = [trNode findChildTags:@"td"];
    for (HTMLNode *tdNode in tdNodes) {


        // NSArray *notes = [[tdNode getAttributeNamed:@"class"] isEqualToString:@"notes"];

        if ([[tdNode getAttributeNamed:@"class"] isEqualToString:@"notes"]) {
            //for (HTMLNode *noteNode in notes) {
            NSString *appDesc = [tdNode allContents];
            [app setDescription:appDesc];

            //}
        }
    }
    [apps addObject:app];
    [app retain];
    app = [[App alloc] init];
}

- (void)parsePage:(HTMLNode *)bodyNode withArray:(NSMutableArray *)apps {
    NSArray *trNodes = [bodyNode findChildTags:@"tr"];
    for (HTMLNode *trNode in trNodes) {
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status1"]) {
            [self createApp:@"Unknown" withArray:apps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status2"]) {
            [self createApp:@"works" withArray:apps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status3"]) {
            [self createApp:@"does not work" withArray:apps forNode:trNode];
        }
        if ([[trNode getAttributeNamed:@"class"] isEqualToString:@"content status4"]) {
            [self createApp:@"has some problems" withArray:apps forNode:trNode];
        }

    }
}

- (void)check {
    if (![self networkQueue]) {
        [self setNetworkQueue:[[[ASINetworkQueue alloc] init] autorelease]];
    }
    [[self networkQueue] setDelegate:self];
    [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
    [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
    [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];

    NSInteger maxPage = 0;
    if (![self apps]) {
        apps = [[NSMutableArray alloc] init];
    }

    NSURL *url = [[NSURL alloc] initWithString:@"http://roaringapps.com/apps:table/p/1"];
    NSError *error = nil;
    NSString *html = [[NSString alloc] initWithContentsOfURL:url
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];

    NSError *parserError = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&parserError];

    if (error) {
        NSLog(@"Error: %@", error);
        return;
    }

    HTMLNode *bodyNode = [parser body];
    NSArray *inputNodes = [bodyNode findChildTags:@"span"];
    for (HTMLNode *spanNode in inputNodes) {
        if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"pager-no"]) {
            //Hier kann man die Seitenanzahl herausfinden
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

    //Since we already have the first page, lets parse this before requesting other pages!


    NSString *urlTemplate = @"http://roaringapps.com/apps:table/p/";
    [self parsePage:bodyNode withArray:apps];

    for (int i = 2; i <= maxPage; i++) {
        NSString *completeUrl = [NSString stringWithFormat:@"%@%d", urlTemplate, i];
        NSURL *newUrl = [[NSURL alloc] initWithString:completeUrl];

        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:newUrl];
        [[self networkQueue] addOperation:request];

        [completeUrl retain];
        [url retain];
        [parser retain];
    }

    [[self networkQueue] go];
    [urlTemplate retain];
    return apps;
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    NSString *response = [request responseString];
    NSError *newParserError = nil;
    HTMLParser *newParser = [[HTMLParser alloc] initWithString:response error:&newParserError];
    HTMLNode *newBodyNode = [newParser body];
    [self parsePage:newBodyNode withArray:apps];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];

    NSLog(@"%∆", error);
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	// You could release the queue here if you wanted
	if ([[self networkQueue] requestsCount] == 0) {
		[self setNetworkQueue:nil];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RequestsFinishedNotification" object:apps];
	NSLog(@"Queue finished");
}




- (void)dealloc {
    [networkQueue release];
    [apps release];
    [super dealloc];
}

@end
