//
//  Intrinsics.swift
//  rekey
//
//  Created by nemoto on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

class Intrinsics {

    private func getValue<T>(_ target: Any!) -> T? {
        guard target is T? else { return nil }
        return target as! T?
    }

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
            
            func getFlagsFromOptionsDict(_ options: NSDictionary?) -> CGEventFlags? {
                guard let flags: NSNumber = self.getValue(options?.value(forKey: "flags")) else {
                    return nil
                }
                return CGEventFlags(rawValue: flags.uint64Value)
            }

            if let options : NSDictionary = self.getValue(arg1) {
                
                // emit single if "isUp" is not specified
                if let isUp : Bool = self.getValue(options.value(forKey: "isUp")){

                    if let ev = CGEvent(
                        keyboardEventSource: evSrc,
                        virtualKey: cgKeyCode,
                        keyDown: !isUp
                        )
                    {
                        ev.flags = getFlagsFromOptionsDict(options) ??
                                CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                    }
                } else { // emit down , up if "isUp" is not specified
                    if let ev = CGEvent(
                        keyboardEventSource: evSrc,
                        virtualKey: cgKeyCode,
                        keyDown: true
                        )
                    {
                        ev.flags = getFlagsFromOptionsDict(options)
                                ?? CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
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
                    ev.flags = CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
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
        _ = jsContext?.evaluateScript("getModifierFlags = function() { return \(Constants.flagsJsVarName)}")
        jsContext?.setb1(Constants.emitFlagsChangeJsFunctionNameInternal) { arg1->Any! in

            guard let options: NSDictionary = self.getValue(arg1) else {
                _ = jsContext?.evaluateScript("throw Error('argument must be an object')")
                return nil
            }

            let flags = options["flags"]
            jsContext?.store(Constants.flagsJsVarName, flags)

            guard let evSrc=CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                _ = jsContext?.evaluateScript("throw Error('failed to create CGEventSource')")
                return nil
            }
            evSrc.userData=Constants.magicValue

            if let ev = CGEvent(source: evSrc) {
                ev.flags = CGEventFlags(rawValue: flags as! UInt64)
                ev.type = CGEventType.flagsChanged
                ev.post(tap: CGEventTapLocation.cghidEventTap)
            }
            return nil
        }
        _ = jsContext?.evaluateScript("Key.\(Constants.emitFlagsChangeJsFunctionName)=\(Constants.emitFlagsChangeJsFunctionNameInternal)")
        _ = jsContext?.evaluateScript("var \(Constants.flagsJsVarName)=256;")
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

        _ = jsContext?.evaluateScript("onFlagsChanged = function(key, flags, isRepeat, isUp, isSysKey){ \(Constants.emitFlagsChangeJsFunctionNameInternal)({flags: flags}) }")
        _ = jsContext?.evaluateScript("onKey = function(key, flags, isRepeat, isUp, isSysKey){ Key.emit( key,{isUp: isUp}) }")
    }
    
    
}

