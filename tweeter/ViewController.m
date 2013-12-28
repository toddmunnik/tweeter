//
//  ViewController.m
//  tweeter
//
//  Created by Todd Munnik on 12/23/13.
//  Copyright (c) 2013 Todd Munnik. All rights reserved.
//

#import "ViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "Tweet.h"

@interface ViewController ()
{
    ACAccountStore *accountStore;
    ACAccountType *accountType;
    NSMutableArray *arrayOfTweets;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self tableView]setDataSource:self];
    [[self tableView]setDelegate:self];
    [[self tweetText]setDelegate:self];

    [self fetchTweets];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) buildAccountStore
{
    if (accountStore == nil) {
        accountStore = [[ACAccountStore alloc] init];
        
        accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arrayOfTweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    Tweet *tweet = [arrayOfTweets objectAtIndex:indexPath.row];

    cell.textLabel.text = tweet.text;
    cell.detailTextLabel.text = tweet.status;
    
    return cell;
}

- (void)fetchTweets
{
    [self buildAccountStore];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil
                                       completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             // Get the list of Twitter accounts.
             NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
             
             if ([accountsArray count] > 0) {
    
                ACAccount *twitterAccount = [accountsArray objectAtIndex:0];
                NSURL *requestURL = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/user_timeline.json"];
                
                NSMutableDictionary *parameters =
                [[NSMutableDictionary alloc] init];
                [parameters setObject:@"10" forKey:@"count"];
                [parameters setObject:@"0" forKey:@"include_entities"];
                
                SLRequest *postRequest = [SLRequest
                                          requestForServiceType:SLServiceTypeTwitter
                                          requestMethod:SLRequestMethodGET
                                          URL:requestURL parameters:parameters];
                
                postRequest.account = twitterAccount;
                
                [postRequest performRequestWithHandler:
                 ^(NSData *responseData, NSHTTPURLResponse
                   *urlResponse, NSError *error)
                 {
                     NSArray *result = [NSJSONSerialization
                                        JSONObjectWithData:responseData
                                        options:NSJSONReadingMutableLeaves
                                        error:&error];
                     
                     if (result.count != 0) {
                         
                         arrayOfTweets = [[NSMutableArray alloc] init];
                         
                         for(NSDictionary *item in result) {
                             
                             //build arrayOfTweets from result
                             Tweet *tweet = [[Tweet alloc] init];
                             tweet.text = [item objectForKey:@"text"];
                             tweet.status = @"Success";
                             
                             [arrayOfTweets addObject:tweet];
                         }
                         [self reloadTable];
                     }
                 }];
            }
         }
     }];
}

- (IBAction)postTweet:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
        [self buildAccountStore];
    
        [accountStore requestAccessToAccountsWithType:accountType options:nil
                                  completion:^(BOOL granted, NSError *error)
         {
             if (granted == YES)
             {
                 // Get the list of Twitter accounts.
                 NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
                 if ([accountsArray count] > 0) {
                
                     //default to the first one
                     ACAccount *twitterAccount = [accountsArray objectAtIndex:0];
                
                     NSString *tweetText = [_tweetText.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                     NSDictionary *message = @{@"status": tweetText};
                
                     NSURL *requestURL = [NSURL
                                     URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
                
                     SLRequest *postRequest = [SLRequest
                                          requestForServiceType:SLServiceTypeTwitter
                                          requestMethod:SLRequestMethodPOST
                                          URL:requestURL parameters:message];
                
                     postRequest.account = twitterAccount;
                
                     [postRequest performRequestWithHandler:^(NSData *responseData,
                                                         NSHTTPURLResponse *urlResponse, NSError *error)
                      {
                          int responseStatusCode = [urlResponse statusCode];
                          NSString *responseString;
                          if (responseStatusCode == 200)
                          {
                              responseString = @"Submitted";
                          }
                          else {
                              responseString = @"Failed";
                          }
                          
                          Tweet *tweet = [[Tweet alloc] init];
                          tweet.text = [message objectForKey:@"status"];
                          
                          if ([tweet.text isEqualToString:@""]) {
                              tweet.text = @"(empty)";
                          }
                          
                          tweet.status = responseString;
                          
                          [arrayOfTweets insertObject:tweet atIndex:0];
                          
                          [self reloadTable];
                          
                          [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                              
                              _tweetText.text = @"";
                              
                              //do not fetch successful tweets unless responseStatusCode == 200
                              if (responseStatusCode == 200)
                              {
                                  [self fetchTweets];
                              }
                          }];
                      }];
                 }
             }
         }];
    });
}

-(void)reloadTable {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];
    });
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text hasSuffix:@"\n"]) {
        [self postTweet:nil];
    }
    return YES;
}

@end
