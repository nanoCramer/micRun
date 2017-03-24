//
//  GameViewController.m
//  micLevel
//
//  Created by jie shi on 2/21/17.
//  Copyright © 2017 jie shi. All rights reserved.
//

#import "GameViewController.h"
#import <AVFoundation/AVFoundation.h>

#define KWhiteMaxLength 100
#define KWhiteMinLength 40
#define KBlackMaxLength 300
#define KBlackMinLength 50
#define KBlackHeight    MainHeight*0.3
#define KBlackViewTag   100000
#define KAlertViewTag   200000

#define KUpSpeed        3
#define KDownSpeed      5

#define KLastTime       10

//大于ios8以上
#define IOMIOS8Later    ([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0 ? YES : NO)

//屏幕宽
#define MainWidth (!IOMIOS8Later?[UIScreen mainScreen].bounds.size.height:[[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.height)
//屏幕高
#define MainHeight (!IOMIOS8Later?[UIScreen mainScreen].bounds.size.width:[[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size.width)

typedef NS_ENUM(NSInteger, EHeightLevel) {
    EHeightLevel0       = 0,    //[0, 0.5]
    EHeightLevel1       = 1,    //(0.50, 0.65]
    EHeightLevel2,              //(0.65, 0.80]
    EHeightLevel3,              //(0.80, 0.90]
    EHeightLevel4,              //(0.90, 1.00]
};

typedef NS_ENUM(NSInteger, EPlayerStatus) {
    EPlayerStatusWalk   = 0,
    EPlayerStatusUp,
    EPlayerStatusDown,
};

@interface GameViewController () <UIAlertViewDelegate>
@property (nonatomic, strong)AVAudioRecorder *recorder;
@property (nonatomic, strong)NSTimer *levelTimer;
//@property (nonatomic, strong)UILabel *textLabel;
@property (nonatomic, strong)UIView *levelView;
@property (nonatomic, strong)UILabel *scoreLabel;

@property (nonatomic, strong)UIImageView *playerView;   //
@property (nonatomic, assign)EPlayerStatus playerStatus;

@property (nonatomic, assign)CGFloat maxLevel;
@property (nonatomic, assign)NSInteger lastTime;
@property (nonatomic, assign)NSInteger jumpHeight;
@property (nonatomic, assign)EHeightLevel heightLevel;
@property (nonatomic, assign)NSInteger score;

@property (nonatomic, assign)BOOL shouldStop;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _maxLevel = 0.0;
    _playerStatus = EPlayerStatusWalk;
    _lastTime = KLastTime;
    _jumpHeight = 0;
    _heightLevel = EHeightLevel0;
    _score = 0;
    
    [self initRecorder];
    [self initRecorderLevelLabel];
    
    [self initPlayer];
    
    [self initFirstCoulmn];
    [self column];
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
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (_recorder) {
        [_recorder prepareToRecord];
        _recorder.meteringEnabled = YES;
        [_recorder record];
        _levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
    } else {
        NSLog(@"%@", [error description]);
    }
}

- (void)initRecorderLevelLabel {
//    UILabel *textLabel = [[UILabel alloc] init];
//    [textLabel setFrame:CGRectMake(200, 44, 200, 30)];
//    [textLabel setTextColor:[UIColor redColor]];
//    [textLabel setBackgroundColor:[UIColor lightGrayColor]];
//    [textLabel setFont:[UIFont systemFontOfSize:24]];
//    [textLabel setTextAlignment:NSTextAlignmentLeft];
//    [self.view addSubview:textLabel];
//    self.textLabel = textLabel;
    
    UILabel *levelTipLabel = [[UILabel alloc] init];
    [levelTipLabel setFrame:CGRectMake(10, 80, 60, 20)];
    [levelTipLabel setTextColor:[UIColor blackColor]];
    [levelTipLabel setText:@"分贝："];
    [levelTipLabel setBackgroundColor:[UIColor whiteColor]];
    [levelTipLabel setFont:[UIFont systemFontOfSize:18]];
    [levelTipLabel setTextAlignment:NSTextAlignmentRight];
    [self.view addSubview:levelTipLabel];
    
    UIView *levelView = [[UIView alloc] initWithFrame:CGRectMake(80, 80, 200, 20)];
    [levelView setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:levelView];
    self.levelView = levelView;
    
    UILabel *scoreTipLabel = [[UILabel alloc] init];
    [scoreTipLabel setFrame:CGRectMake(10, 44, 60, 30)];
    [scoreTipLabel setTextColor:[UIColor blackColor]];
    [scoreTipLabel setText:@"得分："];
    [scoreTipLabel setBackgroundColor:[UIColor whiteColor]];
    [scoreTipLabel setFont:[UIFont systemFontOfSize:18]];
    [scoreTipLabel setTextAlignment:NSTextAlignmentRight];
    [self.view addSubview:scoreTipLabel];
    
    UILabel *scoreLabel = [[UILabel alloc] init];
    [scoreLabel setFrame:CGRectMake(80, 44, 100, 30)];
    [scoreLabel setTextColor:[UIColor redColor]];
    [scoreLabel setText:@"0"];
    [scoreLabel setBackgroundColor:[UIColor whiteColor]];
    [scoreLabel setFont:[UIFont systemFontOfSize:24]];
    [scoreLabel setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:scoreLabel];
    self.scoreLabel = scoreLabel;
    
    UILabel *tipsLabel = [[UILabel alloc] init];
    [tipsLabel setFrame:CGRectMake(10, 10, 200, 20)];
    [tipsLabel setTextColor:[UIColor lightGrayColor]];
    [tipsLabel setBackgroundColor:[UIColor whiteColor]];
    [tipsLabel setFont:[UIFont systemFontOfSize:12]];
    [tipsLabel setTextAlignment:NSTextAlignmentLeft];
    [tipsLabel setText:@"发出声音使人物前进~"];
    [self.view addSubview:tipsLabel];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(MainWidth-44, 7, 30, 30)];
    [btn setBackgroundColor:[UIColor whiteColor]];
    [btn setTitle:@"X" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(stopGame) forControlEvents:UIControlEventTouchUpInside];
    [btn.layer setCornerRadius:15];
    [btn.layer setMasksToBounds:YES];
    [btn.layer setBorderWidth:1.0];
    [btn.layer setBorderColor:[UIColor blackColor].CGColor];
    [self.view addSubview:btn];
}

- (void)initPlayer {
    NSMutableArray *images=[[NSMutableArray alloc]init];
    for (NSInteger i=1; i<=8; i++) {
        NSString *name=[NSString stringWithFormat:@"perRun%ld",(long)i];
        UIImage *image=[UIImage imageNamed:name];
        [images addObject:image];
    }
    _playerView=[[UIImageView alloc]initWithFrame:CGRectMake(MainWidth/3, MainHeight-KBlackHeight-30, 39, 30)];
    [_playerView setImage:[UIImage imageNamed:@"perRun8"]];
    [_playerView setBackgroundColor:[UIColor clearColor]];
    _playerView.animationDuration=0.5;
    _playerView.animationImages=images;
    _playerView.animationRepeatCount=0;
    [_playerView startAnimating];
    [self.view addSubview:_playerView];
}

- (void)initFirstCoulmn {
    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, MainHeight-KBlackHeight, MainWidth, KBlackHeight)];
    [blackView setBackgroundColor:[UIColor blackColor]];
    blackView.tag = KBlackViewTag;
    [self.view addSubview:blackView];
}

- (void)column {
    NSInteger blackViewWidth=arc4random()%(KBlackMaxLength-KBlackMinLength)+KBlackMinLength;
    NSInteger whiteViewWidth=arc4random()%(KWhiteMaxLength-KWhiteMinLength)+KWhiteMinLength;
    
    UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(MainWidth+whiteViewWidth, MainHeight-KBlackHeight, blackViewWidth, KBlackHeight)];
    [blackView setBackgroundColor:[UIColor blackColor]];
    blackView.tag = KBlackViewTag;
    [self.view addSubview:blackView];
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
    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf.textLabel setText:[NSString stringWithFormat:@"%f", level*120]];
        [weakSelf dealWithLevel:level];
        [weakSelf refreshLevelView:level];
    });
}

- (void)refreshLevelView:(float)level {
    if (level < 0.0f) {
        level = 0.0f;
    } else if (level >= 1.0f) {
        level = 1.0f;
    }
    
    CGRect frame = self.levelView.frame;
    frame.size.width = 100*level;
    self.levelView.frame = frame;
}

- (void)dealWithLevel:(float)level {
    if (level < 0.0f) {
        level = 0.0f;
    } else if (level >= 1.0f) {
        level = 1.0f;
    }
    
    NSLog(@"分贝比例：%f", level);
    if (level > 0.2) {
        BOOL shouldNew = YES;
        for (UIView *blackView in self.view.subviews) {
            if (blackView.tag == KBlackViewTag) {
                CGRect rect = blackView.frame;
                rect.origin.x = rect.origin.x - 2;
                blackView.frame = rect;
                
                if (rect.origin.x + rect.size.width > MainWidth) {
                    shouldNew = NO;
                }
                
                if (rect.origin.x + rect.size.width < 0) {
                    [blackView removeFromSuperview];
                }
            }
        }
        if (shouldNew) {
            NSLog(@"新建");
            [self column];
        }
        [self addScore];
        [_playerView startAnimating];
    } else {
//        [_playerView stopAnimating];
        if (_playerStatus == EPlayerStatusWalk) {
            [_playerView stopAnimating];
        }
    }
    
    if (level > 0.4) {
        if (_playerStatus == EPlayerStatusWalk || _playerStatus == EPlayerStatusUp) {
            if (level > _maxLevel) {
                _maxLevel = level;
                _lastTime = KLastTime;
                _playerStatus = EPlayerStatusUp;

                if (level > 0.85) {
                    _heightLevel = EHeightLevel4;
                } else if (level > 0.7) {
                    _heightLevel = EHeightLevel3;
                } else if (level > 0.55) {
                    _heightLevel = EHeightLevel2;
                } else {
                    _heightLevel = EHeightLevel1;
                }
            } else {
                _lastTime = _lastTime - 1;
            }
        }
    }
    
    
    [self playAction];
}

- (void)playAction {
    if (_playerStatus == EPlayerStatusWalk) {
        NSLog(@"EPlayerStatusWalk");
        if ([self playerInBlack] == NO) {
            _playerStatus = EPlayerStatusDown;
        }
    } else if (_playerStatus == EPlayerStatusUp) {
        NSLog(@"EPlayerStatusUp");
        if (_jumpHeight < (_heightLevel*10)) {
            CGRect frame= self.playerView.frame;
            frame.origin.y-=KUpSpeed;
            _jumpHeight+=KUpSpeed;
            self.playerView.frame=frame;
        } else {
            _maxLevel = 0;
            _playerStatus = EPlayerStatusDown;
        }
    } else {
        NSLog(@"EPlayerStatusDown");
        if (_jumpHeight >= 0) {
            CGRect frame= self.playerView.frame;
            frame.origin.y+=KDownSpeed;
            _jumpHeight-=KDownSpeed;
            self.playerView.frame=frame;
        } else {
            if (_shouldStop) {
                BOOL mustStop = NO;
                for (UIView *blackView in self.view.subviews) {
                    if (blackView.tag == KBlackViewTag) {
                        BOOL ret1=CGRectIntersectsRect(self.playerView.frame, blackView.frame);
                        if (ret1) {
                            mustStop = YES;
                        }
                    }
                }
                if (self.playerView.frame.origin.y+self.playerView.frame.size.height > MainHeight) {
                    mustStop = YES;
                }
                if (mustStop) {
                    [self stopGame];
                } else {
                    CGRect frame= self.playerView.frame;
                    frame.origin.y+=KDownSpeed;
                    _jumpHeight-=KDownSpeed;
                    self.playerView.frame=frame;
                }
            } else {
                if ([self playerInBlack]) {
                    [self.playerView setFrame:CGRectMake(MainWidth/3, MainHeight-KBlackHeight-30, 39, 30)];
                    _jumpHeight = 0;
                    _playerStatus = EPlayerStatusWalk;
                } else {
                    CGRect frame= self.playerView.frame;
                    frame.origin.y+=KDownSpeed;
                    _jumpHeight-=KDownSpeed;
                    self.playerView.frame=frame;
                    _shouldStop = YES;
                }
            }
        }
    }
}

- (BOOL)playerInBlack {
    CGFloat playerX = self.playerView.frame.origin.x;
    CGFloat playerW = self.playerView.frame.size.width;
    
    BOOL inBlack = NO;
    for (UIView *blackView in self.view.subviews) {
        if (blackView.tag == KBlackViewTag) {
            CGFloat blackX = blackView.frame.origin.x;
            CGFloat blackW = blackView.frame.size.width;
            
            if ((playerX >= (blackX-playerW)) &&(playerX <= (blackX+blackW))) {
                inBlack = YES;
            }
        }
    }
    return inBlack;
}

- (void)stopGame {
    NSLog(@"stopGame");
    [self.levelTimer invalidate];
    self.levelTimer = nil;
    
    [_recorder stop];
    self.recorder = nil;
    
    for (UIView *blackView in self.view.subviews) {
        if (blackView.tag == KBlackViewTag) {
            [blackView removeFromSuperview];
        }
    }
    
    [self showScore];
}

- (void)addScore {
    self.score += 1;
    [self.scoreLabel setText:[NSString stringWithFormat:@"%ld", (long)(self.score/10)]];
}

- (void)showScore {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *topScore = [userDefaults objectForKey:@"topScope"];
    NSInteger topScoreInt = topScore.integerValue;
    if (_score > topScoreInt) {
        [userDefaults setObject:[NSString stringWithFormat:@"%ld", (long)_score] forKey:@"topScope"];
        [userDefaults synchronize];
    }
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MainWidth, MainHeight)];
    [bgView setBackgroundColor:[UIColor lightTextColor]];
    
    UIView *layerView = [[UIView alloc] initWithFrame:CGRectMake(100, 50, MainWidth - 200, MainHeight - 100)];
    [layerView setBackgroundColor:[UIColor lightGrayColor]];
    [layerView.layer setCornerRadius:10.0];
    [layerView.layer setMasksToBounds:YES];
    [layerView.layer setBorderWidth:2.0];
    [layerView.layer setBorderColor:[UIColor blackColor].CGColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake((MainWidth - 200)/2, 50 + (MainHeight - 100)/4*2, 200, 44)];
    [btn setBackgroundColor:[UIColor whiteColor]];
    [btn setTitle:@"再来一次" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(again) forControlEvents:UIControlEventTouchUpInside];
    [btn.layer setCornerRadius:10];
    [btn.layer setMasksToBounds:YES];
    [btn.layer setBorderWidth:1.0];
    [btn.layer setBorderColor:[UIColor blackColor].CGColor];
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn2 setFrame:CGRectMake((MainWidth - 200)/2, 50 + (MainHeight - 100)/4*3, 200, 44)];
    [btn2 setBackgroundColor:[UIColor whiteColor]];
    [btn2 setTitle:@"返回菜单" forState:UIControlStateNormal];
    [btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [btn2.layer setCornerRadius:10];
    [btn2.layer setMasksToBounds:YES];
    [btn2.layer setBorderWidth:1.0];
    [btn2.layer setBorderColor:[UIColor blackColor].CGColor];
    
    UILabel *topScoreTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(MainWidth/2-150-10, 50, 150, (MainHeight - 100)/4)];
    [topScoreTipLabel setText:@"历史最佳："];
    [topScoreTipLabel setFont:[UIFont systemFontOfSize:12]];
    [topScoreTipLabel setTextColor:[UIColor blackColor]];
    [topScoreTipLabel setTextAlignment:NSTextAlignmentRight];
    
    UILabel *scoreTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(MainWidth/2-150-10, 50 + (MainHeight - 100)/4, 150, (MainHeight - 100)/4)];
    [scoreTipLabel setText:@"本场得分："];
    [scoreTipLabel setFont:[UIFont systemFontOfSize:12]];
    [scoreTipLabel setTextColor:[UIColor blackColor]];
    [scoreTipLabel setTextAlignment:NSTextAlignmentRight];
    
    UILabel *topScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(MainWidth/2+10, 50, 150, (MainHeight - 100)/4)];
    [topScoreLabel setText:[NSString stringWithFormat:@"%ld", (long)(topScoreInt/10)]];
    [topScoreLabel setFont:[UIFont systemFontOfSize:24]];
    [topScoreLabel setTextColor:[UIColor redColor]];
    [topScoreLabel setTextAlignment:NSTextAlignmentLeft];
    
    UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(MainWidth/2+10, 50 + (MainHeight - 100)/4, 150, (MainHeight - 100)/4)];
    [scoreLabel setText:[NSString stringWithFormat:@"%ld", (long)(_score/10)]];
    [scoreLabel setFont:[UIFont systemFontOfSize:24]];
    [scoreLabel setTextColor:[UIColor redColor]];
    [scoreLabel setTextAlignment:NSTextAlignmentLeft];
    
    NSMutableArray *images=[[NSMutableArray alloc]init];
    for (NSInteger i=1; i<=8; i++) {
        NSString *name=[NSString stringWithFormat:@"perRun%ld",(long)i];
        UIImage *image=[UIImage imageNamed:name];
        [images addObject:image];
    }
    UIImageView *playerView=[[UIImageView alloc]initWithFrame:CGRectMake(100+50, 50+30, 78, 60)];
    [playerView setImage:[UIImage imageNamed:@"perRun8"]];
    [playerView setBackgroundColor:[UIColor clearColor]];
    playerView.animationDuration=0.5;
    playerView.animationImages=images;
    playerView.animationRepeatCount=0;
    [playerView startAnimating];
    
    [bgView addSubview:layerView];
    [bgView addSubview:btn];
    [bgView addSubview:btn2];
    [bgView addSubview:topScoreTipLabel];
    [bgView addSubview:scoreTipLabel];
    [bgView addSubview:topScoreLabel];
    [bgView addSubview:scoreLabel];
    [bgView addSubview:playerView];
    
    [bgView setTag:KAlertViewTag];
    [self.view addSubview:bgView];
}

- (void)again {
    for (UIView *subview in self.view.subviews) {
        if (subview.tag == KAlertViewTag) {
            [subview removeFromSuperview];
        }
    }
    
    [self refreshGame];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)refreshGame {
    for (UIView *blackView in self.view.subviews) {
        if (blackView.tag == KBlackViewTag) {
            [blackView removeFromSuperview];
        }
    }
    
    _maxLevel = 0.0;
    _playerStatus = EPlayerStatusWalk;
    _lastTime = KLastTime;
    _jumpHeight = 0;
    _heightLevel = EHeightLevel0;
    _shouldStop = NO;
    _score = 0;
    
    [self.playerView setFrame:CGRectMake(MainWidth/3, MainHeight-KBlackHeight-30, 39, 30)];
    
    [self initRecorder];
    [self initFirstCoulmn];
    [self column];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
