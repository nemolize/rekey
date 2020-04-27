//
//  AppDelegate.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa
import Pods_rekey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private func trustThisApplication() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        guard AXIsProcessTrustedWithOptions([key: true] as NSDictionary) else {
            exit(1)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        trustThisApplication()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

