//
//  ViewController.h
//  APCG_Proj
//
//  Created by Justin Bennett on 10/6/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@end

