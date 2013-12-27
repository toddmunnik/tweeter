//
//  CustomViewCell.h
//  tweeter
//
//  Created by Todd Munnik on 12/26/13.
//  Copyright (c) 2013 Todd Munnik. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CustomView;
@interface CustomViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *tweetTextLabel;
@property (strong, nonatomic) IBOutlet UILabel *tweetResponseLabel;

@end
