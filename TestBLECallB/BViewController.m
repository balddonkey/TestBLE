//
//  ViewController.m
//  TestBLECallB
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import "BViewController.h"
#import "BBleHelper.h"

@interface BViewController () <BBleHelperDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextView *msgView;
@property (strong, nonatomic) BBleHelper *helper;
@property (weak, nonatomic) IBOutlet UITextField *phoneTf;
@property (weak, nonatomic) IBOutlet UITextField *contentTf;

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
    
    if (![self checkData]) {
        return;
    }
    NSDictionary *jsObj = @{@"phone": self.phoneTf.text, @"content": self.contentTf.text, @"action": @"sendMsg"};
    
    [self.helper enqueue:jsObj];
}

- (IBAction)openHot:(id)sender {
    NSDictionary *open = @{@"action": @"openHot"};
    [self.helper enqueue:open];
}

- (IBAction)closeHot:(id)sender {
    NSDictionary *close = @{@"action": @"closeHot"};
    [self.helper enqueue:close];
}

- (IBAction)clear {
    self.msgView.text = nil;
}

- (BOOL)checkData {
    if (self.phoneTf.text.length == 0) {
        [self changeMsg:@"请输入对方手机号码"];
        return NO;
    } else if (self.contentTf.text.length == 0) {
        [self changeMsg:@"请输入短信内容"];
        return NO;
    }
    return YES;
}

#pragma mark - CBleHelperDelegate method
- (void)changeMsg:(NSString *)msg {
    self.msgView.text = [NSString stringWithFormat:@"%@\n-----%@", self.msgView.text, msg];
    [self.msgView scrollRangeToVisible:NSMakeRange(self.msgView.text.length, 1)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self clearKeyboard];
    return YES;
}

- (void)clearKeyboard {
    if ([self.phoneTf isFirstResponder]) {
        [self.phoneTf resignFirstResponder];
    } else if ([self.contentTf isFirstResponder]) {
        [self.contentTf resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
