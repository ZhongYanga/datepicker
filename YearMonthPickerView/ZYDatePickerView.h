//
//  ZYDatePickerView.h
//  ZYEducation
//
//  Created by zhongyang on 2018/1/5.
//  Copyright © 2018年 zeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZYDatePickerView : UIView
- (void)show;
- (void)dismiss;
/** 是否显示今天 */
@property (nonatomic, assign) BOOL isShowToday;

/** 最小时间 */
@property (nullable, weak, nonatomic) NSDate *minimumDate;
/** 最大时间 */
@property (nullable, weak, nonatomic) NSDate *maximumDate;

@property (nonatomic, copy) void (^_Nullable didSelectedTimeStrBlock)(NSString * _Nullable timeStr);
@end
