//
//  MessageCellView.h
//  TwitterFon
//
//  Created by kaz on 11/2/08.
//  Copyright 2008 naan studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@interface MessageCellView : UIView {
    Message*    message;
}

@property(nonatomic, retain) Message* message;

@end
