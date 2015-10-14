//
//  OpenCVWrapper.m
//  APCG_Proj
//
//  Created by Justin Bennett on 10/13/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>

@implementation OpenCVWrapper

-(UIImage*)genEdgeImage:(UIImage*)inputImage{
    cv::Mat originalMat = [self cvMatFromUIImage:inputImage];
    
    cv::Mat grayMat;
    cv::cvtColor(originalMat, grayMat, CV_BGR2GRAY);
    
    cv::Mat output;
    cv::Canny(grayMat, output, 80, 120);
    
    return [self UIImageFromCVMat:output];
}

/*
 Get the cvMatrix from an image
 */
-(cv::Mat)cvMatFromUIImage:(UIImage*)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,     // Pointer to data
                                                    cols,           // Width of bitmap
                                                    rows,           // Height of bitmap
                                                    8,              // Bits per component
                                                    cvMat.step[0],  // Bytes per row
                                                    colorSpace,     // Color space
                                                    kCGImageAlphaNoneSkipLast
                                                    | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    
    CGColorSpaceRef colorspace;
    
    if (cvMat.elemSize() == 1) {
        colorspace = CGColorSpaceCreateDeviceGray();
    }else{
        colorspace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Create CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorspace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    
    // get uiimage from cgimage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    return finalImage;
}
@end
