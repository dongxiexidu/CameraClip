//
//  ViewController.m
//  身份证拍照截取
//
//  Created by fashion on 2018/10/26.
//  Copyright © 2018年 shangZhu. All rights reserved.
//

#import "ViewController.h"
#import "ZKIDCardCameraController.h"

@interface ViewController ()<ZKIDCardCameraControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)frontClick:(id)sender {
    ZKIDCardCameraController *controller = [[ZKIDCardCameraController alloc] initWithType:ZKIDCardTypeFront];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)reverseClick:(id)sender {
    ZKIDCardCameraController *controller = [[ZKIDCardCameraController alloc] initWithType:ZKIDCardTypeReverse];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)cameraDidFinishShootWithCameraImage:(nonnull UIImage *)image { 
    self.imageView.image = image;
}


@end
