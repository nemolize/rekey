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

    static let windowMovePhysics = PointPhysics(onUpdate: { (_, velocity) in
        do {
            let appRef = try getFrontmostApplicationElement()

            var windowRef: AnyObject?
            try appRef.copyAttributeValue(kAXFocusedWindowAttribute, &windowRef)
            let windowElement: AXUIElement = windowRef as! AXUIElement

            var positionRef: CFTypeRef?
            try windowElement.copyAttributeValue(kAXPositionAttribute, &positionRef)

            var position = CGPoint()
            if !AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &position) {
                throw AppError.accessibility("AXValueGetValue has failed")
            }

            position += velocity

            if let positionAxValue = AXValueCreate(AXValueType.cgPoint, &position) {
                try windowElement.setAttributeValue(kAXPositionAttribute, positionAxValue)
            }

        } catch AppError.accessibility(let message, let code) {
            debugPrint(message, code ?? "none")
        } catch {
            debugPrint("Unknown error has occurred.")
        }
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

