//
//  NavigationController.m
//  DecodeVideoFrameDemo
//
//  Created by dynamsoft on 2020/7/8.
//  Copyright © 2020 dynamsoft. All rights reserved.
//

#import "NavigationController.h"

@interface NavigationController ()

@end

@implementation NavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)controllerWillPopHandler {
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *vc = self.topViewController;
    if ([vc respondsToSelector:@selector(controllerWillPopHandler)]) {
        [vc performSelector:@selector(controllerWillPopHandler)];
    }
    return [super popViewControllerAnimated:animated];
}

@end
