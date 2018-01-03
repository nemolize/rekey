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
        }
        _ = jsContext?.evaluateScript("console = { log: function() { for (var i = 0; i < arguments.length; i++) { _consoleLog(arguments[i]); }} }")
    }
    
    private func setUpKey(){
        
//        let evCmdDown=CGEvent(keyboardEventSource: evSrc,virtualKey: 0x37, keyDown: true)
//        evCmdDown?.flags = CGEventFlags.maskCommand
//        evs.append(evCmdDown!)
//        
//        let evCmdUp=CGEvent(keyboardEventSource: evSrc,virtualKey: 0x37, keyDown: false)
//        evs.append(evCmdUp!)
        
        jsContext?.setb1("_emitKeyDownUpEvent") { (cgKeyCode)->Any! in
            
            var evs=[CGEvent]()
            
            let evSrc=CGEventSource(stateID: CGEventSourceStateID.privateState)
            evSrc?.userData=Constants.magicValue
            
            if let down = CGEvent(keyboardEventSource: evSrc,virtualKey: cgKeyCode as! UInt16, keyDown: true) {
                evs.append(down)
            }
            
            for ev in evs {
                ev.post(tap: CGEventTapLocation.cghidEventTap)
            }
            return nil
        }
        jsContext?.setb2("_emitKeyEvent") { (cgKeyCode,isUp)->Any! in

            guard let evSrc=CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                postLog("failed to create CGEventSource")
                return nil
            }
            evSrc.userData=Constants.magicValue
            
            if let ev = CGEvent(
                keyboardEventSource: evSrc,
                virtualKey: cgKeyCode as! UInt16,
                keyDown: !(isUp as! Bool)) {
                ev.post(tap: CGEventTapLocation.cghidEventTap)
            }
            return nil
        }
        _ = jsContext?.evaluateScript("Key = {}")
        _ = jsContext?.evaluateScript("Key.downUp = function(keyCode) { _emitKeyDownUpEvent(keyCode) }")
        _ = jsContext?.evaluateScript("Key.emit = function(keyCode,isUp) { _emitKeyEvent(keyCode, isUp) }")
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
        setUpMouse()
    }
    
    
}

