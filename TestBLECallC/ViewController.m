//
//  ViewController.m
//  TestBLECallC
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import "ViewController.h"
#import "CBleHelper.h"
#import "AViewController.h"
#import "BViewController.h"
#import "CViewController.h"

@interface ViewController () <CBleHelperDelegate>

@property (weak, nonatomic) IBOutlet UITextView *msgView;
@property (strong, nonatomic) CBleHelper *helper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.helper = [[CBleHelper alloc] initWithDelegate: self];
    
    AViewController *a = [[AViewController alloc] init];
    BViewController *b = [[BViewController alloc] init];
    CViewController *c = [[CViewController alloc] init];
    [a diuleilaomou];
    [b diuleilaomou];
    [b diuleilaomou];
    [c diuleilaomou];
    [c diuleilaomou];
    [c diuleilaomou];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setup {
    self.msgView.layoutManager.allowsNonContiguousLayout = NO;
}

- (IBAction)write:(id)sender {
    [self.helper sendMsg:@"hehe"];
}

- (IBAction)call:(id)sender {
    [self.helper call];
}

#pragma mark - CBleHelperDelegate method 
- (void)changeMsg:(NSString *)msg {
    self.msgView.text = [NSString stringWithFormat:@"%@\n-----%@", self.msgView.text, msg];
    [self.msgView scrollRangeToVisible:NSMakeRange(self.msgView.text.length, 1)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
