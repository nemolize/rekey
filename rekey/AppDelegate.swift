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

    static let windowMovePhysics = PointPhysics(onSetPosition: { (_, velocity) in
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            debugPrint("failed to obtain frontmostApplication")
            return
        }

        let appRef = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let windowsResult = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
        if windowsResult != AXError.success {
            debugPrint("AXUIElementCopyAttributeValue for windows has failed with code: \(windowsResult.rawValue)")
            return
        }

        guard let windowElement: AXUIElement = (windowsRef as? [AXUIElement])?.first else {
            debugPrint("failed to get window")
            return
        }

        var positionRef: CFTypeRef?
        let getPositionResult = AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef);
        if positionRef == nil || getPositionResult != AXError.success {
            debugPrint("AXUIElementCopyAttributeValue has failed with code: \(getPositionResult.rawValue)")
            return
        }

        var position = CGPoint()
        if !AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &position) {
            debugPrint("AXValueGetValue has failed")
            return
        }

        position += velocity

        if let pointRef = AXValueCreate(AXValueType.cgPoint, &position) {
            let ret: AXError = AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, pointRef)
            if ret.rawValue != 0 {
                debugPrint("AXUIElementSetAttributeValue has failed with code: \(ret.rawValue)")
            }
        }
        return
    })

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if (!isTrusted()) {
            NSApplication.shared.terminate(self)
        }

        // TODO: load from config
        AppDelegate.windowMovePhysics.setFriction(2)
        AppDelegate.windowMovePhysics.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func isTrusted() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        return AXIsProcessTrustedWithOptions([key: true] as NSDictionary)
    }
}

