//
//  ViewController.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa
import Foundation

import JavaScriptCore

let executionLock = NSLock()
let jsContext = JSContext()
let center = NotificationCenter.default
extension Notification.Name {
    static let appendLog = Notification.Name("appendLog")
}



func onKeyEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>?{
    
    if [.keyDown , .keyUp].contains(type) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        let isUp=type == .keyDown
        
        executionLock.lock()
        defer{executionLock.unlock()}
        
        // call js code
        if let mainFunc = jsContext?.objectForKeyedSubscript("main"){
            if !mainFunc.isUndefined{
            mainFunc.call(withArguments: [keyCode,isUp])
            }
//            let result = mainFunc.call(withArguments: [keyCode,isUp])!
//            center.post(name: .appendLog, object: result ?? "undefined")
        }
        
        switch(keyCode){
        //a to z
//        case 0:
//            event.setIntegerValueField(.keyboardEventKeycode, value: 6)
            //        //z to a
            //cancel c
            //        case 8:
        //            return nil
        case 0: // only modifier
            if event.flags.contains(.maskCommand){
                
                func getCurrentMouseLocation()-> CGPoint {
                    
                    return CGEvent(source:nil)!.location
                }
                
                var point=getCurrentMouseLocation()
                
                point.x+=1
                
                guard let moveEvent = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .mouseMoved,
                    mouseCursorPosition: point,
                    mouseButton: .left
                    )
                    else {
                        return nil
                }
                moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
                
                return nil
            }
            break
        default:
            break
        }
    }
    else if [.flagsChanged].contains(type){
        print(String(format: "flags %@", String(event.flags.rawValue,radix:2)))
    }
    
    return Unmanaged.passUnretained(event)
}


class ViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var label: NSTextField!
    @IBOutlet var jsTextInput: NSTextView!
    @IBOutlet var logLabel: NSTextView!
    
    var isShiftKeyPressed=false
        var isCommandPressed=false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        jsTextInput.isAutomaticQuoteSubstitutionEnabled=false
        jsTextInput.isAutomaticSpellingCorrectionEnabled=false
        jsTextInput.isContinuousSpellCheckingEnabled=false
       
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            return $0
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
        
        // キューを生成してサブスレッドで実行
        DispatchQueue(label: "com.nemoto.app.queue").async {
            self.backgroundThread()
        }
        
        center.addObserver(forName: .appendLog,
                           object: nil,
                           queue: nil,
                           using: notified)
    }
    
    /** C: 今回、通知された時に呼ばれる用のメソッド */
    private func notified(notification: Notification) {
        guard notification.object != nil else {
            print("notification object is nil")
            return
        }

            let msg="\( notification.object ?? "undefined" )"
            DispatchQueue.main.async {
                self.log(msg)
            }
    }
    
    func log(_ message: String?){
        if message == nil { return }

        logLabel.string?.append("\(message!)\n")
        logLabel.scrollToEndOfDocument(nil)
    }
    
    override func keyDown(with event: NSEvent) {
    
        guard self.isCommandPressed else { return }
        guard event.keyCode == Keycode.Enter else { return }
        defer {
            jsTextInput.string=""
        }
        
        guard let jsSource=jsTextInput.string?.trimmingCharacters(in: ["\n","\t"," "]) else { return }
        guard !jsSource.isEmpty else { return }

        
        executionLock.lock()
        defer{executionLock.unlock()}
        jsContext!.evaluateScript(jsSource)
        jsTextInput.string?=""
        log(jsSource)
    }
    
    override func flagsChanged(with event: NSEvent) {
        isShiftKeyPressed=event.modifierFlags.contains(NSShiftKeyMask)
        isCommandPressed=event.modifierFlags.contains(NSCommandKeyMask)
    }

    
    func backgroundThread(){
        // Do any additional setup after loading the view.
        print("creating js engine")
        
        // get the home path directory
        let homeDir = NSHomeDirectory()
        
        print("starting background thread")
        // load javascript file in String

        jsContext?.exceptionHandler = { context, exception in
            center.post(name: .appendLog, object: "JS Error: \(exception?.description ?? "unknown error")")
        }
        
        let confPath=homeDir+"/.config/rekey.js"
        
        if FileManager.default.fileExists(atPath: confPath){
            if let jsSource = try? String(contentsOfFile: confPath){
                jsContext!.evaluateScript(jsSource)
            }else{
                center.post(name: .appendLog, object: String(format:"failed to load %@",confPath))
            }
        } else {
            center.post(name: .appendLog, object: String(format:"user config file does not exist. %@",confPath))
        }

        let eventMask = (1<<CGEventType.flagsChanged.rawValue)|(1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: onKeyEvent,
                                               userInfo: nil) else {
                                                print("failed to create event tap")
                                                exit(1)
        }
    
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
