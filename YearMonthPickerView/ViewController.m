//
//  ViewController.m
//  YearMonthPickerView
//
//  Created by zhongyang on 2018/1/11.
//  Copyright © 2018年 zhongyang. All rights reserved.
//

#import "ViewController.h"
#import "ZYDatePickerView.h"
#import "ZYDateTimePickerView.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s",__func__);
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"MM月dd日  hh:mm"];
    NSString *dateStr = @"02月02日  17:00";
    NSString *dateStr1 = @"02月01日  17:01";
    NSLog(@"%ld",(long)[dateStr compare:dateStr1]);
}
- (IBAction)yearMonthPickerClick:(id)sender
{
    ZYDatePickerView *pickerView = [[ZYDatePickerView alloc]init];
    [self.view addSubview:pickerView];
    pickerView.minimumDate = [NSDate dateWithTimeIntervalSince1970:1434004116];
    pickerView.maximumDate = [NSDate dateWithTimeIntervalSince1970:1520107444];
    [pickerView show];
    pickerView.didSelectedTimeStrBlock = ^(NSString * _Nullable timeStr) {
        NSLog(@"%@",timeStr);
        self.timeLabel.text = timeStr;
    };
}
- (IBAction)dateTimePickerClick:(id)sender
{
    ZYDateTimePickerView *pickerView = [[ZYDateTimePickerView alloc]init];
    [self.view addSubview:pickerView];
    pickerView.minimumDate = [NSDate date];
    pickerView.maximumDate = [NSDate dateWithTimeIntervalSince1970:1525950610];
    [pickerView show];
    pickerView.didSelectedTimeStrBlock = ^(NSString * _Nullable selectedDateTimeStr, NSDate * _Nullable selectedDate) {
        self.timeLabel.text = selectedDateTimeStr;
    };
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    [self calculateDateTime];
    
    /*
    ZYDatePickerView *pickerView = [[ZYDatePickerView alloc]init];
    [self.view addSubview:pickerView];
    pickerView.minimumDate = [NSDate dateWithTimeIntervalSince1970:1434004116];
    pickerView.maximumDate = [NSDate dateWithTimeIntervalSince1970:1520107444];
    [pickerView show];
    pickerView.didSelectedTimeStrBlock = ^(NSString * _Nullable timeStr) {
        NSLog(@"%@",timeStr);
    };
     */
}



@end
