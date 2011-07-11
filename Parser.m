
#import "Parser.h"
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "App.h"


@implementation Parser


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

- (NSArray *)check {
    NSInteger maxPage = 0;
    NSMutableArray *apps = [[NSMutableArray alloc] init];

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
        NSError *urlError = nil;
        NSString *newHtml = [[NSString alloc] initWithContentsOfURL:newUrl
                                                           encoding:NSUTF8StringEncoding
                                                              error:&urlError];
        if (error) {
            NSLog(@"Error: %@", error);
            return;
        }

        NSError *newParserError = nil;
        HTMLParser *newParser = [[HTMLParser alloc] initWithString:newHtml error:&newParserError];
        HTMLNode *newBodyNode = [newParser body];
        [self parsePage:newBodyNode withArray:apps];

        [completeUrl retain];
        [url retain];
        [parser retain];
    }

    [urlTemplate retain];
    return apps;
}

@end
