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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.cv2 = [[OpenCVWrapper alloc] init];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.imageView.image = [self.cv2 genEdgeImage:[UIImage imageNamed:@"mug.jpg"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
