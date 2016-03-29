//
//  SCScanViewController.m
//  GreenViewVilla
//
//  Created by Tousan on 15/12/26.
//  Copyright (c) 2015年 Tousan. All rights reserved.
//

#import "TOScanViewController.h"

@interface TOScanViewController ()

@end

@implementation TOScanViewController
{
    //UI
    UIButton *cancel_Btn;
    UIView *lastCover_View;
    UIImageView *scan_ImageView;
    UIImageView *line;
    
    //global data
    ScanResultHandle resultHandle;
}

#pragma mark - 初始化
- (id)initWithResultHandle:(ScanResultHandle)handle;
{
    self = [super init];
    if (self)
    {
        resultHandle = handle;
    }
    return self;
}

#pragma mark - 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    [super viewWillAppear:animated];
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus!=AVAuthorizationStatusAuthorized)
    {
        UIAlertView *camera_Alert = [[UIAlertView alloc]initWithTitle:@"请在设置里打开允许访问相机" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [camera_Alert show];
        return;
    }
    [self startReading];
}

#pragma mark - 初始化UI
- (void)setUI;
{
    cancel_Btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 44, 44)];
    [cancel_Btn setImage:TOANVIEWCONTROLLER_BACKBUTTON_ITEM forState:UIControlStateNormal];
    [cancel_Btn addTarget:self action:@selector(clickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancel_Btn];
}

- (UIStatusBarStyle)preferredStatusBarStyle;
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - 加载UI
- (void)loadUI;
{
    
}

#pragma mark
#pragma mark 交互响应方法
- (void)clickCancelBtn:(UIButton*)btn;
{
    [self stopReading];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)systemLightSwitch:(BOOL)open
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (open) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

- (BOOL)startReading;
{
    // 获取 AVCaptureDevice 实例
    NSError * error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 初始化输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    // 创建会话
    _captureSession = [[AVCaptureSession alloc] init];
    // 添加输入流
    [_captureSession addInput:input];
    // 初始化输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    // 添加输出流
    [_captureSession addOutput:captureMetadataOutput];
    
    // 创建dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("scanQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    // 设置元数据类型 AVMetadataObjectTypeQRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil]];
    
    // 创建输出对象
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    
    [self.view.layer addSublayer:_videoPreviewLayer];
    UIView *statusBg_View = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    statusBg_View.backgroundColor = [UIColor blackColor];
    [self.view addSubview:statusBg_View];
    
    if (!scan_ImageView)
    {
        scan_ImageView = [UIImageView new];
        [self.view addSubview:scan_ImageView];
        scan_ImageView.frame = CGRectMake(0, 0, 225*[UIScreen mainScreen].bounds.size.width/320, 225*[UIScreen mainScreen].bounds.size.width/320);
        scan_ImageView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
        scan_ImageView.image = TOANVIEWCONTROLLER_SCANFIELD_ITEM;
        scan_ImageView.clipsToBounds = YES;
    }
    
    if (!line)
    {
        line = [UIImageView new];
        [scan_ImageView addSubview:line];
        line.image = TOANVIEWCONTROLLER_SCANLINE_ITEM;
        line.frame = CGRectMake(0, -scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height, scan_ImageView.frame.size.width, scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height);
        [line layoutIfNeeded];
        timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(animateScanField) userInfo:nil repeats:YES];
    }
    
    if (lastCover_View==nil)
    {
        lastCover_View = nil;
        for (int i=0; i<4; i++)
        {
            UIView *cover_View = [UIView new];
            [self.view addSubview:cover_View];
            [cover_View mas_makeConstraints:^(MASConstraintMaker *make) {
                switch (i)
                {
                    case 0:
                    {
                        make.left.equalTo(self.view.mas_left);
                        make.top.equalTo(self.view.mas_top).offset(20);
                        make.right.equalTo(self.view.mas_right);
                        make.bottom.equalTo(scan_ImageView.mas_top);
                        break;
                    }
                    case 1:
                    {
                        make.left.equalTo(self.view.mas_left);
                        make.top.equalTo(lastCover_View.mas_bottom);
                        make.right.equalTo(scan_ImageView.mas_left);
                        make.bottom.equalTo(self.view.mas_bottom);
                        break;
                    }
                    case 2:
                    {
                        make.left.equalTo(lastCover_View.mas_right);
                        make.top.equalTo(scan_ImageView.mas_bottom);
                        make.right.equalTo(self.view.mas_right);
                        make.bottom.equalTo(self.view.mas_bottom);
                        break;
                    }
                    case 3:
                    {
                        make.left.equalTo(scan_ImageView.mas_right);
                        make.top.equalTo(scan_ImageView.mas_top);
                        make.right.equalTo(self.view.mas_right);
                        make.bottom.equalTo(lastCover_View.mas_top);
                        break;
                    }
                }
            }];
            cover_View.backgroundColor = [UIColor blackColor];
            cover_View.alpha = 0.5;
            lastCover_View = cover_View;
        }
    }
    
    if (cancel_Btn)
    {
        [self.view bringSubviewToFront:cancel_Btn];
    }
    
    // 开始会话
    [_captureSession startRunning];
    
    return YES;
}

- (void)stopReading
{
    // 停止会话
    [_captureSession stopRunning];
    [_videoPreviewLayer removeFromSuperlayer];
    _videoPreviewLayer = nil;
    _captureSession = nil;
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
}


#pragma mark 代理响应方法
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    [self stopReading];
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if (metadataObj) {
            result = metadataObj.stringValue;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultHandle(NO,nil,self);
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            resultHandle(YES,result,self);
        });
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    switch (buttonIndex)
    {
        case 0:
        {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
        case 1:
        {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
            break;
        }
    }
}

#pragma mark - 动画
- (void)animateScanField;
{
    [UIView animateWithDuration:2 animations:^{
        line.frame = CGRectMake(0, scan_ImageView.frame.size.height+scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height, scan_ImageView.frame.size.width, scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height);
    } completion:^(BOOL finished) {
        line.frame = CGRectMake(0, -scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height, scan_ImageView.frame.size.width, scan_ImageView.frame.size.width/TOANVIEWCONTROLLER_SCANLINE_ITEM.size.width*TOANVIEWCONTROLLER_SCANLINE_ITEM.size.height);
    }];
}

@end

