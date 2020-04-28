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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        trustThisApplication()

        Mouse.shared.setFriction(10) // TODO: load from config
        Mouse.shared.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func trustThisApplication() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        guard AXIsProcessTrustedWithOptions([key: true] as NSDictionary) else {
            exit(1)
        }
    }
}

