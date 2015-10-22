//
//  ViewController.m
//  APCG_Proj
//
//  Created by Justin Bennett on 10/6/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import "ViewController.h"
#import "OpenCVWrapper.h"

@interface ViewController ()
@property (strong,nonatomic)OpenCVWrapper* cv2;

@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoDataOutput* vidDataOutput;
@property (strong, nonatomic) dispatch_queue_t vidDataOutputQueue;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* prevLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.cv2 = [[OpenCVWrapper alloc] init];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    self.imageView.image = [self.cv2 genEdgeImage:[UIImage imageNamed:@"mug.jpg"]];
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
    
    AVCaptureDevice* device;
    AVCaptureDevicePosition desiredPos = AVCaptureDevicePositionBack;
    
    // grab device
    for (AVCaptureDevice *dev in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] ) {
        if ([dev position] == desiredPos) {
            device = dev;
            break;
        }
    }
    
    if(device == nil){
        NSLog(@"Could not access camera, terminating");
        return;
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
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
    
    AVCaptureConnection *videoConnection = [_vidDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
    
    // set video connection orientation
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:orientation];
    }
    
    // show preview layer
    CALayer* root = self.view.layer;
    self.prevLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [_prevLayer setFrame:[root bounds]];
    
    // set orientation of prev layer
    [_prevLayer.connection setVideoOrientation:orientation];
    // aspect ration
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [root addSublayer:_prevLayer];
    
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.session stopRunning];
    self.vidDataOutput = nil;
    self.vidDataOutputQueue = nil;
    self.session = nil;
}
@end
