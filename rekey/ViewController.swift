//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.

import Cocoa
import Foundation
import JavaScriptCore

class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet var jsTextInput: NSTextView!
    @IBOutlet var logLabel: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        NSRunningApplication().activate(options: .activateIgnoringOtherApps)
    }
}
