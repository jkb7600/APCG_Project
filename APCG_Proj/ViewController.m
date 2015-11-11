//
//  ViewController.m
//  APCG_Proj
//
//  Created by Justin Bennett on 10/6/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import "ViewController.h"
#import "OpenCVWrapper.h"
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface ViewController ()
@property (strong,nonatomic)OpenCVWrapper* cv2;

@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoDataOutput* vidDataOutput;
@property (strong, nonatomic) dispatch_queue_t vidDataOutputQueue;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* prevLayer;
@property (strong, nonatomic) GLKView* customPrevLayer;
@property (strong, nonatomic) AVCaptureDevice* device;
@end

@implementation ViewController{
    EAGLContext *_eaglContext;
    CIContext *_ciContext;
    
    CGRect _videoPreviewBounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.cv2 = [OpenCVWrapper sharedInstance];
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // Must be done after all the GLKViews are properly set up
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace:[NSNull null]}];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    self.imageView.image = [self.cv2 genEdgeImage:[UIImage imageNamed:@"mug.jpg"]];
    [self becomeFirstResponder];
    [self setupAVCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupAVCapture{
    NSError *error;
    
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetMedium];
    
//    AVCaptureDevice* device;
    AVCaptureDevicePosition desiredPos = AVCaptureDevicePositionBack;
    
    // grab device
    for (AVCaptureDevice *dev in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] ) {
        if ([dev position] == desiredPos) {
            self.device = dev;
            break;
        }
    }

    
    if(self.device == nil){
        NSLog(@"Could not access camera, terminating");
        return;
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    if (!input || error) {
        NSLog(@"Error w/ AVCaptureDeviceInput %@", [error description]);
    }
    
    // add input to session
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    // set videoDataOutput
    self.vidDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary* settings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey :
                                   @(kCVPixelFormatType_32BGRA)};
    self.vidDataOutput.videoSettings = settings;
    
    // discard late frames
    [_vidDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // create serial queue
    _vidDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue",DISPATCH_QUEUE_SERIAL);
    [_vidDataOutput setSampleBufferDelegate:self queue:_vidDataOutputQueue];
    
    // add output to session
    if ([self.session canAddOutput:_vidDataOutput]) {
        [self.session addOutput:_vidDataOutput];
    }
    
    // Enable after output is added?
//    if ([self.device isTorchModeSupported:AVCaptureTorchModeAuto]) {
//        [self.device lockForConfiguration:nil];
//        [self.device setTorchMode:AVCaptureTorchModeAuto];
//        NSLog(@"Emabling auto torch mode");
//        [self.device unlockForConfiguration];
//    }
    
    AVCaptureConnection *videoConnection = [_vidDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
    
    // set video connection orientation
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:orientation];
    }
    
    // Custom Preview Layer
    self.customPrevLayer = [[GLKView alloc] initWithFrame:self.view.bounds context:_eaglContext];
//    self.customPrevLayer = NO;
    
    // rotatate 90 to account for native video image
//    self.customPrevLayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.customPrevLayer.frame = self.view.bounds;
    [self.view addSubview:self.customPrevLayer];
    
    [self.customPrevLayer bindDrawable];
    
    _videoPreviewBounds = CGRectZero;
    _videoPreviewBounds.size.height = self.customPrevLayer.drawableHeight;
    _videoPreviewBounds.size.width = self.customPrevLayer.drawableWidth;
    
    
    
    // show preview layer -- TEMP. Will render custom soon
//    CALayer* root = self.view.layer;
//    self.prevLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
//    [_prevLayer setFrame:[root bounds]];
//    
//    // set orientation of prev layer
//    [_prevLayer.connection setVideoOrientation:orientation];
//    // aspect ration
//    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    
//    [root addSublayer:_prevLayer];
    
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.session stopRunning];
    self.vidDataOutput = nil;
    self.vidDataOutputQueue = nil;
    self.session = nil;
}

- (CIImage*)getCIImageFromPixelBufferRef:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef pb = CMSampleBufferGetImageBuffer(sampleBuffer);
    return [CIImage imageWithCVImageBuffer:pb];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    // update video dimensions
    CIImage *sourceImage = [self getCIImageFromPixelBufferRef:sampleBuffer];
    
    CGRect sourceExtent = [sourceImage extent];
    CGFloat sourceAspect = sourceExtent.size.width/sourceExtent.size.height;
    
    CGFloat previewAspect = _videoPreviewBounds.size.width/ _videoPreviewBounds.size.height;
    
    // maintain aspect ratio by clipping video image
    
    CGRect drawRect = sourceExtent;
    
    if (sourceAspect > previewAspect) {
        // use full height, center crop width
        drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect)/2.0;
        drawRect.size.width = drawRect.size.height * previewAspect;
        
    }else{
        // use full width, center crop height
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width /previewAspect)/2.0;
        drawRect.size.height = drawRect.size.width / previewAspect;
    }
    
    [_customPrevLayer bindDrawable];
    
    if (_eaglContext != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:_eaglContext];
    }
    
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // set blend mode to "Source over" so CI will use it
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    if(sourceImage){
        sourceImage = [self.cv2 genEdgeImageCI:sourceImage];
        [_ciContext drawImage:sourceImage inRect:_videoPreviewBounds fromRect:drawRect];
    }
    
    [_customPrevLayer display];
    
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    NSLog(@"Buffer dropped");
}

#pragma mark -shake detection
// TODO clean up
-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if (motion == UIEventSubtypeMotionShake) {
        NSLog(@"Shake detected");
//        [self.session stopRunning];
        NSError *error = nil;
        if ([self.device torchMode] == AVCaptureTorchModeOff) {
            // turn on
            NSLog(@"Attempting to turn on torch");
            if ([self.device isTorchModeSupported:AVCaptureTorchModeOn]) {
                    NSError *error = nil;

                [self.device lockForConfiguration:&error];
                if (error!= nil) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
                [self.device setTorchMode:AVCaptureTorchModeOn];
                [self.device unlockForConfiguration];
            }
        }else{
            // turn off
            NSLog(@"Attempting to turn off torch");
            if ([self.device isTorchModeSupported:AVCaptureTorchModeOff]) {
                [self.device lockForConfiguration:&error];
                if (error!= nil) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
                [self.device setTorchMode:AVCaptureTorchModeOff];
                [self.device unlockForConfiguration];
            }
        }
//        [self.session startRunning];
    }
}
- (BOOL)canBecomeFirstResponder{
    return YES;
}

@end
