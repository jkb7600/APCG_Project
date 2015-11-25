//
//  OpenCVWrapper.m
//  APCG_Proj
//
//  Created by Justin Bennett on 10/13/15.
//  Copyright © 2015 jkb7600. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <QuartzCore/QuartzCore.h>
#include <ImageIO/ImageIO.h>

@implementation OpenCVWrapper{
}


+ (instancetype)sharedInstance{
    static OpenCVWrapper *instance= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [OpenCVWrapper new];
//        if (!face_cascade.load("lbpcascade_frontalface.xml")) {
//            NSLog(@"Error reading in");
//        }
    });
    return instance;
}

-(UIImage*)genEdgeImage:(UIImage*)inputImage{
    cv::Mat originalMat = [self cvMatFromUIImage:inputImage];
    
    cv::Mat grayMat;
    cv::cvtColor(originalMat, grayMat, CV_BGR2GRAY);
    
    cv::Mat output;
    cv::Canny(grayMat, output, 80, 120);
    
    return [self UIImageFromCVMat:output];
}

- (CIImage*)genEdgeImageCI:(CIImage*)image{
    
    CIContext* context = [CIContext contextWithCGContext:nil options:nil];
    
    CGImageRef imgRef = [context createCGImage:image fromRect:[image extent]];
    
    cv::Mat originalMat = [self cvMatFromCGImage:imgRef columns:[image extent].size.width rows:[image extent].size.height];
    CGImageRelease(imgRef);
    cv::Mat grayMat;
    cv::cvtColor(originalMat, grayMat, CV_BGR2GRAY);
    
    // face detection
    std::vector<cv::Rect> faces;
    cv::CascadeClassifier* faceCascade;
    
    // uncomment for loading classifier
//    faceCascade = [self loadClassifier];
//    faceCascade->detectMultiScale(grayMat, faces);
    
//    face_cascade->detectMultiScale( grayMat, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, Size(30, 30) );
//    faceCascade->detectMultiScale( frame_gray, faces, 1.1, 2, 0, Size(80, 80) );
    
    cv::Mat blur;
    cv::GaussianBlur(grayMat, blur, cv::Size(3,3), 3);
    
    
    cv::Mat output;
    cv::Canny(blur, output, 80, 120);
    
//    cv::Mat element;
//    element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3,3));
//    
//    cv::Mat dilate;
//    cv::dilate(output, dilate, element);
//    
//    element.release();
    
    cv::Mat multiplex;
    cv::add(output, grayMat, multiplex);
    
    // cvt back to color
//    cv::cvtColor(multiplex, multiplex, cv::COLOR_GRAY2BGRA);
////
////    // Face detection built in
//    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
//    
//    NSArray* features = [detector featuresInImage:image options:@{CIDetectorSmile: @NO, CIDetectorImageOrientation:[NSNumber numberWithInt:4]}];
//    
//    for(CIFaceFeature* f in features){
//        cv::Point center = cv::Point(f.bounds.origin.x+(f.bounds.size.width/2),f.bounds.origin.y+(f.bounds.size.height/2));
//        cv::circle(multiplex, center, f.bounds.size.width/2, cv::Scalar(255,0,0));
//    }
//    
    
    CGImageRef out1 = [self CGImageRefFromMat:multiplex];
    CIImage *outputImg = [CIImage imageWithCGImage:out1 options:nil];
    originalMat.release();
    grayMat.release();
    blur.release();
    output.release();
    multiplex.release();
    //colorOut.release();
    CGImageRelease(out1);
    return outputImg;
}

- (cv::CascadeClassifier*)loadClassifier{
    NSString* haar = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    cv::CascadeClassifier* cascade = new cv::CascadeClassifier();
    cascade->load([haar UTF8String]);
    return cascade;
}

/*
 Get cvMatrix from CGImage
 */
- (cv::Mat)cvMatFromCGImage:(CGImageRef)image columns:(CGFloat)columns rows:(CGFloat)rows {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);

    
    cv::Mat cvMat(rows, columns, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,     // Pointer to data
                                                    columns,        // Width of bitmap
                                                    rows,           // Height of bitmap
                                                    8,              // Bits per component
                                                    cvMat.step[0],  // Bytes per row
                                                    colorSpace,     // Color space
                                                    kCGImageAlphaNoneSkipLast
                                                    | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, columns, rows), image);
    CGContextRelease(contextRef);
    return cvMat;
}

- (CGImageRef)CGImageRefFromMat:(cv::Mat)cvMat{
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
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    
    return imageRef;

}

/*
 Get the cvMatrix from a UIImage
 */
-(cv::Mat)cvMatFromUIImage:(UIImage*)image{
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    return [self cvMatFromCGImage:image.CGImage columns:cols rows:rows];
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat{
    CGImageRef imageRef = [self CGImageRefFromMat:cvMat];
    
    // get uiimage from cgimage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return finalImage;
}
@end
