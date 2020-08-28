
#import "DbrManager.h"

@implementation DbrManager
{
    AVCaptureSession *m_videoCaptureSession;
    
    DynamsoftBarcodeReader *m_barcodeReader;
    
    SEL m_recognitionCallback;
    id m_recognitionReceiver;
    SEL m_verificationCallback;
    id m_verificationReceiver;
    AVCaptureDevice* inputDevice;
    int itrFocusFinish;
    BOOL firstFocusFinish;
}
@synthesize startRecognitionDate;
@synthesize isPauseFramesComing;
@synthesize isCurrentFrameDecodeFinished;
@synthesize cameraResolution;

-(void)MemberInitialize
{
    m_videoCaptureSession = nil;
    isPauseFramesComing = NO;
    isCurrentFrameDecodeFinished = YES;
    _barcodeFormat = EnumBarcodeFormatONED | EnumBarcodeFormatPDF417 | EnumBarcodeFormatQRCODE | EnumBarcodeFormatDATAMATRIX;
    _barcodeFormat2 = EnumBarcodeFormat2NULL;
    startRecognitionDate = nil;
    m_recognitionReceiver = nil;
    _startVidioStreamDate  = [NSDate date];
    _adjustingFocus = YES;
    itrFocusFinish = 0;
    firstFocusFinish = false;
}

-(id)initWithLicenseFromServer:(NSString*)serverURL LicenseKey:(NSString*)licenseKey
{
    self = [super init];
    if(self)
    {
        m_barcodeReader = [[DynamsoftBarcodeReader alloc] initWithLicenseFromServer:serverURL licenseKey:licenseKey verificationDelegate:self];
        [self MemberInitialize];
    }
    
    return self;
}

-(id)initWithLicense:(NSString *)license{
    self = [super init];
    
    if(self)
    {
        NSError __autoreleasing * _Nullable error;
        m_barcodeReader = [[DynamsoftBarcodeReader alloc] initWithLicense:license];
        //Best Coverage settings
        //[m_barcodeReader initRuntimeSettingsWithString:@"{\"ImageParameter\":{\"Name\":\"BestCoverage\",\"DeblurLevel\":9,\"ExpectedBarcodesCount\":512,\"ScaleDownThreshold\":100000,\"LocalizationModes\":[{\"Mode\":\"LM_CONNECTED_BLOCKS\"},{\"Mode\":\"LM_SCAN_DIRECTLY\"},{\"Mode\":\"LM_STATISTICS\"},{\"Mode\":\"LM_LINES\"},{\"Mode\":\"LM_STATISTICS_MARKS\"}],\"GrayscaleTransformationModes\":[{\"Mode\":\"GTM_ORIGINAL\"},{\"Mode\":\"GTM_INVERTED\"}]}}" conflictMode:EnumConflictModeOverwrite error:&error];
        //Best Speed settings
        //[m_barcodeReader initRuntimeSettingsWithString:@"{\"ImageParameter\":{\"Name\":\"BestSpeed\",\"DeblurLevel\":3,\"ExpectedBarcodesCount\":512,\"LocalizationModes\":[{\"Mode\":\"LM_SCAN_DIRECTLY\"}],\"TextFilterModes\":[{\"MinImageDimension\":262144,\"Mode\":\"TFM_GENERAL_CONTOUR\"}]}}" conflictMode:EnumConflictModeOverwrite error:&error];
        //balance settings
        [m_barcodeReader initRuntimeSettingsWithString:@"{\"ImageParameter\":{\"Name\":\"Balance\",\"DeblurLevel\":5,\"ExpectedBarcodesCount\":512,\"LocalizationModes\":[{\"Mode\":\"LM_CONNECTED_BLOCKS\"},{\"Mode\":\"LM_SCAN_DIRECTLY\"}]}}" conflictMode:EnumConflictModeOverwrite error:&error];
        
        iPublicRuntimeSettings* settings = [m_barcodeReader getRuntimeSettings:nil];
        settings.barcodeFormatIds = EnumBarcodeFormatONED | EnumBarcodeFormatPDF417 | EnumBarcodeFormatQRCODE | EnumBarcodeFormatDATAMATRIX;
        settings.barcodeFormatIds_2 = EnumBarcodeFormat2NULL;
        [m_barcodeReader updateRuntimeSettings:settings error:nil];
        
        [self MemberInitialize];
    }
    
    return self;
}

-(id)init{
    return [self initWithLicense:@""];
}

- (void)dealloc
{
    m_barcodeReader = nil;
    if(m_videoCaptureSession != nil)
    {
        if([m_videoCaptureSession isRunning])
        {
            [m_videoCaptureSession stopRunning];
        }
        m_videoCaptureSession = nil;
    }
    inputDevice = nil;
    m_recognitionReceiver = nil;
    m_recognitionCallback = nil;
    m_verificationReceiver = nil;
    m_verificationCallback = nil;
}

-(void)connectServerAfterInit:(NSString*)serverURL LicenseKey:(NSString*)licenseKey
{
    if(self)
    {
        m_barcodeReader = [[DynamsoftBarcodeReader alloc] initWithLicenseFromServer:serverURL licenseKey:licenseKey verificationDelegate:self];
    }
}

- (void)setBarcodeFormat:(long)barcodeFormat barcodeFormat2:(long)barcodeFormat2{
    _barcodeFormat = barcodeFormat;
    _barcodeFormat2 = barcodeFormat2;
    NSError __autoreleasing * _Nullable error;
    iPublicRuntimeSettings* settings = [m_barcodeReader getRuntimeSettings:nil];
    settings.barcodeFormatIds = barcodeFormat;
    settings.barcodeFormatIds_2 = barcodeFormat2;
    [m_barcodeReader updateRuntimeSettings:settings error:&error];
}

-(void)setVideoSession {
    inputDevice = [self getAvailableCamera];
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:inputDevice
                                          error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t queue;
    queue = dispatch_queue_create("dbrCameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    // Enable continuous autofocus
    if ([inputDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error = nil;
        if ([inputDevice lockForConfiguration:&error]) {
            inputDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [inputDevice unlockForConfiguration];
        }
    }
    // Enable AutoFocusRangeRestriction
    if([inputDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
       inputDevice.autoFocusRangeRestrictionSupported) {
        if([inputDevice lockForConfiguration:nil]) {
            inputDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
            [inputDevice unlockForConfiguration];
        }
    }
    [captureOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    if(captureInput == nil || captureOutput == nil)
    {
        return;
    }
    m_videoCaptureSession = [[AVCaptureSession alloc] init];
    [m_videoCaptureSession addInput:captureInput];
    [m_videoCaptureSession addOutput:captureOutput];
    if ([m_videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080])
    {
        [m_videoCaptureSession setSessionPreset :AVCaptureSessionPreset1920x1080];
        cameraResolution.width = 1920;
        cameraResolution.height = 1080;
    }
    else if ([m_videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
    {
        [m_videoCaptureSession setSessionPreset :AVCaptureSessionPreset1280x720];
        cameraResolution.width = 1280;
        cameraResolution.height = 720;
    }
    else if([m_videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
    {
        [m_videoCaptureSession setSessionPreset :AVCaptureSessionPreset640x480];
        cameraResolution.width = 640;
        cameraResolution.height = 480;
    }
}

-(void)startVideoSession
{
    if(!m_videoCaptureSession.isRunning)
    {
        [m_videoCaptureSession startRunning];
    }
}

-(AVCaptureSession*) getVideoSession {
    return m_videoCaptureSession;
}

-(void)setRecognitionCallback :(id)sender :(SEL)callback {
    m_recognitionReceiver = sender;
    m_recognitionCallback = callback;
}

-(void)setServerLicenseVerificationCallback: (id)sender :(SEL)callback {
    m_verificationReceiver = sender;
    m_verificationCallback = callback;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
{
    if(inputDevice == nil)
    {
        return;
    }
    if(inputDevice.isAdjustingFocus == false)
    {
        itrFocusFinish = itrFocusFinish + 1;
        if(itrFocusFinish == 1)
        {
            firstFocusFinish = true;
        }
    }
    if(!firstFocusFinish || isPauseFramesComing == YES || isCurrentFrameDecodeFinished == NO)
    {
        return;
    }
    isCurrentFrameDecodeFinished = NO;
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    int bufferSize = (int)CVPixelBufferGetDataSize(imageBuffer);
    int imgWidth = (int)CVPixelBufferGetWidth(imageBuffer);
    int imgHeight = (int)CVPixelBufferGetHeight(imageBuffer);
    size_t bpr = CVPixelBufferGetBytesPerRow(imageBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    NSData * buffer = [NSData dataWithBytes:baseAddress length:bufferSize];
    startRecognitionDate = [NSDate date];
    NSArray* results = [m_barcodeReader decodeBuffer:buffer withWidth:imgWidth height:imgHeight stride:bpr format:EnumImagePixelFormatARGB_8888 templateName:@"" error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self->m_recognitionReceiver performSelector:self->m_recognitionCallback withObject:results];
    });
}

-(AVCaptureDevice *)getAvailableCamera {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == AVCaptureDevicePositionBack) {
            captureDevice = device;
            break;
        }
    }
    
    if (!captureDevice)
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    return captureDevice;
}

#pragma mark - DBRServerLicenseVerificationDelegate
- (void)licenseVerificationCallback:(bool)isSuccess error:(NSError * _Nullable)error
{
    NSNumber* boolNumber = [NSNumber numberWithBool:isSuccess];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->m_verificationReceiver performSelector:self->m_verificationCallback withObject:boolNumber withObject:error];
    });
}

@end
