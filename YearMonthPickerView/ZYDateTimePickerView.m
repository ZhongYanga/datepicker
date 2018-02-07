//
//  ZYDateTimePickerView.m
//  YearMonthPickerView
//
//  Created by zhongyang on 2018/1/31.
//  Copyright © 2018年 zhongyang. All rights reserved.
//

#import "ZYDateTimePickerView.h"
#import <Masonry.h>
#import "UIColor+ZYExtension.h"
@interface ZYDateTimePickerView ()<UIPickerViewDataSource,UIPickerViewDelegate>
/* 取消按钮*/
@property (nonatomic, strong) UIButton *cancelBtn;
/* 确定按钮*/
@property (nonatomic, strong) UIButton *sureBtn;
/* pickView*/
@property (nonatomic, strong) UIPickerView *pickView;
/* 背景view 包含工具栏和pickview*/
@property (nonatomic, strong) UIView *popView;
/* 工具栏*/
@property (nonatomic, strong) UIView *toolView;
/** 分割线 */
@property (nonatomic, strong) UIView *lineView;
/** selectedDateStr */
@property (nonatomic, copy) NSString *selectedDateTimeStr;
/** daysArray */
@property (nonatomic, strong) NSMutableArray *daysArray;
/** hoursArray */
@property (nonatomic, strong) NSMutableArray *hoursArray;
/** min */
@property (nonatomic, strong) NSMutableArray *minutesArray;
@end

static CGFloat const kToolViewHeight = 44;
static CGFloat const kPickViewHeight = 216;
static NSInteger const kMaxRowCount = 16438;

@implementation ZYDateTimePickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self popView];
        [self toolView];
        [self pickView];
        [self.popView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.pickView.mas_bottom);
        }];
        [self layoutIfNeeded];
        //默认滚动最中间
        [self.pickView selectRow:kMaxRowCount/2 inComponent:1 animated:NO];
        [self.pickView selectRow:kMaxRowCount/2 inComponent:2 animated:NO];
    }
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    UIView *view = [touch view];
    if (view == self) {
        [self dismiss];
    }
}
#pragma mark - Public Method
- (void)show
{
    [self calculateDateTime];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self.popView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mas_bottom).offset(-kPickViewHeight-kToolViewHeight);
    }];
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        [self layoutIfNeeded];
    }];
    
}
- (void)dismiss
{
    [self.popView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.mas_bottom).offset(0);
    }];
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundColor = [UIColor clearColor];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
#pragma mark - Target Method
- (void)cancelBtnClick
{
    [self dismiss];
}
- (void)sureBtnClick
{
    [self dismiss];
    NSString *selectedDateStr = self.daysArray[[self.pickView selectedRowInComponent:0]];
    if ([selectedDateStr isEqualToString:@"今天"]) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitWeekday fromDate:[NSDate date]];
        selectedDateStr = [NSString stringWithFormat:@"%zd年%zd月%02zd日 ",[components year],[components month],[components day]];
        
    }
    NSString *selectedHourStr = self.hoursArray[[self.pickView selectedRowInComponent:1] % self.hoursArray.count];
    NSString *selectedMinuteStr = self.minutesArray[[self.pickView selectedRowInComponent:2] % self.minutesArray.count] ;
    NSString *selectedDateTimeStr = [NSString stringWithFormat:@"%@ %@:%@",[selectedDateStr substringToIndex:11],selectedHourStr,selectedMinuteStr];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    NSDate *selectedDate = [formatter dateFromString:selectedDateTimeStr];
    !_didSelectedTimeStrBlock?:_didSelectedTimeStrBlock(selectedDateTimeStr,selectedDate);
    
}
#pragma mark - getDateTimeData
// 获取当月的天数
- (NSInteger)getNumberOfDaysInMonthOfDate:(NSDate *)date
{
    NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; // 指定日历的算法
    NSRange range = [calendar rangeOfUnit:NSCalendarUnitDay
                                   inUnit:NSCalendarUnitMonth
                                  forDate:date];
    return range.length;
}
/**
 *  获取当月中所有天数是周几
 */
- (void)getAllDaysWithCalenderOfDate:(NSDate *)date
{
    NSUInteger dayCount = [self getNumberOfDaysInMonthOfDate:date]; //一个月的总天数
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyy年MM月"];
    
    NSInteger startDay = 1;
    if ([[formatter stringFromDate:date] isEqualToString:[formatter stringFromDate:_minimumDate]]) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitWeekday fromDate:_minimumDate];
        startDay = [components day];
    }
    if ([[formatter stringFromDate:date] isEqualToString:[formatter stringFromDate:_maximumDate]]) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitWeekday fromDate:_maximumDate];
        dayCount = [components day];
    }
    NSMutableArray * allDaysArray = [[NSMutableArray alloc] init];
    NSString * str = [formatter stringFromDate:date];
    [formatter setDateFormat:@"yyyy年MM月dd日"];
    for (NSInteger i = startDay; i <= dayCount; i++) {
        NSString * sr = [NSString stringWithFormat:@"%@%02ld日",str,i];
        NSDate *suDate = [formatter dateFromString:sr];
        if ([self isToday:suDate]) {
//            [allDaysArray addObject:@"今天"];
            [allDaysArray addObject:[NSString stringWithFormat:@"%@ %@",sr,[self getweekDayWithDate:suDate]]];
        } else {
            [allDaysArray addObject:[NSString stringWithFormat:@"%@ %@",sr,[self getweekDayWithDate:suDate]]];
        }
        
    }
    [self.daysArray addObjectsFromArray:allDaysArray];
}

/**
 *  获取指定的日期是星期几
 */
- (id)getweekDayWithDate:(NSDate *)date
{
    NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; // 指定日历的算法
    NSDateComponents *comps = [calendar components:NSCalendarUnitWeekday fromDate:date];
    
    // 1 是周日，2是周一 3.以此类推
    return [self weekMappingFrom:[comps weekday]];
    
}
/**
 *  包装周几字符串
 */
- (NSString *)weekMappingFrom:(NSInteger)weekDay {
    switch (weekDay) {
        case 1:
            return @"周日";
        case 2:
            return @"周一";
        case 3:
            return @"周二";
        case 4:
            return @"周三";
        case 5:
            return @"周四";
        case 6:
            return @"周五";
        case 7:
            return @"周六";
        default:
            break;
    }
    return nil;
}
- (BOOL)isToday:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitDay | NSCalendarUnitMonth |  NSCalendarUnitYear;
    // 1.获得当前时间的年月日
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    // 2.获得传入的年月日
    NSDateComponents *selfCmps = [calendar components:unit fromDate:date];
    return(selfCmps.year == nowCmps.year) &&(selfCmps.month == nowCmps.month) &&(selfCmps.day == nowCmps.day);
}
- (void)calculateDateTime
{
    if (self.maximumDate == nil) {
        self.maximumDate = [NSDate dateWithTimeIntervalSinceNow:10000000];
    }
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *maxComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:_maximumDate];
    // 最小时间
    if (self.minimumDate == nil) {
        self.minimumDate = [NSDate date];
    }
    NSDateComponents *miniComponents2 = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:self.minimumDate];
    NSInteger miniYear = [miniComponents2 year];
    NSInteger maxYear = [maxComponents year];
    NSInteger miniMonth = [miniComponents2 month];
    NSInteger maxMonth = [maxComponents month];
    for (NSInteger i = miniYear; i <= maxYear; i++) {
        for (NSInteger j = 1; j <= 12; j ++) {
            if (i == miniYear && j < miniMonth) {
                continue;
            }
            if (i == maxYear && j > maxMonth) {
                break;
            }
            NSString *dateStr = [NSString stringWithFormat:@"%zd-%02zd",i,j];
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            [formatter setDateFormat:@"yyyy-MM"];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
            NSDate *date = [formatter dateFromString:dateStr];
            [self getAllDaysWithCalenderOfDate:date];
        }
    }
    NSDateComponents *nowComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
    NSInteger nowHour = [nowComponents hour];
    NSInteger nowMinute = [nowComponents minute];
    [self.pickView reloadAllComponents];
    //滚动到最中间位置 伪无限循环
    NSInteger hourCount = kMaxRowCount / 2 % self.hoursArray.count;
    NSInteger minuteCount = kMaxRowCount / 2 % self.minutesArray.count;
    NSInteger hourIndex = [self.hoursArray indexOfObject:[NSString stringWithFormat:@"%02zd",nowHour]];
    NSInteger minuteIndex = [self.minutesArray indexOfObject:[NSString stringWithFormat:@"%02zd",nowMinute]];
    [self.pickView selectRow:kMaxRowCount / 2 + (hourIndex - hourCount) inComponent:1 animated:NO];
    [self.pickView selectRow:kMaxRowCount / 2 + (minuteIndex - minuteCount) inComponent:2 animated:NO];
}
//选中的时间是否越界超出最小最大时间
- (void)isOutofDate
{
    NSString *dayStr = self.daysArray[[self.pickView selectedRowInComponent:0]];
    NSString *hourStr = self.hoursArray[[self.pickView selectedRowInComponent:1] % self.hoursArray.count];
    NSString *minuteStr = self.minutesArray[[self.pickView selectedRowInComponent:2] % self.minutesArray.count];
    
    NSString *dateStr = [NSString stringWithFormat:@"%@ %@:%@",[dayStr substringToIndex:11],hourStr,minuteStr];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    NSDate *date = [formatter dateFromString:dateStr];
    
    if ([date earlierDate:_minimumDate] == date) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:_minimumDate];
        NSInteger hourCount = kMaxRowCount / 2 % self.hoursArray.count;
        NSInteger hourIndex = [self.hoursArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components hour]]];
        [self.pickView selectRow:kMaxRowCount / 2 + (hourIndex - hourCount) inComponent:1 animated:YES];
        NSInteger minuteCount = kMaxRowCount / 2 % self.minutesArray.count;
        NSInteger minuteIndex = [self.minutesArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components minute]]];
        [self.pickView selectRow:kMaxRowCount / 2 + (minuteIndex - minuteCount) inComponent:2 animated:YES];
    }
    if ([date earlierDate:_maximumDate] == _maximumDate) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:_maximumDate];
        NSInteger hourCount = kMaxRowCount / 2 % self.hoursArray.count;
        NSInteger hourIndex = [self.hoursArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components hour]]];
        [self.pickView selectRow:kMaxRowCount / 2 + (hourIndex - hourCount) inComponent:1 animated:YES];
        NSInteger minuteCount = kMaxRowCount / 2 % self.minutesArray.count;
        NSInteger minuteIndex = [self.minutesArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components minute]]];
        [self.pickView selectRow:kMaxRowCount / 2 + (minuteIndex - minuteCount) inComponent:2 animated:YES];
    }
}
#pragma mark - <UIPickerViewDataSource>
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return self.daysArray.count;
    } else if(component == 1){
        return kMaxRowCount;
    }else{
        return kMaxRowCount;
    }
}
#pragma mark - <UIPickerViewDelegate>
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self isOutofDate];
    /*
    if (component == 0) {
        if ([pickerView selectedRowInComponent:0] == 0) {
            NSString *dayStr = self.daysArray[row];
            NSString *hourStr = self.hoursArray[[self.pickView selectedRowInComponent:1] % self.hoursArray.count];
            NSString *minuteStr = self.minutesArray[[self.pickView selectedRowInComponent:2] % self.minutesArray.count];
            
            NSString *dateStr = [NSString stringWithFormat:@"%@ %@:%@",[dayStr substringToIndex:11],hourStr,minuteStr];
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
            NSDate *date = [formatter dateFromString:dateStr];
            if ([date earlierDate:[NSDate date]] == date) {
                NSCalendar* calendar = [NSCalendar currentCalendar];
                NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
                NSInteger hourCount = kMaxRowCount / 2 % self.hoursArray.count;
                NSInteger hourIndex = [self.hoursArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components hour]]];
                [pickerView selectRow:kMaxRowCount / 2 + (hourIndex - hourCount) inComponent:1 animated:YES];
                NSInteger minuteCount = kMaxRowCount / 2 % self.minutesArray.count;
                NSInteger minuteIndex = [self.minutesArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components minute]]];
                [pickerView selectRow:kMaxRowCount / 2 + (minuteIndex - minuteCount) inComponent:2 animated:YES];
            }
        }
    }
    if (component == 1) {
        if ([pickerView selectedRowInComponent:0] == 0) {
            NSCalendar* calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:[NSDate date]];
            NSInteger hourCount = kMaxRowCount / 2 % self.hoursArray.count;
            NSInteger hourIndex = [self.hoursArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components hour]]];
            if ([self.hoursArray[row % self.hoursArray.count] integerValue] < [components hour]) {
                [pickerView selectRow:kMaxRowCount / 2 + (hourIndex - hourCount) inComponent:1 animated:YES];
            }
        }
    }
    if (component == 2) {
        if ([pickerView selectedRowInComponent:0] == 0) {
            NSCalendar* calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitMinute fromDate:[NSDate date]];
            NSInteger minuteCount = kMaxRowCount / 2 % self.minutesArray.count;
            NSInteger minuteIndex = [self.minutesArray indexOfObject:[NSString stringWithFormat:@"%02zd",[components minute]]];
            if ([self.minutesArray[row % self.minutesArray.count] integerValue] < [components minute]) {
                [pickerView selectRow:kMaxRowCount / 2 + (minuteIndex - minuteCount) inComponent:2 animated:YES];
            }
        }
    }
     */
    
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
//        if (row == 0) {
//            return @"今天";
//        }else{
           return [self.daysArray[row] substringFromIndex:6];
//        }
    } else if(component == 1){
        return self.hoursArray[row % self.hoursArray.count];
    }else{
        return self.minutesArray[row % self.minutesArray.count];
    }
}
// 重写方法设置字体
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    //设置分割线的颜色
    for(UIView *singleLine in pickerView.subviews){
        
        if (singleLine.frame.size.height < 1){
            singleLine.backgroundColor = [UIColor colorWithHexString:@"#D8D4D5"];
        }
    }
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:20]];
        pickerLabel.textColor = [UIColor colorWithHexString:@"333333"];
    }
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == 0) {
        return 200;
    } else if(component == 1){
        return 40;
    }else{
        return 40;
    }
}
#pragma mark - lazyload
- (UIView *)popView
{
    if (!_popView) {
        _popView = [UIView new];
        [self addSubview:_popView];
        [_popView setBackgroundColor:[UIColor clearColor]];
        [_popView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self);
            make.top.mas_equalTo(self.mas_bottom);
        }];
    }
    return _popView;
}
- (UIView *)toolView
{
    if (!_toolView) {
        _toolView = [UIView new];
        [_popView addSubview:_toolView];
        _toolView.backgroundColor = [UIColor whiteColor];
        [_toolView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kToolViewHeight);
            make.top.mas_equalTo(0);
        }];
        [self cancelBtn];
        [self sureBtn];
        [self lineView];
    }
    return _toolView;
}
- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc]init];
        [_toolView addSubview:_cancelBtn];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor colorWithHexString:@"#2D96E0"] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [_cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(16.5);
            make.centerY.mas_equalTo(0);
        }];
    }
    return _cancelBtn;
}
- (UIButton *)sureBtn
{
    if (!_sureBtn) {
        _sureBtn = [[UIButton alloc]init];
        [_toolView addSubview:_sureBtn];
        [_sureBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_sureBtn setTitleColor:[UIColor colorWithHexString:@"#2D96E0"] forState:UIControlStateNormal];
        [_sureBtn addTarget:self action:@selector(sureBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [_sureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-16.5);
            make.centerY.mas_equalTo(0);
        }];
    }
    return _sureBtn;
}
- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [UIView new];
        [_toolView addSubview:_lineView];
        _lineView.backgroundColor = [UIColor colorWithHexString:@"ECECEC"];
        [_lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.mas_equalTo(0);
            make.height.mas_equalTo(0.5);
        }];
    }
    return _lineView;
}
- (UIPickerView *)pickView
{
    if (!_pickView) {
        _pickView  = [[UIPickerView alloc]init];
        [_popView addSubview:_pickView];
        _pickView.backgroundColor = [UIColor whiteColor];
        _pickView.dataSource = self;
        _pickView.delegate = self;
        [_pickView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_toolView.mas_bottom);
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(kPickViewHeight);
        }];
    }
    return _pickView;
}
- (NSMutableArray *)daysArray
{
    if (!_daysArray) {
        _daysArray = [NSMutableArray array];
//        for (NSInteger i = 0; i < 24; i ++) {
//            [_daysArray addObject:[NSString stringWithFormat:@"%10zd",i]];
//        }
    }
    return _daysArray;
}
- (NSMutableArray *)hoursArray
{
    if (!_hoursArray) {
        _hoursArray = [NSMutableArray array];
        for (NSInteger i = 0; i < 24; i ++) {
            [_hoursArray addObject:[NSString stringWithFormat:@"%02zd",i]];
        }
    }
    return _hoursArray;
}
- (NSMutableArray *)minutesArray
{
    if (!_minutesArray) {
        _minutesArray = [NSMutableArray array];
        for (NSInteger i = 0; i < 60; i = i+1) {
            [_minutesArray addObject:[NSString stringWithFormat:@"%02zd",i]];
        }
    }
    return _minutesArray;
}
@end
