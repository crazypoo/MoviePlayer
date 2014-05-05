//
//  PooViewController.m
//  MoviePlayer
//
//  Created by crazypoo on 14-4-22.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooViewController.h"
#import "PooPlayMovieViewController.h"

@interface PooViewController ()<PooPlayMovieViewControllerDataSource>

@end

@implementation PooViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *camera = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [camera addTarget:self action:@selector(playNetMovie) forControlEvents:UIControlEventTouchUpInside];
    camera.frame = CGRectMake(0, 100, 100, 100);
    [self.view addSubview:camera];
}

- (void)playNetMovie
{
    NSURL *url = [NSURL URLWithString:@"http://v.youku.com/player/getRealM3U8/vid/XNzAwMTQzOTM2/type/mp4/v.m3u8"];
    PooPlayMovieViewController *movieVC = [[PooPlayMovieViewController alloc]initNetworkPooPlayMovieViewControllerWithURL:url movieTitle:@"暴走大事件9"];
    movieVC.datasource = self;
    [self presentViewController:movieVC animated:YES completion:nil];
}

- (BOOL)isHavePreviousMovie
{
    return NO;
}

- (BOOL)isHaveNextMovie
{
    return NO;
}

- (NSDictionary *)previousMovieURLAndTitleToTheCurrentMovie
{
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSURL URLWithString:@"http://v.youku.com/player/getRealM3U8/vid/XNzAwMTQzOTM2/type/mp4/v.m3u8"],KURLOfMovieDicTionary,@"qqqqqqq",KTitleOfMovieDictionary, nil];
    return dic;
}

- (NSDictionary *)nextMovieURLAndTitleToTheCurrentMovie
{
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
