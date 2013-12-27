//
//  ViewController.h
//  tweeter
//
//  Created by Todd Munnik on 12/23/13.
//  Copyright (c) 2013 Todd Munnik. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *tweetText;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
