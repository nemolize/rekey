//
//  ViewController.swift
//
//  Created by mnemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
import Cocoa
import Foundation
import JavaScriptCore

let executionLock = NSLock()
let jsContext = JSContext()
var modifierFlags: CGEventFlags = CGEventFlags(rawValue: 256)

func onKeyEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>?{
    
    if (event.getIntegerValueField(CGEventField.eventSourceUserData)==Constants.magicValue) {
        return Unmanaged.passUnretained(event)
    }
    
    // queue processing worker thread
    DispatchQueue(label: Constants.processQueueName).async {
        
        // syskey
        if type.rawValue == UInt32(NX_SYSDEFINED){
            if let nsEvent = NSEvent(cgEvent: event) , nsEvent.subtype.rawValue == 8 {
                let keyCode = (nsEvent.data1 & 0xffff0000) >> 16
                let isUp = ((nsEvent.data1 & 0xff00) >> 8) != 0xa
                let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)
                
                executionLock.lock()
                defer{executionLock.unlock()}
                
                // call js code
                if let mainFunc = jsContext?.objectForKeyedSubscript("onSysKey"){
                    if !mainFunc.isUndefined {
                        let result = mainFunc.call(withArguments: [keyCode,
                                                                   event.flags.rawValue,
                                                                   isRepeat,
                                                                   isUp,
                                                                   true])
                        if result?.isBoolean == true && result?.toBool() == true { return }
                    }
                }
            }
        }
        
        if [.keyDown , .keyUp].contains(type) {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let isUp=type == .keyUp
            let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)
            
            executionLock.lock()
            defer{executionLock.unlock()}
            
            // call js code
            if let mainFunc = jsContext?.objectForKeyedSubscript("onKey"){
                if !mainFunc.isUndefined {
                    let result = mainFunc.call(withArguments: [keyCode,
                                                               event.flags.rawValue,
                                                               isRepeat,
                                                               isUp,
                                                               false])
                    if result?.isBoolean == true && result?.toBool() == true { return }
                }
            }
        }
        else if [.flagsChanged].contains(type) // on flags changed
        {
            modifierFlags = event.flags
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let isUp=type == .keyUp
            let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)
            
            executionLock.lock()
            defer{executionLock.unlock()}
            
            _ = jsContext?.evaluateScript("var flags=\(event.flags.rawValue)")
            
            // call js code
            if let mainFunc = jsContext?.objectForKeyedSubscript("onFlagsChanged"){
                if !mainFunc.isUndefined {
                    let result = mainFunc.call(withArguments: [keyCode,
                                                               event.flags.rawValue,
                                                               isRepeat,
                                                               isUp,
                                                               false])
                    if result?.isBoolean == true && result?.toBool() == true { return }
                }
            }
        }
    }

    if [.keyDown , .keyUp].contains(type){
        return nil
    }
    
    // TODO return nil when emit event is implemented
    return Unmanaged.passUnretained(event)
}


class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet var jsTextInput: NSTextView!
    @IBOutlet var logLabel: NSTextView!
    
    var isCommandPressed=false
    
    private func setUpConsoleUIKeyEvent(){
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
        jsTextInput.isAutomaticQuoteSubstitutionEnabled=false
        jsTextInput.isAutomaticSpellingCorrectionEnabled=false
        jsTextInput.isContinuousSpellCheckingEnabled=false
        
        // get console UI key event
        setUpConsoleUIKeyEvent()
        
        // capture key events in background thread
        DispatchQueue(label: Constants.captureEventQueueName).async {
            self.backgroundThread()
        }
        
        // append log notification from non UI threads to the UI thread
        NotificationCenter.default.addObserver(
            forName: .appendLog,
            object: nil,
            queue: nil,
            using: { notification in
                guard notification.object != nil else { print("notification object is nil"); return }
                self.log("\( notification.object ?? "undefined" )")
        })

        let intrinsics=Intrinsics()
        intrinsics.setUpAppIntrinsicJsObjects()
    }
    
    func log(_ message: String?){
        DispatchQueue.main.async {
            if message == nil { return }
            // prevent NSTextView slowness https://stackoverflow.com/a/5495287
            let ts = self.logLabel.textStorage
            ts?.beginEditing()
            ts?.append(NSAttributedString(string: "\(message!)\n"))
            ts?.endEditing()
            self.logLabel.scrollToEndOfDocument(nil)
        }
    }
    
    var histories: [String] = []
    
    func executeBuffer(){
        guard let jsSource=jsTextInput.string?.trimmingCharacters(in: ["\n","\t"," "]) else { return }
        guard !jsSource.isEmpty else { return }
        
        logLabel.string? += "[expression]: \(jsSource)\n"
        
        executionLock.lock()
        defer{executionLock.unlock()}
        let result = jsContext!.evaluateScript(jsSource)
        var expression = "\(result!)"
        if result?.isString == true {
            expression = "\"\(expression)\""
        }
        
        log("=> \(expression)")
        
        if 100 < histories.count { histories.removeFirst() }
        histories.append(jsSource)
        
        jsTextInput.string = ""
        logLabel.scrollToEndOfDocument(nil)
    }
    
    func loadHistory(){
        jsTextInput.string=""
        if 0 < histories.count{
            jsTextInput.string = histories.popLast()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if isCommandPressed && event.keyCode == Keycodes.Enter {
            executeBuffer()
        }else if event.keyCode == Keycodes.upArrow {
            let range=jsTextInput.selectedRange()
            if range.location==0 && range.length==0{
                loadHistory()
            }
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        isCommandPressed=event.modifierFlags.contains(NSCommandKeyMask)
    }
    
    func loadConfig(){
        // get the home path directory
        let confPath=NSHomeDirectory()+"/.config/rekey.js"
        
        if FileManager.default.fileExists(atPath: confPath){
            if let jsSource = try? String(contentsOfFile: confPath){
                jsContext!.evaluateScript(jsSource)
            }else{
                self.log(String(format:"failed to load %@",confPath))
            }
        } else {
            self.log(String(format:"user config file does not exist. %@",confPath))
        }
    }
    
    func createEventTap(){
        let eventMask = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
            UInt32(NX_SYSDEFINED)
            ].reduce(0) { prev, next in prev | (1 << next) }
        
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: onKeyEvent,
                                               userInfo: nil)
            else {
                print("failed to create event tap")
                exit(1)
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }
        
    func backgroundThread(){
        print("starting background thread")
        jsContext?.exceptionHandler = { context, exception in
            self.log("JS Error: \(exception?.description ?? "unknown error" )")
        }
        loadConfig()
        createEventTap()
    }
}
