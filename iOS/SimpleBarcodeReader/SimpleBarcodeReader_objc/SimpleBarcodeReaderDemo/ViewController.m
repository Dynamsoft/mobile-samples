
#import "ViewController.h"
#import "BarcodeTypesTableViewController.h"
#import "DbrManager.h"
#import <DynamsoftBarcodeReader/DynamsoftBarcodeSDK.h>
//you can init DynamsoftBarcodeReader with a license or licenseKey
static NSString * const kLicense    = @"Put your license here";
static NSString * const kLicensekey = @"Put your license key here";

@interface ViewController ()

@end

@implementation ViewController
{
    BOOL m_isFlashOn;
}

@synthesize cameraPreview;
@synthesize previewLayer;
@synthesize rectLayerImage;
@synthesize dbrManager;
@synthesize flashButton;
@synthesize detectDescLabel;

- (void)viewDidLoad {
    [super viewDidLoad];

    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    //register notification for UIApplicationDidBecomeActiveNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    //init DbrManager with Dynamsoft Barcode Reader mobile license
    bool isInitWithLicenseKey = NO;//Choose an initialization method
    if(!isInitWithLicenseKey)
    {
        dbrManager = [[DbrManager alloc] initWithLicense:kLicense];
    }
    else
    {
        dbrManager = [[DbrManager alloc] initWithLicenseFromServer:@"" LicenseKey:kLicensekey];
        [dbrManager setServerLicenseVerificationCallback:self :@selector(onVerificationCallBack:error:)];
    }
    
    [dbrManager setRecognitionCallback:self :@selector(onReadImageBufferComplete:)];
    
    [dbrManager setVideoSession];
    
    if(!isInitWithLicenseKey)
    {
        [dbrManager startVideoSession];
    }
    
    [self configInterface];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(dbrManager != nil)
    {
        dbrManager = nil;
    }
}

- (void)didBecomeActive:(NSNotification *)notification;
{
    if(dbrManager.isPauseFramesComing == NO)
        [self turnFlashOn:m_isFlashOn];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dbrManager.isPauseFramesComing = NO;
    [self turnFlashOn:m_isFlashOn];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) turnFlashOn: (BOOL) on {
    // validate whether flashlight is available
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device != nil && [device hasTorch]){
        [device lockForConfiguration:nil];
        
        if (on == YES) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [flashButton setImage:[UIImage imageNamed:@"flash_on"] forState:UIControlStateNormal];
            [flashButton setTitle:@" Flash on" forState:UIControlStateNormal];
            
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [flashButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
            [flashButton setTitle:@" Flash off" forState:UIControlStateNormal];
        }
        
        [device unlockForConfiguration];
    }
}

- (IBAction)onFlashButtonClick:(id)sender {
    
    m_isFlashOn = m_isFlashOn == YES ? NO : YES;
    [self turnFlashOn:m_isFlashOn];
}

- (void) customizeAC : (UIAlertController *) ac
{
    if(ac == nil) return;
    
    UIView *subView1 = ac.view.subviews[0];
    UIView *subView2 = subView1.subviews[0];
    UIView *subView3 = subView2.subviews[0];
    UIView *subView4 = subView3.subviews[0];
    UIView *subView5 = subView4.subviews[0];
    
    for (int i = 0; i < subView5.subviews.count; i++) {
        if([subView5.subviews[i] isKindOfClass: [UILabel class]])
        {
            UILabel *alertLabel = (UILabel*)subView5.subviews[i];
            alertLabel.textAlignment = NSTextAlignmentLeft;
        }
    }
}

- (IBAction)onAboutInfoClick:(id)sender {
    dbrManager.isPauseFramesComing = YES;
    
    UIAlertController * ac=   [UIAlertController
                               alertControllerWithTitle:@"About"
                               message:@"\nDynamsoft Barcode Reader Mobile App Demo(Dynamsoft Barcode Reader SDK)\n\n© 2020 Dynamsoft. All rights reserved. \n\nIntegrate Barcode Reader Functionality into Your own Mobile App? \n\nClick 'Overview' button for further info.\n\n"
                               preferredStyle:UIAlertControllerStyleAlert];
    
    [self customizeAC:ac];
    
    UIAlertAction* linkAction = [UIAlertAction actionWithTitle:@"Overview" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                 {
                                     NSString *urlString = @"http://www.dynamsoft.com/Products/barcode-scanner-sdk-iOS.aspx";
                                     NSURL *url = [NSURL URLWithString:urlString];
                                     if ([[UIApplication sharedApplication] canOpenURL:url])
                                     {
                                         [[UIApplication sharedApplication] openURL:url];
                                     }
                                     self->dbrManager.isPauseFramesComing = NO;
                                 }];
    [ac addAction:linkAction];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"OK"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    self->dbrManager.isPauseFramesComing = NO;
                                }];
    
    [ac addAction:yesButton];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showBarcodeTypes"]) {
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        
        [[self navigationItem] setBackBarButtonItem:newBackButton];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        BarcodeTypesTableViewController *destViewController = segue.destinationViewController;
        if(destViewController != nil)
            destViewController.mainView = self;
        [self turnFlashOn:NO];
        dbrManager.isPauseFramesComing = YES;
    }
}

-(void) onVerificationCallBack:(NSNumber *) isSuccess error:(NSError *) error{
    if ([isSuccess boolValue])
    {
        [dbrManager startVideoSession];
    }
    else
    {
        NSString* msg = @"";
        if(error != nil)
        {
            msg =  error.userInfo[NSLocalizedDescriptionKey];
            if(msg == nil)
            {
                msg =  [error localizedDescription];
            }
        }
        UIAlertController* ac = [UIAlertController
                                alertControllerWithTitle:@"Server license verify failed"
                                message: msg
                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Try again"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [self->dbrManager connectServerAfterInit:@"" LicenseKey:kLicensekey];
                                   }];
        [ac addAction:okButton];
        UIAlertAction* cancelButton = [UIAlertAction
                                       actionWithTitle:@"Cancel with local License"
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction * action)
                                       {
                                           [self->dbrManager startVideoSession];
                                       }];
        [ac addAction:cancelButton];
        [self presentViewController:ac animated:NO completion:nil];
    }
}

-(void) onReadImageBufferComplete:(NSArray *) readResult{
    
    if(readResult == nil || dbrManager.isPauseFramesComing == YES)
    {
        dbrManager.isCurrentFrameDecodeFinished = YES;
        return;
    }
    
    double timeInterval = [dbrManager.startRecognitionDate timeIntervalSinceNow] * -1;
    NSString* msgText =@"";
    if (readResult.count == 0) {
        dbrManager.isCurrentFrameDecodeFinished = YES;
        return;
    } else {
        for (NSInteger i=0; i<[readResult count]; i++) {
            if (((iTextResult*)readResult[i]).barcodeFormat_2 != 0) {
                msgText = [msgText stringByAppendingString:[NSString stringWithFormat:@"\nType: %@\nValue: %@\n", ((iTextResult*)readResult[i]).barcodeFormatString_2, ((iTextResult*)readResult[i]).barcodeText]];
            }else{
                msgText = [msgText stringByAppendingString:[NSString stringWithFormat:@"\nType: %@\nValue: %@\n", ((iTextResult*)readResult[i]).barcodeFormatString, ((iTextResult*)readResult[i]).barcodeText]];
            }
        }
        UIAlertController* ac= [UIAlertController
                                alertControllerWithTitle:@"Result"
                                message:[msgText stringByAppendingString:[NSString stringWithFormat:@"\nInterval: %.03f seconds\n",timeInterval]]
                                preferredStyle:UIAlertControllerStyleAlert];
        
        [self customizeAC:ac];
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       self->dbrManager.isCurrentFrameDecodeFinished = YES;
                                       self->dbrManager.startVidioStreamDate = [NSDate date];
                                   }];
        
        [ac addAction:okButton];
        [self presentViewController:ac animated:NO completion:nil];
        
    }
}

- (void) configInterface{
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    CGFloat w = [[UIScreen mainScreen] bounds].size.width;
    CGFloat h = [[UIScreen mainScreen] bounds].size.height;
    CGRect mainScreenLandscapeBoundary = CGRectZero;
    mainScreenLandscapeBoundary.size.width = MIN(w, h);
    mainScreenLandscapeBoundary.size.height = MAX(w, h);
    
    rectLayerImage.frame = mainScreenLandscapeBoundary;
    rectLayerImage.contentMode = UIViewContentModeTopLeft;
    
    [self createRectBorderAndAlignControls];
    
    //init vars and controls
    m_isFlashOn = NO;
    flashButton.layer.zPosition = 1;
    detectDescLabel.layer.zPosition = 1;
    [flashButton setTitle:@" Flash off" forState:UIControlStateNormal];
    
    //show vedio capture
    AVCaptureSession* captureSession = [dbrManager getVideoSession];
    if(captureSession == nil)
        return;
    
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    previewLayer.frame = mainScreenLandscapeBoundary;
    cameraPreview = [[UIView alloc] init];
    [cameraPreview.layer addSublayer:previewLayer];
    [self.view insertSubview:cameraPreview atIndex:0];
}

- (void)createRectBorderAndAlignControls {
    int width = rectLayerImage.bounds.size.width;
    int height = rectLayerImage.bounds.size.height;
    
    int widthMargin = width * 0.1;
    int heightMargin = (height - width + 2 * widthMargin) / 2;
    
    UIGraphicsBeginImageContext(self.rectLayerImage.bounds.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    //1. draw gray rect
    [[UIColor blackColor] setFill];
    CGContextFillRect(ctx, (CGRect){{0,      0}, {widthMargin, height}});
    CGContextFillRect(ctx, (CGRect){{0,      0}, {width, heightMargin}});
    CGContextFillRect(ctx, (CGRect){{width - widthMargin, 0}, {widthMargin, height}});
    CGContextFillRect(ctx, (CGRect){{0, height - heightMargin}, {width, heightMargin}});
    
    //2. draw red line
    CGPoint points[2];
    
    //3. draw white rect
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 1.0);
    // draw left side
    points[0]=(CGPoint){widthMargin,heightMargin}; points[1]=(CGPoint){widthMargin,height - heightMargin};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw right side
    points[0]=(CGPoint){width - widthMargin,heightMargin}; points[1]=(CGPoint){width - widthMargin,height - heightMargin};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw top side
    points[0]=(CGPoint){widthMargin,heightMargin}; points[1]=(CGPoint){width - widthMargin,heightMargin};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw bottom side
    points[0]=(CGPoint){widthMargin,height - heightMargin}; points[1]=(CGPoint){width - widthMargin,height - heightMargin};
    CGContextStrokeLineSegments(ctx, points, 2);
    
    //4. draw orange corners
    [[UIColor orangeColor] setStroke];
    CGContextSetLineWidth(ctx, 2.0);
    // draw left up corner
    points[0]=(CGPoint){widthMargin - 2,heightMargin - 2}; points[1]=(CGPoint){widthMargin + 18,heightMargin - 2};
    CGContextStrokeLineSegments(ctx, points, 2);
    points[0]=(CGPoint){widthMargin - 2,heightMargin - 2}; points[1]=(CGPoint){widthMargin - 2,heightMargin + 18};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw left bottom corner
    points[0]=(CGPoint){widthMargin - 2,height - heightMargin + 2}; points[1]=(CGPoint){widthMargin + 18,height - heightMargin + 2};
    CGContextStrokeLineSegments(ctx, points, 2);
    points[0]=(CGPoint){widthMargin - 2,height - heightMargin + 2}; points[1]=(CGPoint){widthMargin - 2,height - heightMargin - 18};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw right up corner
    points[0]=(CGPoint){width - widthMargin + 2,heightMargin - 2}; points[1]=(CGPoint){width - widthMargin - 18,heightMargin - 2};
    CGContextStrokeLineSegments(ctx, points, 2);
    points[0]=(CGPoint){width - widthMargin + 2,heightMargin - 2}; points[1]=(CGPoint){width - widthMargin + 2,heightMargin + 18};
    CGContextStrokeLineSegments(ctx, points, 2);
    // draw right bottom corner
    points[0]=(CGPoint){width - widthMargin + 2,height - heightMargin + 2}; points[1]=(CGPoint){width - widthMargin - 18,height - heightMargin + 2};
    CGContextStrokeLineSegments(ctx, points, 2);
    points[0]=(CGPoint){width - widthMargin + 2,height - heightMargin + 2}; points[1]=(CGPoint){width - widthMargin + 2,height - heightMargin - 18};
    CGContextStrokeLineSegments(ctx, points, 2);
    
    //5. set image
    rectLayerImage.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //6. align detectDescLabel horizontal center
    CGRect tempFrame = detectDescLabel.frame;
    tempFrame.origin.x = (width - detectDescLabel.bounds.size.width) / 2;
    tempFrame.origin.y = heightMargin * 0.6;
    [detectDescLabel setFrame:tempFrame];
    
    //7. align flashButton horizontal center
    tempFrame = flashButton.frame;
    tempFrame.origin.x = (width - flashButton.bounds.size.width) / 2;
    tempFrame.origin.y = (heightMargin + (width - widthMargin * 2) + height) * 0.5 - flashButton.bounds.size.height * 0.5;
    [flashButton setFrame:tempFrame];
    
    return;
}

@end
