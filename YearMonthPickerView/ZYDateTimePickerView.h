//
//  ZYDateTimePickerView.h
//  YearMonthPickerView
//
//  Created by zhongyang on 2018/1/31.
//  Copyright © 2018年 zhongyang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZYDateTimePickerView : UIView
- (void)show;
- (void)dismiss;
/** 最小时间 */
@property (nullable, strong, nonatomic) NSDate *minimumDate;
/** 最大时间 */
@property (nullable, strong, nonatomic) NSDate *maximumDate;
@property (nonatomic, copy) void (^_Nullable didSelectedTimeStrBlock)(NSString * _Nullable selectedDateTimeStr,NSDate * _Nullable selectedDate);
@end
