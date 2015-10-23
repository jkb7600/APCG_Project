//
//  OpenCVWrapper.h
//  APCG_Proj
//
//  Created by Justin Bennett on 10/13/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (instancetype)sharedInstance;

- (UIImage*)genEdgeImage:(UIImage*)inputImage;
- (CIImage*)genEdgeImageCI:(CIImage*)image;

@end
