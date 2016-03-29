//
//  SCScanViewController.h
//  GreenViewVilla
//
//  Created by Tousan on 15/12/26.
//  Copyright (c) 2015年 Tousan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
#import "TOScanViewControllerConfig.h"
#import "Masonry.h"
@class TOScanViewController;

typedef void (^ScanResultHandle)(BOOL isSuccess,id result,TOScanViewController *viewController);

@interface TOScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>
{
    NSTimer * timer;
}
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

- (id)initWithResultHandle:(ScanResultHandle)handle;
- (BOOL)startReading;

@end
