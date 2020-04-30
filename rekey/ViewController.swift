//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import HotKey

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var leftSetButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSRunningApplication().activate(options: .activateIgnoringOtherApps)
    }

    @IBAction func setLeft(_ sender: Any) {
        captureKey {
            self.leftHotKey = $0.setHandler({ self.updateDirection(left: $0) })
            self.leftSetButton.title = $0.keyCombo.description
        }
    }

    private var handlerObject: Any? = nil

    private func captureKey(block: @escaping (HotKey) -> Void) {
        self.handlerObject = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.removeCapture()
            if let key = Key(carbonKeyCode: UInt32($0.keyCode)) {
                block(HotKey(key: key, modifiers: $0.modifierFlags))
            }
            return $0
        }
    }

    private func removeCapture() {
        if let handlerObject = self.handlerObject {
            NSEvent.removeMonitor(handlerObject)
            self.handlerObject = nil
        }
    }

    private var up: HotKey?
    private var down: HotKey?
    private var leftHotKey: HotKey?
    private var right: HotKey?

    private struct Direction {
        var up = false
        var down = false
        var left = false
        var right = false
    }

    private var direction = Direction()

    private func updateDirection(up: Bool? = nil, down: Bool? = nil, left: Bool? = nil, right: Bool? = nil) {
        direction.up = up ?? direction.up
        direction.down = down ?? direction.down
        direction.left = left ?? direction.left
        direction.right = right ?? direction.right
        setForce()
    }


    private func setForce() {
        let acceleration: CGFloat = 11.0
        let x: CGFloat = (direction.left ? -acceleration : 0.0) + (direction.right ? acceleration : 0.0)
        let y: CGFloat = (direction.up ? -acceleration : 0.0) + (direction.down ? acceleration : 0.0)
        AppDelegate.windowMovePhysics.setAcceleration(x, y)
    }

}
