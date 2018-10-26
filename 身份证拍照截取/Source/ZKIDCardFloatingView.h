//
//  ZKIDCardFloatingView.h
//  FBSnapshotTestCase
//
//  Created by zhangkai on 2018/9/21.
//

#import <UIKit/UIKit.h>
#import "ZKIDCardCameraController.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height

NS_ASSUME_NONNULL_BEGIN

@interface ZKIDCardFloatingView : UIView

@property (nonatomic, strong) CAShapeLayer *IDCardWindowLayer;
- (instancetype)initWithType:(ZKIDCardType)type;

@end

NS_ASSUME_NONNULL_END
