//
//  TimelieViewController.m
//  TwitterFon
//
//  Created by kaz on 7/23/08.
//  Copyright 2008 naan studio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TimelineViewController.h"
#import "TwitterFonAppDelegate.h"
#import "PostViewController.h"
#import "MessageCell.h"
#import "ColorUtils.h"
#import "StringUtil.h"

@interface NSObject (TimelineViewControllerDelegate)
- (void)postTweetDidSucceedDelegate:(NSDictionary*)dic;
@end

@implementation TimelineViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)dealloc {
    [userTimeline release];
    [timeline release];
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    unread   = 0;
    tag      = [self navigationController].tabBarItem.tag;

    switch (tag) {
        case TAB_FRIENDS:
            self.tableView.separatorColor = [UIColor whiteColor];
            break;
            
        case TAB_REPLIES:
            self.tableView.separatorColor =  [UIColor whiteColor];
            self.tableView.backgroundColor = [UIColor repliesColor:false];
            break;
            
        case TAB_MESSAGES:
            self.tableView.separatorColor =  [UIColor whiteColor];
            self.tableView.backgroundColor = [UIColor messageColor:false];
    }

    TwitterFonAppDelegate *appDelegate = (TwitterFonAppDelegate*)[UIApplication sharedApplication].delegate;
    imageStore = appDelegate.imageStore;
    timeline = [[Timeline alloc] initWithDelegate:self];
    
    [timeline restore:tag all:false];
    [timeline getTimeline:tag page:1 insertAt:0];
}


- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated 
{
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [timeline countMessages];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Message* message = [timeline messageAtIndex:indexPath.row];
    
    if (message.type <= MSG_TYPE_LOAD_FROM_WEB) {
        LoadCell * cell =  (LoadCell*)[tableView dequeueReusableCellWithIdentifier:@"LoadCell"];
        if (!cell) {
            cell = [[[LoadCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"LoadCell"] autorelease];
        }
        [cell setType:message.type];
        return cell;
    }

	MessageCell* cell = (MessageCell*)[tableView dequeueReusableCellWithIdentifier:MESSAGE_REUSE_INDICATOR];
	if (!cell) {
		cell = [[[MessageCell alloc] initWithFrame:CGRectZero reuseIdentifier:MESSAGE_REUSE_INDICATOR] autorelease];
	}
    
	cell.message = message;
    if (message.type > MSG_TYPE_LOAD_FROM_WEB) {
        [cell.profileImage setImage:[imageStore getImage:message.user.profileImageUrl delegate:self] forState:UIControlStateNormal];
    }

    if (tag == TAB_FRIENDS) {
        cell.contentView.backgroundColor = message.hasReply ?
            [UIColor repliesColor:message.unread] : [UIColor friendColor:message.unread];
    }
    else if (tag == TAB_REPLIES) {
        cell.contentView.backgroundColor = [UIColor repliesColor:message.unread];
    }
    else if (tag == TAB_MESSAGES) {
        cell.contentView.backgroundColor = [UIColor messageColor:message.unread];
    }

    [cell update:tag delegate:self];

	return cell;
}

- (void)didTouchLinkButton:(NSString*)url
{
    TwitterFonAppDelegate *appDelegate = (TwitterFonAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate openWebView:url on:[self navigationController]];
}

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
}

- (IBAction) post: (id) sender
{
    TwitterFonAppDelegate *appDelegate = (TwitterFonAppDelegate*)[UIApplication sharedApplication].delegate;
    PostViewController* postView = appDelegate.postView;

    [[self navigationController].view addSubview:postView.view];
    [postView startEdit];
}

- (IBAction) reload: (id) sender
{
    indexOfLoadCell = 0;
    [timeline getTimeline:tag page:1 insertAt:0];
}

- (void) loadMoreTweet:(NSIndexPath *)indexPath
{
    
}
//
// UITableViewDelegate
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *m = [timeline messageAtIndex:indexPath.row];
    return m.cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *m = [timeline messageAtIndex:indexPath.row];
    
    // Load missing tweet
    //
    if (m.type <= MSG_TYPE_LOAD_FROM_WEB) {
        LoadCell *cell = (LoadCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[LoadCell class]]) {
            [cell.spinner startAnimating];
        }
        int count = 0;
        if (m.type == MSG_TYPE_LOAD_FROM_DB) {
            count = [timeline restore:tag all:true];
            
            NSMutableArray *newPath = [[[NSMutableArray alloc] init] autorelease];

            // Avoid to create too many table cell.
            if (count > 0) {
                if (count > 2) count = 2;
                for (int i = 0; i < count; ++i) {
                    [newPath addObject:[NSIndexPath indexPathForRow:i + indexPath.row inSection:0]];
                }        
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:newPath withRowAnimation:UITableViewRowAnimationTop];
                [self.tableView endUpdates];   
            }
            else {
                [newPath addObject:indexPath];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:newPath withRowAnimation:UITableViewRowAnimationLeft];
                [self.tableView endUpdates];   
            }
            [self.tableView deselectRowAtIndexPath:indexPath animated:TRUE];   
        }
        else {
            indexOfLoadCell = indexPath.row;
            [timeline getTimeline:tag page:m.page insertAt:indexPath.row];
        }
    }
    //
    // Display user timeline
    //
    else {
        if (userTimeline == nil) {
            userTimeline = [[UserTimelineController alloc] initWithNibName:@"UserView" bundle:nil];
        }
        [[self navigationController] pushViewController:userTimeline animated:true];
        userTimeline.message = m;
        [self.tableView deselectRowAtIndexPath:indexPath animated:TRUE];   
    }
 
}

- (void)didTouchProfileImage:(MessageCell*)cell
{
    Message* m = cell.message;
    
    TwitterFonAppDelegate *appDelegate = (TwitterFonAppDelegate*)[UIApplication sharedApplication].delegate;
    PostViewController* postView = appDelegate.postView;
    
    if (postView.view.hidden == false) return;
    
    NSString *msg;
    if (tag == MSG_TYPE_MESSAGES) {
        msg = [NSString stringWithFormat:@"d %@ ", m.user.screenName];
    }
    else {
        msg = [NSString stringWithFormat:@"@%@ ", m.user.screenName];
    }
    
    [[self navigationController].view addSubview:postView.view];
    [postView startEditWithString:msg];
}

- (void)postViewAnimationDidFinish
{
    if (tag == TAB_FRIENDS && self.navigationController.topViewController == self) {
        //
        // Do animation if the controller displays friends timeline.
        //
        NSArray *indexPaths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], nil];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    }
}

- (void)postTweetDidSucceed:(NSDictionary*)dic
{
    if (tag == TAB_FRIENDS) {
        Message *message = [Message messageWithJsonDictionary:dic type:MSG_TYPE_FRIENDS];
        [timeline insertMessage:message];
    }
    else {
        //
        //  Do not come here anymore
    }
}

//
// TwitterFonApPDelegate delegate
//
- (void)didChangeSeletViewController:(UINavigationController*)navigationController
{
    navigationController.tabBarItem.badgeValue = nil;
    for (int i = 0; i < [timeline countMessages]; ++i) {
        Message* m = [timeline messageAtIndex:i];
        m.unread = false;
    }
    unread = 0;
}

//
// ImageStoreDelegate
//
- (void)imageStoreDidGetNewImage:(UIImage*)image
{
	[self.tableView reloadData];
}

//
// TimelineDelegate
//
- (void)timelineDidReceiveNewMessage:(Message*)msg
{
	[imageStore getImage:msg.user.profileImageUrl delegate:self];
}

- (void)timelineDidUpdate:(int)count insertAt:(int)position
{
    if (count) {
        unread += count;
        [self navigationController].tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", unread];
    }

    if (!self.view.hidden) {
        
        [self.tableView beginUpdates];
        
        if (indexOfLoadCell) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfLoadCell inSection:0] animated:TRUE];    
            NSMutableArray *deletion = [[[NSMutableArray alloc] init] autorelease];
            [deletion addObject:[NSIndexPath indexPathForRow:indexOfLoadCell inSection:0]];
            [self.tableView deleteRowsAtIndexPaths:deletion withRowAnimation:UITableViewRowAnimationLeft];
        }
        if (count != 0) {
            NSMutableArray *insertion = [[[NSMutableArray alloc] init] autorelease];
            
            // Avoid to create too many table cell.
            if (count > 8) count = 8;
            for (int i = 0; i < count; ++i) {
                [insertion addObject:[NSIndexPath indexPathForRow:position + i inSection:0]];
            }        
            [self.tableView insertRowsAtIndexPaths:insertion withRowAnimation:UITableViewRowAnimationTop];
        }
        
        [self.tableView endUpdates];    
    }

}
@end
