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

func onKeyEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>?{
    
    // queue processing worker thread
    DispatchQueue(label: "com.nemoto.app.processQueue").async {
        
        if [.keyDown , .keyUp].contains(type) {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let isUp=type == .keyUp
            let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)
            
            executionLock.lock()
            defer{executionLock.unlock()}
            
            // call js code
            if let mainFunc = jsContext?.objectForKeyedSubscript("main"){
                if !mainFunc.isUndefined {
                    let result = mainFunc.call(withArguments: [keyCode,
                                                               event.flags.rawValue,
                                                               isRepeat,
                                                               isUp])
                    if result?.isBoolean == true && result?.toBool() == true { return }
                }
            }
        }
        else if [.flagsChanged].contains(type){
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let isUp=type == .keyUp
            let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)
            
            executionLock.lock()
            defer{executionLock.unlock()}
            print(event.getIntegerValueField(CGEventField.eventSourceStateID))
            // call js code
            if let mainFunc = jsContext?.objectForKeyedSubscript("main"){
                if !mainFunc.isUndefined {
                    let result = mainFunc.call(withArguments: [keyCode,
                                                               event.flags.rawValue,
                                                               isRepeat,
                                                               isUp])
                    if result?.isBoolean == true && result?.toBool() == true { return }
                }
            }
        }
    }
    
    // TODO return nil when emit event is implemented
    return Unmanaged.passUnretained(event)
}


class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var label: NSTextField!
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
        jsTextInput.isAutomaticQuoteSubstitutionEnabled=false
        jsTextInput.isAutomaticSpellingCorrectionEnabled=false
        jsTextInput.isContinuousSpellCheckingEnabled=false
        
        // get console UI key event
        setUpConsoleUIKeyEvent()
        
        // capture key events in background thread
        DispatchQueue(label: "com.nemoto.app.queue").async {
            self.backgroundThread()
        }
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
        print(jsTextInput.attributedString())
        logLabel.scrollToEndOfDocument(nil)
    }
    
    func loadHistory(){
        jsTextInput.string=""
        if 0 < histories.count{
            jsTextInput.string = histories.popLast()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if isCommandPressed && event.keyCode == Keycode.Enter {
            executeBuffer()
        }else if event.keyCode == Keycode.upArrow {
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
            _ = jsContext?.evaluateScript("function main(){}")
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
    
    func setUpAppIntrinsicJsObjects(){
        jsContext?.setb1("_consoleLog") { (arg0)->Any! in
            DispatchQueue.main.async {
                self.log("\( arg0 ?? "undefined" )")
            }
        }
        _ = jsContext?.evaluateScript("console = { log: function() { for (var i = 0; i < arguments.length; i++) { _consoleLog(arguments[i]); }} }")
        
        
        func mouseMove(_ dx:CGFloat,_ dy:CGFloat){
            func getCurrentMouseLocation()-> CGPoint {
                return CGEvent(source:nil)!.location
            }
            
            var point=getCurrentMouseLocation()
            
            point.x+=dx
            point.y+=dy
            
            guard let moveEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left
                )
                else {
                    log("failed to post the event")
                    return
            }
            moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        jsContext?.setb2("_mouseMove"){ (dx,dy) ->Any! in
            let ddx=dx as? Double
            let ddy=dy as? Double

            guard ddx != nil && ddy != nil else {
                _ = jsContext?.evaluateScript("throw \"bad arguments dx=\(dx ?? "undefined"), dy=\(dy ?? "undefined")\";")
                return nil
            }
            mouseMove(CGFloat(ddx!),CGFloat(ddy!))
            return nil
        }
        _ = jsContext?.evaluateScript("Mouse = { move: function(dx,dy) { _mouseMove(dx,dy) } }")
    }
    
    func backgroundThread(){
        print("starting background thread")
        jsContext?.exceptionHandler = { context, exception in
            self.log("JS Error: \(exception?.description ?? "unknown error" )")
        }
        setUpAppIntrinsicJsObjects()
        loadConfig()
        createEventTap()
    }
}
