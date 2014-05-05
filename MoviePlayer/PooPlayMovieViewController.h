//
//  PooPlayMovieViewController.h
//  MoviePlayer
//
//  Created by crazypoo on 14-4-22.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol PooPlayMovieViewControllerDelegate <NSObject>
- (void)movieFinished:(CGFloat)progress;
@end

@protocol PooPlayMovieViewControllerDataSource <NSObject>

#define KTitleOfMovieDictionary @"title"
#define KURLOfMovieDicTionary @"url"

@required
- (NSDictionary *)nextMovieURLAndTitleToTheCurrentMovie;
- (NSDictionary *)previousMovieURLAndTitleToTheCurrentMovie;
- (BOOL)isHaveNextMovie;
- (BOOL)isHavePreviousMovie;
@end

@interface PooPlayMovieViewController : UIViewController
typedef enum {
    PooPlayMovieViewControllerModeNetwork = 0,
    PooPlayMovieViewControllerModeLocal
} PooPlayMovieViewControllerMode;

@property (nonatomic,strong,readonly)NSURL *movieURL;
@property (nonatomic,strong,readonly)NSArray *movieURLList;
@property (readonly,nonatomic,copy)NSString *movieTitle;
@property (nonatomic, assign) id<PooPlayMovieViewControllerDelegate> delegate;
@property (nonatomic, assign) id<PooPlayMovieViewControllerDataSource> datasource;
@property (nonatomic, assign) PooPlayMovieViewControllerMode mode;

- (id)initNetworkPooPlayMovieViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle;
- (id)initLocalPooPlayMovieViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle;
- (id)initLocalPooPlayMovieViewControllerWithURLList:(NSArray *)urlList movieTitle:(NSString *)movieTitle;
@end
