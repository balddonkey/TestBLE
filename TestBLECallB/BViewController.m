//
//  ViewController.m
//  TestBLECallB
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import "BViewController.h"
#import "BBleHelper.h"

@interface BViewController () <BBleHelperDelegate>

@property (weak, nonatomic) IBOutlet UITextView *msgView;
@property (strong, nonatomic) BBleHelper *helper;

@end

@implementation BViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setup {
    self.helper = [[BBleHelper alloc] initWithDelegate:self];
}

- (IBAction)find:(id)sender {
    [self.helper find];
}

- (IBAction)send:(id)sender {
    NSArray *jsObjs = @[
                        @{@"phone": @"13646288987", @"content": @"12345678"}
                        ];
    
    for (NSDictionary *obj in jsObjs) {
        [self.helper enqueue:obj];
    }
    [_helper sendNext];
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
