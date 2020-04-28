//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import HotKey

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var leftLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSRunningApplication().activate(options: .activateIgnoringOtherApps)
    }

    @IBAction func setLeft(_ sender: Any) {
        captureKey() { event in
            guard let key = Key(carbonKeyCode: UInt32(event.keyCode)) else {
                return
            }
            self.leftHotKey = HotKey(key: key, modifiers: event.modifierFlags,
                    keyDownHandler: {
                        self.direction.left = true
                        self.setForce()
                    },
                    keyUpHandler: {
                        self.direction.left = false
                        self.setForce()
                    })
        }
    }

    private var handlerObject: Any? = nil

    private func captureKey(block: @escaping (NSEvent) -> Void) {
        if (self.handlerObject != nil) {
            removeCapture()
        }
        self.handlerObject = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            block($0)
            self.removeCapture()
            return $0
        }
    }

    private func removeCapture(){
        NSEvent.removeMonitor(self.handlerObject!)
        self.handlerObject = nil
    }

    private var up: HotKey?
    private var down: HotKey?
    private var leftHotKey: HotKey?
    private var right: HotKey?

    struct Direction {
        var up = false
        var down = false
        var left = false
        var right = false
    }

    var direction = Direction()

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
            leftHotKey = HotKey(key: key, modifiers: event.modifierFlags,
                    keyDownHandler: {
                        self.direction.left = true
                        self.setForce()
                    },
                    keyUpHandler: {
                        self.direction.left = false
                        self.setForce()
                    })
        }
    }

    func setForce() {
        let acceleration: CGFloat = 11.0
        let dx: CGFloat = (direction.left ? -acceleration : 0.0) + (direction.right ? acceleration : 0.0)
        let dy: CGFloat = (direction.up ? -acceleration : 0.0) + (direction.down ? acceleration : 0.0)
        Mouse.shared.setAcceleration(dx, dy)
    }

}
