//
//  AppDelegate.m
//  JsonToModel
//
//  Created by 李兆祥 on 2018/4/17.
//  Copyright © 2018年 李兆祥. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag{
    if (!flag){
        //主窗口显示
        [NSApp activateIgnoringOtherApps:NO];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"appReopen" object:nil userInfo:nil];
        
    }
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
