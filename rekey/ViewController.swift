//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import HotKey

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var upSetButton: NSButton!
    @IBOutlet weak var downSetButton: NSButton!
    @IBOutlet weak var leftSetButton: NSButton!
    @IBOutlet weak var rightSetButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSRunningApplication().activate(options: .activateIgnoringOtherApps)
    }

    @IBAction func setUp(_ sender: Any) {
        captureKey {
            self.updateHotKey(up: $0.setHandler({ self.updateDirection(up: $0) }))
        }
    }

    @IBAction func setDown(_ sender: Any) {
        captureKey {
            self.updateHotKey(down: $0.setHandler({ self.updateDirection(down: $0) }))
        }
    }

    @IBAction func setLeft(_ sender: Any) {
        captureKey {
            self.updateHotKey(left: $0.setHandler({ self.updateDirection(left: $0) }))
        }
    }

    @IBAction func setRight(_ sender: Any) {
        captureKey {
            self.updateHotKey(right: $0.setHandler({ self.updateDirection(right: $0) }))
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

    private struct DirectionHotKey {
        var up: HotKey? = nil
        var down: HotKey? = nil
        var left: HotKey? = nil
        var right: HotKey? = nil
    }

    private struct Direction {
        var up = false
        var down = false
        var left = false
        var right = false
    }

    private var hotKey = DirectionHotKey()
    private var direction = Direction()

    private func updateHotKey(up: HotKey? = nil, down: HotKey? = nil, left: HotKey? = nil, right: HotKey? = nil) {
        if (up != nil) {
            hotKey.up = up
            upSetButton.title = up!.keyCombo.description
        }

        if (down != nil) {
            hotKey.down = down
            downSetButton.title = down!.keyCombo.description
        }

        if (left != nil) {
            hotKey.left = left
            leftSetButton.title = left!.keyCombo.description
        }

        if (right != nil) {
            hotKey.right = right
            rightSetButton.title = right!.keyCombo.description
        }
    }

    private func updateDirection(up: Bool? = nil, down: Bool? = nil, left: Bool? = nil, right: Bool? = nil) {
        direction.up = up ?? direction.up
        direction.down = down ?? direction.down
        direction.left = left ?? direction.left
        direction.right = right ?? direction.right
        setForce()
    }


    private func setForce() {
        let acceleration: CGFloat = 2.75
        let x: CGFloat = (direction.left ? -acceleration : 0.0) + (direction.right ? acceleration : 0.0)
        let y: CGFloat = (direction.up ? -acceleration : 0.0) + (direction.down ? acceleration : 0.0)
        AppDelegate.windowMovePhysics.setAcceleration(x, y)
    }

}
