//
//  ViewController.m
//  micLevel
//
//  Created by jie shi on 2/21/17.
//  Copyright © 2017 jie shi. All rights reserved.
//

#import "ViewController.h"
#import "GameViewController.h"
#import <AVFoundation/AVFoundation.h>

//大于ios8以上
#define IOMIOS8Later    ([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0 ? YES : NO)

//屏幕宽
#define MainWidth (!IOMIOS8Later?[UIScreen mainScreen].bounds.size.height:[[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.height)
//屏幕高
#define MainHeight (!IOMIOS8Later?[UIScreen mainScreen].bounds.size.width:[[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.width)

@interface ViewController ()
@property (nonatomic, strong)AVAudioRecorder *recorder;
@property (nonatomic, strong)NSTimer *levelTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    NSMutableArray *images=[[NSMutableArray alloc]init];
    for (NSInteger i=1; i<=8; i++) {
        NSString *name=[NSString stringWithFormat:@"perRun%ld",(long)i];
        UIImage *image=[UIImage imageNamed:name];
        [images addObject:image];
    }
    UIImageView *playerView=[[UIImageView alloc]initWithFrame:CGRectMake((MainWidth - 78)/2, (MainHeight - 60)/2, 78, 60)];
    [playerView setImage:[UIImage imageNamed:@"perRun8"]];
    [playerView setBackgroundColor:[UIColor clearColor]];
    playerView.animationDuration=0.5;
    playerView.animationImages=images;
    playerView.animationRepeatCount=0;
    [playerView startAnimating];
    [self.view addSubview:playerView];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake((MainWidth - 200)/2, (MainHeight - 44)/2 + 80, 200, 44)];
    [btn setBackgroundColor:[UIColor whiteColor]];
    [btn setTitle:@"点击开始" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [btn.layer setCornerRadius:10];
    [btn.layer setMasksToBounds:YES];
    [btn.layer setBorderWidth:1.0];
    [btn.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.view addSubview:btn];
    
    UILabel *textLabel = [[UILabel alloc] init];
    [textLabel setFrame:CGRectMake((MainWidth - 200)/2, (MainHeight - 30), 200, 30)];
    [textLabel setTextColor:[UIColor lightGrayColor]];
    [textLabel setBackgroundColor:[UIColor whiteColor]];
    [textLabel setFont:[UIFont systemFontOfSize:12]];
    [textLabel setTextAlignment:NSTextAlignmentCenter];
    [textLabel setText:@"你也可以试试大喊一声~"];
    [self.view addSubview:textLabel];
}

- (void)initRecorder {
    /* 必须添加这句话，否则在模拟器可以，在真机上获取始终是0  */
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    
    /* 不需要保存录音文件 */
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                              nil];
    NSError *error;
    if (!_recorder) {
        _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    }
    if (_recorder) {
        [_recorder prepareToRecord];
        _recorder.meteringEnabled = YES;
        [_recorder record];
        if (!_levelTimer) {
            _levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
        }
    } else {
        NSLog(@"%@", [error description]);
    }
}

- (void)levelTimerCallback:(NSTimer *)timer {
    [_recorder updateMeters];
    
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [_recorder averagePowerForChannel:0];
    
    if (decibels < minDecibels) {
        level = 0.0f;
    } else if (decibels >= 0.0f) {
        level = 1.0f;
    } else {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    /* level 范围[0 ~ 1], 转为[0 ~120] 之间 */
    __weak typeof(self) weakSelf = self;
    if (level * 120 > 80) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf start];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self initRecorder];
}

- (void)start {
    [self.levelTimer invalidate];
    self.levelTimer = nil;
    
    [_recorder stop];
    self.recorder = nil;
    
    GameViewController *gameViewController = [[GameViewController alloc] init];
    [self.navigationController pushViewController:gameViewController animated:YES];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
