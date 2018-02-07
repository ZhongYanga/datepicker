//
//  ZYDatePickerView.m
//  ZYEducation
//
//  Created by zhongyang on 2018/1/5.
//  Copyright © 2018年 zeng. All rights reserved.
//
#define DateFormat @"yyyy.MM"
#import "ZYDatePickerView.h"
#import "UIColor+ZYExtension.h"
#import <Masonry.h>
@interface ZYDatePickerView ()<UIPickerViewDelegate,UIPickerViewDataSource>
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

/** 年份Max */
@property (nonatomic, assign) NSInteger maxYear;

/** 月份Max */
@property (nonatomic, assign) NSInteger maxMonth;
/** 选择的row */
@property (nonatomic, assign) NSInteger selectedRow;
/** 年份min */
@property (nonatomic, assign) NSInteger minYear;

/** 月份min */
@property (nonatomic, assign) NSInteger minMonth;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

/** 年份数组 */
@property (nonatomic,strong) NSMutableArray *yearArray;

/** 月份数组 */
@property (nonatomic,strong) NSMutableArray *monthArray;

/** 是否选择至今 */
@property (nonatomic, assign) BOOL isChooseToday;

/** 选中的年份 */
@property (nonatomic, copy) NSString *choosedYear;

/** 选中的月份 */
@property (nonatomic, copy) NSString *choosedMonth;

/** 是否是当前年份 */
@property (nonatomic, assign) BOOL isCurrentYear;

/** 是否是第一年 */
@property (nonatomic, assign) BOOL isFirstYear;
@end
static CGFloat const kToolViewHeight = 44;
static CGFloat const kPickViewHeight = 216;
@implementation ZYDatePickerView

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
    [self getData];
    [self.pickView reloadAllComponents];
    [self.pickView selectRow:self.yearArray.count - 1 inComponent:0 animated:NO];
    [self.pickView selectRow:self.maxMonth - 1 inComponent:1 animated:NO];
    _selectedRow = self.maxMonth - 1;
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
#pragma mark - <UIPickerViewDataSource>
// 返回选择器有几列.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// 返回每组有几行
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    if (component == 0) {
        return self.yearArray.count;
    }else{
        return self.monthArray.count;
    }
}

#pragma mark - <UIPickerViewDelegate>
// 返回第component列第row行的内容（标题）
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return self.yearArray[row];
    }else{
        return self.monthArray[row];
    }
}

// 选中第component第row的时候调用
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    if (component == 0) {
        NSInteger selectedYear = [[self.yearArray[row] componentsSeparatedByString:@"年"].firstObject integerValue];
        BOOL refresh = [self pickViewShouldRefreshMonthWithSelectedYear:selectedYear refresh:YES];
        if (refresh) {
            [pickerView reloadComponent:1];
        }
        self.choosedYear = self.yearArray[row];
        if (row == 0) {//最小年 比较最小月
            if (self.minMonth - 1 > _selectedRow) {
                _selectedRow = self.minMonth - 1;
            }
        }else if (row == self.yearArray.count - 1){//最大年 计较最大月
            if (self.maxMonth - 1 < _selectedRow) {
                _selectedRow = self.maxMonth - 1;
            }
        }
        self.choosedMonth = self.monthArray[_selectedRow];
    }else{
        _selectedRow = row;
        self.choosedMonth = self.monthArray[row];
    }
    
}

// 重写方法设置字体
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    //设置分割线的颜色
    for(UIView *singleLine in pickerView.subviews){
        
        if (singleLine.frame.size.height < 1){
            
            singleLine.backgroundColor = [UIColor colorWithHexString:@"D8D4D5"];
        }
    }
    
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:18]];
        pickerLabel.textColor = [UIColor blackColor];
    }
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    
    return pickerLabel;
}
#pragma mark - Target Method
- (void)cancelBtnClick
{
    [self dismiss];
}
- (void)sureBtnClick
{
    NSString *timeStr;
    if (self.choosedMonth == nil) {
        timeStr = [NSString stringWithFormat:@"%@%02ld月",self.choosedYear,self.minMonth];
    }else{
        timeStr = [NSString stringWithFormat:@"%@%@",self.choosedYear,self.choosedMonth];
    }
    !_didSelectedTimeStrBlock?:_didSelectedTimeStrBlock(timeStr);
    [self dismiss];
}
#pragma mark - 始化获取数据
- (void)getData{
    
    [self.yearArray removeAllObjects];
    [self.monthArray removeAllObjects];
    // 最大时间
    if (self.maximumDate == nil) {
        self.maximumDate = [self.dateFormatter dateFromString:[self getCurrentTimes]];
    }
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:_maximumDate];
    self.maxYear = [components year];
    self.maxMonth = [components month];
    
    // 最小时间
    if (self.minimumDate == nil) {
        self.minimumDate = [self.dateFormatter dateFromString:@"1970.01"];
    }
    
    NSCalendar *calendar2 = [NSCalendar currentCalendar];
    NSDateComponents *components2 = [calendar2 components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:self.minimumDate];
    self.minYear = [components2 year];
    self.minMonth = [components2 month];
    
    //    NSLog(@"最小时间 %ld   %ld",self.minYear,self.minMonth);
    
    // 年份数组
    for (NSInteger i = self.minYear; i<=self.maxYear; i++) {
        
        [self.yearArray addObject:[NSString stringWithFormat:@"%ld年",i]];
    }
    for (NSInteger i = 1; i<=self.maxMonth; i++) {
        
        [self.monthArray addObject:[NSString stringWithFormat:@"%ld月",i]];
    }
    self.choosedYear = [NSString stringWithFormat:@"%zd年",self.maxYear];
    self.choosedMonth = [NSString stringWithFormat:@"%zd月",self.maxMonth];
    //    NSLog(@"Year= %@ month=%@",self.yearArray,self.monthArray);
    [_pickView reloadAllComponents];
}

/**
 *  获取当前的时间 如:1970.01
 */
- (NSString*)getCurrentTimes{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy.MM"];
    NSDate *datenow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    return currentTimeString;
}
- (BOOL)pickViewShouldRefreshMonthWithSelectedYear:(NSInteger)selectedYear refresh:(BOOL)refresh
{
    if (self.minYear == self.maxYear) {
        NSInteger min = self.minMonth;
        NSInteger max = self.maxMonth;
        if (max < min) {
            min = 1;
        }
        NSMutableArray *months = [NSMutableArray arrayWithCapacity:max - min];
        for (NSUInteger i = min; i <= max; i++) {
            [months addObject:[NSString stringWithFormat:@"%zd月",i]];
        }
        self.monthArray = months;
        return refresh;
    }
    BOOL tmp = refresh;
    if (self.minYear == selectedYear) {
        NSInteger index = 12 - self.minMonth;
        NSMutableArray *months = [NSMutableArray arrayWithCapacity:index];
        for (NSUInteger i = self.minMonth; i <= 12; i++) {
            [months addObject:[NSString stringWithFormat:@"%zd月",i]];
        }
        self.monthArray = months;
    }else if (self.maxYear == selectedYear) {
        NSInteger index = self.maxMonth;
        NSMutableArray *months = [NSMutableArray arrayWithCapacity:index];
        for (NSUInteger i = 1; i <= self.maxMonth; i++) {
            [months addObject:[NSString stringWithFormat:@"%zd月",i]];
        }
        self.monthArray = months;
    }else{
        
        NSMutableArray *months = [NSMutableArray arrayWithCapacity:12];
        for (NSUInteger i = 1; i <= 12; i++) {
            [months addObject:[NSString stringWithFormat:@"%zd月",i]];
        }
        self.monthArray = months;
    }
    return tmp;
}
#pragma mark - setter
- (void)setMinimumDate:(NSDate *)minimumDate
{
    _minimumDate = minimumDate;
    [self getData];
}
- (void)setMaximumDate:(NSDate *)maximumDate
{
    _maximumDate = maximumDate;
    [self getData];
}
#pragma mark - lazyload
- (UIView *)popView
{
    if (!_popView) {
        _popView = [UIView new];
        [self addSubview:_popView];
        [_popView setBackgroundColor:[UIColor clearColor]];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismiss)];
        [_popView addGestureRecognizer:tap];
        [_popView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self);
            make.top.mas_equalTo(self.mas_bottom);
            //            make.height.mas_equalTo(kToolViewHeight+kPickViewHeight);
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
- (NSMutableArray *)yearArray{
    if (_yearArray == nil) {
        _yearArray = [[NSMutableArray alloc] init];
    }
    return _yearArray;
}

- (NSMutableArray *)monthArray{
    if (_monthArray == nil) {
        _monthArray = [NSMutableArray array];
    }
    return _monthArray;
}
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = DateFormat;
    }
    return _dateFormatter;
}
@end

