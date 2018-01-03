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
        setUpMouse()
    }
    
    
}

