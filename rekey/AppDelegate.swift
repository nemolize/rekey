//
//  AppDelegate.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let appService = AppService()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if (!appService.hasAccessibilityPermission()) {
            NSApplication.shared.terminate(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

