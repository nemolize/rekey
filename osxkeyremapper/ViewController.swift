//
//  ViewController.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa
import Foundation

import JavaScriptCore

let lock = NSLock()
var jsContext = JSContext()

func onKeyEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>?{
    
    if [.keyDown , .keyUp].contains(type) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        let isUp=type == .keyDown
        
        lock.lock()
        defer{lock.unlock()}
        
        // call js code
        if let mainFunc = jsContext?.objectForKeyedSubscript("main"){
            if let helloValue = mainFunc.call(withArguments: [keyCode,isUp]){
                if helloValue.isNumber{
                    event.setIntegerValueField(.keyboardEventKeycode, value: Int64(helloValue.toInt32()))
                }else{
                    print("the returned value of main is ",helloValue)
                }
            }else{
                print("the returned value does not exist")
            }
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
//            print("the key is \(event.getIntegerValueField(.keyboardEventKeycode))")
//            print("command key flag = \(event.flags.contains(CGEventFlags.maskCommand))")
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

    var isShiftKeyPressed=false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        jsTextInput.delegate=self
        
        // キューを生成してサブスレッドで実行
        DispatchQueue(label: "com.nemoto.app.queue").async {
            self.backgroundThread()
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if event.keyCode==36 && !isShiftKeyPressed{
            let jsSource = jsTextInput.string!
            lock.lock()
            defer{lock.unlock()}

            let testString = jsSource
            let somedata = testString.data(using: String.Encoding.utf16)
            _ = String(data: somedata!, encoding: String.Encoding.utf16) as String!

            jsContext!.evaluateScript(testString)
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        self.isShiftKeyPressed=event.modifierFlags.contains(NSShiftKeyMask)
    }

    
    func backgroundThread(){
        // Do any additional setup after loading the view.
        print("creating js engine")
        
        // get the home path directory
        let homeDir = NSHomeDirectory()
        
        print("starting background thread")
        // load javascript file in String

        let confPath=homeDir+"/.config/rekey.js"
        if let jsSource = try? String(contentsOfFile: confPath){
            jsContext!.evaluateScript(jsSource)
        }else{
            print(String(format:"failed to load %@",confPath))
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

