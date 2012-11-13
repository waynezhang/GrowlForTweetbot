//
//  GrowlForTweetbot.m
//  GrowlForTweetbot
//
//  Created by Linghua Zhang on 12/11/12.
//  Copyright (c) 2012年 Linghua Zhang. All rights reserved.
//

#import "GrowlForTweetbot.h"
#import <objc/runtime.h>

@interface GrowlForTweetbot()

+ (void)notifyWithTitle:(NSString *)title message:(NSString *)message sticky:(BOOL)sticky;

@end

@implementation NSObject(GrowlForTweetbot)

- (void)handleDirectMessage:(id)arg
{
  [self handleDirectMessage:arg];
  
  @try {
    NSString *text = [arg objectForKey:@"text"];
    NSString *from = [arg objectForKey:@"sender_screen_name"];

    [GrowlForTweetbot notifyWithTitle:@"Direct Message" message:[NSString stringWithFormat:@"%@: %@", from, text] sticky:YES];
  }
  @catch (NSException *exception) {
  }
  @finally {
  }
}

- (void)handleStatus:(id)arg
{
  [self handleStatus:arg];
  
  @try {
    static Ivar ivar;
    if (!ivar) {
      ivar = class_getInstanceVariable([self class], "_account");
    }
    if (ivar) {
      NSObject *account = object_getIvar(self, ivar);
      NSString *username = [account username];

      NSDictionary *entities = [arg objectForKey:@"entities"];
      NSArray *mentions = [entities objectForKey:@"user_mentions"];
      for (NSDictionary *m in mentions) {
        if ([[m objectForKey:@"screen_name"] isEqual:username]) {
          // is mentioned
          NSString *text = [arg objectForKey:@"text"];
          NSString *from = [[arg objectForKey:@"user"] objectForKey:@"screen_name"];         
          
          NSDictionary *retweeted = [arg objectForKey:@"retweeted_status"];
          if (retweeted != nil) {
            // is retweet
            [GrowlForTweetbot notifyWithTitle:[@"Retweeted by " stringByAppendingString:from] message:text sticky:NO];
          } else {
            [GrowlForTweetbot notifyWithTitle:[@"Mentioned by " stringByAppendingString:from] message:text sticky:NO];
          }
          break;
        }
      }
    }
  }
  @catch (NSException *exception) {
  }
  @finally {
  }
}

- (void)handleFollow:(id)arg
{
  [self handleFollow:arg];

  @try {
    NSDictionary *dictionary = (NSDictionary *)arg;
    NSString *name = [dictionary objectForKey:@"name"];
    NSString *screenName = [dictionary objectForKey:@"screen_name"];

    [GrowlForTweetbot notifyWithTitle:@"New follower" message:[NSString stringWithFormat:@"%@ - %@", screenName, name] sticky:YES];
  }
  @catch (NSException *exception) {
  }
  @finally {
  }
}

- (void)handleFavorited:(id)arg1 userDictionary:(id)arg2
{
  [self handleFavorited:arg1 userDictionary:arg2];

  @try {
    NSString *screenName = [arg2 objectForKey:@"screen_name"];
    NSString *text = [arg1 objectForKey:@"text"];

    [GrowlForTweetbot notifyWithTitle:[@"Favorited by " stringByAppendingString:screenName] message:text sticky:NO];
  }
  @catch (NSException *exception) {
  }
  @finally {
  }
}
@end


@implementation GrowlForTweetbot

+ (void)load
{
  // DM
  method_exchangeImplementations(class_getInstanceMethod(objc_getClass("PTHTweetbotStreamingController"), @selector(_handleDirectMessage:)),
                                                        class_getInstanceMethod(objc_getClass("NSObject"), @selector(handleDirectMessage:)));

  // tweets
  method_exchangeImplementations(class_getInstanceMethod(objc_getClass("PTHTweetbotStreamingController"), @selector(_handleStatus:)),
                                                        class_getInstanceMethod(objc_getClass("NSObject"), @selector(handleStatus:)));

  // follow
  method_exchangeImplementations(class_getInstanceMethod(objc_getClass("PTHTweetbotStreamingController"), @selector(_handleFollow:)),
                                                        class_getInstanceMethod(objc_getClass("NSObject"), @selector(handleFollow:)));

  // fav
  method_exchangeImplementations(class_getInstanceMethod(objc_getClass("PTHTweetbotStreamingController"), @selector(_handleFavorited:userDictionary:)),
                                                        class_getInstanceMethod(objc_getClass("NSObject"), @selector(handleFavorited:userDictionary:)));

  NSLog(@"GrowlForTweetbot installed");
  [self notifyWithTitle:@"GrowlForTweetbot" message:@"Installed" sticky:NO];
}

+ (void)notifyWithTitle:(NSString *)title message:(NSString *)message sticky:(BOOL)sticky
{
  NSString *commandLine = [NSString stringWithFormat:@"/usr/local/bin/growlnotify -t \"%@\" -m \"%@\" -a Tweetbot %@", title, message, sticky ? @" -s " : @""];
  system([commandLine cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
