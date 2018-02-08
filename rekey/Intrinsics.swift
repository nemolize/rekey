//
//  Intrinsics.swift
//  rekey
//
//  Created by nemopvt on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

class Intrinsics {
    
    private func setUpConsole(){
        jsContext?.setb1("_consoleLog") { (arg0)->Any! in
            postLog("\( arg0 ?? "undefined" )")
            return nil
        }
        _ = jsContext?.evaluateScript("console = { log: function() { for (var i = 0; i < arguments.length; i++) { _consoleLog(arguments[i]); }} }")
    }
    
    private func setUpKey(){
        jsContext?.setb2("_emitKeyEvent") { (arg0,arg1)->Any! in

            guard let cgKeyCode = arg0 as! UInt16? else {
                return jsContext?.evaluateScript("throw 'invalid arguments'")
            }
            
            guard let evSrc=CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                postLog("failed to create CGEventSource")
                return nil
            }
            evSrc.userData=Constants.magicValue

            func getValue<T>(_ target: Any!) -> T? {
                guard target is T? else {
                    return nil
                }
                return target as! T?
            }
            
            func getFlagsFromOptionsDict(_ options: NSDictionary?) -> CGEventFlags? {
                guard let flags: NSNumber = getValue(options?.value(forKey: "flags")) else {
                    return nil
                }
                return CGEventFlags(rawValue: flags.uint64Value)
            }

            if let options : NSDictionary = getValue(arg1) {
                
                // emit single if "isUp" is not specified
                if let isUp : Bool = getValue(options.value(forKey: "isUp")){

                    if let ev = CGEvent(
                        keyboardEventSource: evSrc,
                        virtualKey: cgKeyCode,
                        keyDown: !isUp
                        )
                    {
                        ev.flags = getFlagsFromOptionsDict(options) ?? CGEventFlags(rawValue: jsContext?.fetch("_flags").toNumber() as! UInt64)
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                    }
                } else { // emit down , up if "isUp" is not specified
                    if let ev = CGEvent(
                        keyboardEventSource: evSrc,
                        virtualKey: cgKeyCode,
                        keyDown: true
                        )
                    {
                        ev.flags = getFlagsFromOptionsDict(options) ?? CGEventFlags(rawValue: jsContext?.fetch("_flags").toNumber() as! UInt64)
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                        ev.type=CGEventType.keyUp
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                    }
                }
            } else {  // emit down , up with current modifier flags if options is not specified
                if let ev = CGEvent(
                    keyboardEventSource: evSrc,
                    virtualKey: cgKeyCode,
                    keyDown: true
                    )
                {
                    ev.flags = CGEventFlags(rawValue: jsContext?.fetch("_flags").toNumber() as! UInt64)
                    ev.post(tap: CGEventTapLocation.cghidEventTap)
                    ev.type=CGEventType.keyUp
                    ev.post(tap: CGEventTapLocation.cghidEventTap)
                }
            }
            return nil
        }
        _ = jsContext?.evaluateScript("Key = {}")
        _ = jsContext?.evaluateScript("Key.emit = function(keyCode,options) { _emitKeyEvent(keyCode, options) }")
    }

    private func setUpModifier(){
        jsContext?.setb0("getModifierFlags") { ()->Any! in
            return modifierFlags.rawValue
        }
        jsContext?.evaluateScript("var _flags;")
    }
    
    private func setUpMouse(){
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
                else { postLog("failed to post the event"); return }
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
    
    func setUpAppIntrinsicJsObjects(){
        setUpConsole()
        setUpKey()
        setUpModifier()
        setUpMouse()

        _ = jsContext?.evaluateScript("onFlagsChanged = function(key, flags, isRepeat, isUp, isSysKey){ _flags=flags; }")
        _ = jsContext?.evaluateScript("onKey = function(key, flags, isRepeat, isUp, isSysKey){ Key.emit( key,{isUp: isUp}) }")
    }
    
    
}

