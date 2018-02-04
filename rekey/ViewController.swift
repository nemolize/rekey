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

    var isCommandPressed: Bool = false

    private func setUpConsoleUIKeyEvent() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable automatic replacements
        jsTextInput.isAutomaticQuoteSubstitutionEnabled = false
        jsTextInput.isAutomaticSpellingCorrectionEnabled = false
        jsTextInput.isContinuousSpellCheckingEnabled = false

        // get console UI key event
        setUpConsoleUIKeyEvent()

        // append log notification from non UI threads to the UI thread
        NotificationCenter.default.addObserver(
                forName: .appendLog,
                object: nil,
                queue: nil,
                using: { notification in
                    guard notification.object != nil else {
                        print("notification object is nil");
                        return
                    }
                    self.log("\(notification.object ?? "undefined")")
                })
    }

    var histories: [String] = []

    override func keyDown(with event: NSEvent) {
        if isCommandPressed && event.keyCode == Keycodes.Enter {
            guard let jsSource = jsTextInput.string?.trimmingCharacters(in: ["\n", "\t", " "]) else { return }
            NotificationCenter.postExecuteJS(jsSource)

            if 100 < histories.count { histories.removeFirst() }
            histories.append(jsSource)

            jsTextInput.string = ""
            logLabel.scrollToEndOfDocument(nil)
        } else if event.keyCode == Keycodes.upArrow {
            let range = jsTextInput.selectedRange()
            if range.location == 0 && range.length == 0 {
                loadHistory()
            }
        }
    }

    func loadHistory() {
        jsTextInput.string = ""
        if 0 < histories.count {
            jsTextInput.string = histories.popLast()
        }
    }

    override func flagsChanged(with event: NSEvent) {
        isCommandPressed = event.modifierFlags.contains(NSCommandKeyMask)
    }

    func log(_ message: String?) {
        DispatchQueue.main.async {
            if message == nil { return }
            // prevent NSTextView slowness https://stackoverflow.com/a/5495287
            guard let ts = self.logLabel.textStorage else { return }
            ts.beginEditing()
            ts.append(NSAttributedString(string: "\(message!)\n"))
            ts.endEditing()
            self.logLabel.scrollToEndOfDocument(nil)
        }
    }
}
