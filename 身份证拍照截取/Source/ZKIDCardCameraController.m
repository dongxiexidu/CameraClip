//
//  ZKIDCardCameraController.m
//  FBSnapshotTestCase
//
//  Created by zhangkai on 2018/9/21.
//

#import "ZKIDCardCameraController.h"
#import <AVFoundation/AVFoundation.h>

#import "ZKIDCardFloatingView.h"

@interface ZKIDCardCameraController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;

/*!
 *    @brief    AVCaptureDeviceInput: 输入设备, 使用AVCaptureDevice初始化
 */
@property (nonatomic, strong) AVCaptureDeviceInput *input;

/*!
 *    @brief    捕捉摄像头输出
 */
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

/*!
 *    @brief    启动捕获摄像头
 */
@property (nonatomic, strong) AVCaptureSession *session;

/*!
 *    @brief    实时捕获图像层，图片预览
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UIButton *flashButton;

/*!
 *    @brief    拍摄成功后回显到屏幕
 */
@property (nonatomic, strong) UIImageView *imageView;

/*!
 *    @brief    拍的图片数据
 */
@property (nonatomic, strong) UIImage *image;

/*!
 *    @brief    是否有相机权限
 */
@property (nonatomic, assign) BOOL canUseCamera;

/*!
 *    @brief    取消拍摄
 */
@property (nonatomic, strong) UIButton *cancleButton;

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, assign, getter=isFlashOn) BOOL flashOn;
@property (nonatomic, strong) NSBundle *resouceBundle;

@property (nonatomic, assign) ZKIDCardType type;

@property (strong, nonatomic) ZKIDCardFloatingView *floatingView;

@end

@implementation ZKIDCardCameraController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithType:(ZKIDCardType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.type = type;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self isCanUseCamera]) {
        [self camera];
        
        CGFloat buttonWH = 60;
        CGFloat buttonX = (kScreenW-60)/2;
        CGFloat buttonY = (kScreenH-60-40);
        self.photoButton.frame = CGRectMake(buttonX, buttonY, buttonWH, buttonWH);
        
        CGFloat cancleButtonWH = 45;
        CGFloat cancleButtonX = 32;
        CGFloat cancleButtonY = (kScreenH-cancleButtonWH-40);
        self.cancleButton.frame = CGRectMake(cancleButtonX, cancleButtonY, cancleButtonWH, cancleButtonWH);
        
        CGFloat bottomY = (kScreenH-64);
        self.bottomView.frame = CGRectMake(0, bottomY, kScreenW, 64);
        
        
        UIButton *again = [UIButton buttonWithType:UIButtonTypeCustom];
        [again setTitle:@"重拍" forState:UIControlStateNormal];
        [again setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [again addTarget:self action:@selector(takePhotoAgain) forControlEvents:UIControlEventTouchUpInside];
        again.titleLabel.font = [UIFont systemFontOfSize:18];
        again.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.bottomView addSubview:again];
        
        CGFloat againWH = 64;
        CGFloat againX = 12;
        CGFloat againY = 0;
        again.frame = CGRectMake(againX, againY, againWH, againWH);
        
        UIButton *use = [UIButton buttonWithType:UIButtonTypeCustom];
        [use setTitle:@"使用照片" forState:UIControlStateNormal];
        [use setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [use addTarget:self action:@selector(usePhoto) forControlEvents:UIControlEventTouchUpInside];
        use.titleLabel.font = [UIFont systemFontOfSize:18];
        use.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.bottomView addSubview:use];
        
        CGFloat useH = 64;
        CGFloat useX = kScreenW-100;
        use.frame = CGRectMake(useX, 0, 100, useH);
        
        
        CGFloat flashWH = 45;
        CGFloat flashX = kScreenW-flashWH-32;
        CGFloat flashY = (kScreenH-flashWH-40);
        self.flashButton.frame = CGRectMake(flashX, flashY, flashWH, flashWH);
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
        [self.view addGestureRecognizer:tapGesture];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.device];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGPoint point = CGPointMake(CGRectGetWidth(bounds)/2.f, CGRectGetHeight(bounds)/2.f);
    [self focusAtPoint:point];
}

#pragma mark - events Handler
#pragma mark - 重新拍照
- (void)takePhotoAgain {
    [self.session startRunning];
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    self.cancleButton.hidden = NO;
    self.flashButton.hidden = NO;
    
    self.bottomView.hidden = YES;
    self.photoButton.hidden = NO;
    
}
#pragma mark - 取消拍照
- (void)cancleButtonAction {
    [self.imageView removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 使用图片
- (void)usePhoto {
    if ([self.delegate respondsToSelector:@selector(cameraDidFinishShootWithCameraImage:)]) {
        CGImageRef ref = self.image.CGImage;
        UIImage *newImg = [UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationUp];
        [self.delegate cameraDidFinishShootWithCameraImage:newImg];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -对图片进行裁剪
-(UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect{
    UIImage *image1 = image;
    CGImageRef cgRef = image1.CGImage;
    
    CGFloat widthScale = image1.size.width / kScreenW;
    CGFloat heightScale = image1.size.height / kScreenH;
    
    //其实是横屏的
    //多减掉50是因为最后的效果图片的高度有偏差，不知道原因
    NSLog(@"%@",NSStringFromCGRect(self.floatingView.IDCardWindowLayer.frame));
    //    CGFloat orignWidth = 226-50;//226 -50
    //    CGFloat orginHeight = 360;//360
    CGFloat orignWidth = self.floatingView.IDCardWindowLayer.bounds.size.width;
    CGFloat orginHeight = self.floatingView.IDCardWindowLayer.bounds.size.height;
    
    //我们要裁剪出实际边框内的图片，但是实际的图片和我们看见的屏幕上的img，size是不一样，可以打印一下image的size看看起码好几千的像素，要不然手机拍的照片怎么都是好几兆的呢？
    CGFloat x = (kScreenH - orginHeight) * 0.5 * heightScale;
    CGFloat y = (kScreenW - orignWidth) * 0.5 * widthScale;
    CGFloat width = orginHeight * heightScale;
    CGFloat height = orignWidth * widthScale;
    
    CGRect r = CGRectMake(x, y, width, height);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(cgRef, r);
    
    // UIImage *thumbScale = [UIImage imageWithCGImage:imageRef];
    UIImage *thumbScale = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];
    return thumbScale;
}


//// 提前设置得到图片方向
//#pragma mark -修改图片方向
//-(UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation{
//
//    long double rotate =0.0;
//    CGRect rect;
//    float translateX =0;
//    float translateY =0;
//    float scaleX =1.0;
//    float scaleY =1.0;
//    switch (orientation) {
//        case UIImageOrientationLeft:
//            rotate = M_PI_2;
//            rect = CGRectMake(0,0, image.size.height, image.size.width);
//            translateX = 0;
//            translateY = -rect.size.width;
//            scaleY = rect.size.width/rect.size.height;
//            scaleX = rect.size.height/rect.size.width;
//            break;
//        case UIImageOrientationRight:
//            rotate = 3*M_PI_2;
//            rect = CGRectMake(0,0, image.size.height, image.size.width);
//            translateX = -rect.size.height;
//            translateY = 0;
//            scaleY = rect.size.width/rect.size.height;
//            scaleX = rect.size.height/rect.size.width;
//            break;
//        case UIImageOrientationDown:
//            rotate = M_PI;
//            rect = CGRectMake(0,0, image.size.width, image.size.height);
//            translateX = -rect.size.width;
//            translateY = -rect.size.height;
//            break;
//        default:
//            rotate = 0.0;
//
//            rect = CGRectMake(0,0, image.size.width, image.size.height);
//            translateX = 0;
//            translateY = 0;
//            break;
//    }
//
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context =UIGraphicsGetCurrentContext();
//
//
//    //做CTM变换
//    CGContextTranslateCTM(context,0.0, rect.size.height);
//    CGContextScaleCTM(context,1.0, -1.0);
//    CGContextRotateCTM(context, rotate);
//    CGContextTranslateCTM(context, translateX, translateY);
//    CGContextScaleCTM(context, scaleX, scaleY);
//
//    CGContextDrawImage(context,CGRectMake(0,0, rect.size.width, rect.size.height), image.CGImage);
//    UIImage *newPic =UIGraphicsGetImageFromCurrentImageContext();
//    return newPic;
//}

#pragma mark - 拍照
- (void)shutterCamera:(UIButton *)sender {
    AVCaptureConnection * videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"拍照失败!");
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        if (imageDataSampleBuffer == NULL) return;
        
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *img = [UIImage imageWithData:imageData];
        UIImage *clipImage = [self imageFromImage:img inRect:strongSelf.floatingView.IDCardWindowLayer.frame];
        strongSelf.image = clipImage;
        [strongSelf.session stopRunning]; // 停止会话
        
        strongSelf.imageView = [[UIImageView alloc] initWithFrame:strongSelf.floatingView.IDCardWindowLayer.frame];
        
        [strongSelf.view insertSubview:self.imageView belowSubview:sender];
        strongSelf.imageView.layer.masksToBounds = YES;
        
        strongSelf.imageView.image = clipImage;
        
        // 隐藏切换取消闪光灯按钮
        strongSelf.cancleButton.hidden = YES;
        strongSelf.flashButton.hidden = YES;
        strongSelf.photoButton.hidden = YES;
        strongSelf.bottomView.hidden = NO;
    }];
}
#pragma mark:闪光灯
- (void)flashOn:(UIButton *)sender {
    if ([self.device hasTorch]){ // 判断是否有闪光灯
        [self.device lockForConfiguration:nil];// 请求独占访问硬件设备
        
        if (!self.isFlashOn) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
            self.flashOn = YES;
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
            self.flashOn = NO;
        }
        [self.device unlockForConfiguration];// 请求解除独占访问硬件设备
    }else {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                 message:@"您的设备没有闪光设备，不能提供手电筒功能，请检查"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}

#pragma mark - Private Methods

- (BOOL)isCanUseCamera {
    if (!_canUseCamera) {
        _canUseCamera = [self validateCanUseCamera];
    }
    return _canUseCamera;
}

- (BOOL)validateCanUseCamera {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请打开相机权限" message:@"请到设置中去允许应用访问您的相机: 设置-隐私-相机" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"不需要" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 跳转至设置开启权限
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if([[UIApplication sharedApplication] canOpenURL:url])
            {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:alertController animated:NO completion:nil];
        return NO;
    } else {
        return YES;
    }
}

- (void)focusAtPoint:(CGPoint)point {
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
    }
}

- (void)camera {
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; // 使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil]; // 使用设备初始化输入
    
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    self.session = [[AVCaptureSession alloc] init]; // 生成会话，用来结合输入输出
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    if ([self.session canAddInput:self.input]) {
        [[self session] addInput:self.input];
    }
    
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
    
    // 使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size};
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.session startRunning]; // 开始启动
    if ([_device lockForConfiguration:nil]) {
        if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_device setFlashMode:AVCaptureFlashModeAuto];
        }
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {// 自动白平衡
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_device unlockForConfiguration];
    }
    
    ZKIDCardFloatingView *IDCardFloatingView = [[ZKIDCardFloatingView alloc] initWithType:self.type];
    [self.view addSubview:IDCardFloatingView];
    IDCardFloatingView.frame = self.view.bounds;
    self.floatingView = IDCardFloatingView;

}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    //先进行判断是否支持控制对焦
    if (self.device.isFocusPointOfInterestSupported
        &&[self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error =nil;
        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [self.device lockForConfiguration:&error];
        [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        
        CGRect bounds = [UIScreen mainScreen].bounds;
        CGPoint point = CGPointMake(CGRectGetWidth(bounds)/2.f, CGRectGetHeight(bounds)/2.f);
        [self focusAtPoint:point];
        //操作完成后，记得进行unlock。
        [self.device unlockForConfiguration];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - getters and setters

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_photoButton setImage:[UIImage imageWithContentsOfFile:[self.resouceBundle pathForResource:@"photo@2x" ofType:@"png"]]
                      forState: UIControlStateNormal];
        [_photoButton setImage:[UIImage imageWithContentsOfFile:[self.resouceBundle pathForResource:@"photoSelect@2x" ofType:@"png"]]
                      forState:UIControlStateNormal];
        [_photoButton addTarget:self action:@selector(shutterCamera:)
               forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_photoButton];
    }
    return _photoButton;
}

- (UIButton *)cancleButton {
    if (!_cancleButton) {
        UIImage *image = [UIImage imageWithContentsOfFile:[self.resouceBundle pathForResource:@"closeButton" ofType:@"png"]];
        _cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancleButton setImage:image
                       forState:UIControlStateNormal];
        [_cancleButton addTarget:self action:@selector(cancleButtonAction)
                forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_cancleButton];
    }
    return _cancleButton;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithRed:20/255.f green:20/255.f blue:20/255.f alpha:1];
        _bottomView.hidden = YES;
        
        [self.view addSubview:_bottomView];
    }
    return _bottomView;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        UIImage * image = [UIImage imageWithContentsOfFile:[self.resouceBundle pathForResource:@"cameraFlash" ofType:@"png"]];
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashButton.tintColor = [UIColor whiteColor];
        [_flashButton setImage:image
                      forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(flashOn:)
               forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_flashButton];
    }
    return _flashButton;
}

- (NSBundle *)resouceBundle {
    if (!_resouceBundle) {
        _resouceBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"DXIDCardCamera" ofType:@"bundle"]];
    }
    return _resouceBundle;
}

@end
