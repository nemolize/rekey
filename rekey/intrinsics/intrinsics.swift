//
//  intrinsics.swift
//  rekey
//
//  Created by nemoto on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

struct JsNames {
    static let Reload = "reload"
}

class Intrinsics {
    func makeJsObj(_ targetScope: String! = nil, _ targetObjectName: String, _ innerFunc: (String) -> Void) {
        innerFunc(targetObjectName.appJsIntrinsicName)
        let prefix = targetScope != nil ? "\(targetScope!)." : ""
        _ = jsContext?.evaluateScript("\(prefix)\(targetObjectName)=\(targetObjectName.appJsIntrinsicName)")
    }

    func getValue<T>(_ target: Any!) -> T? {
        guard target is T? else { return nil }
        return target as! T?
    }

    private func setUpConsole() {
        jsContext?.setb1("_consoleLog") { (arg0) -> Any! in
            postLog("\(arg0 ?? "undefined")")
            return nil
        }
        _ = jsContext?.evaluateScript("console = { log: function() { for (var i = 0; i < arguments.length; i++) { _consoleLog(arguments[i]); }} }")
    }

    private func setUpSystemFuncs() {
        makeJsObj(nil, JsNames.Reload, { name in
            jsContext?.setb0(name, {
                NotificationCenter.postReload();
                return nil
            })
        })
    }


    private func setUpModifier() {
        _ = jsContext?.evaluateScript("getModifierFlags = function() { return \(Constants.flagsJsVarName)}")
        jsContext?.setb1(Constants.emitFlagsChangeJsFunctionNameInternal) { arg1 -> Any! in

            guard let options: NSDictionary = self.getValue(arg1) else {
                _ = jsContext?.evaluateScript("throw Error('argument must be an object')")
                return nil
            }

            let flags = options["flags"]
            jsContext?.store(Constants.flagsJsVarName, flags)

            guard let evSrc = CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                _ = jsContext?.evaluateScript("throw Error('failed to create CGEventSource')")
                return nil
            }
            evSrc.userData = Constants.magicValue

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

    func setUpAppIntrinsicJsObjects() {
        setUpConsole()
        setUpSystemFuncs()
        setUpKey()
        setUpModifier()
        setUpMouse()

        _ = jsContext?.evaluateScript("\(JsNames.onFlagsChanged) = function(key, flags, isRepeat, isUp, isSysKey, keyboardType){ \(Constants.emitFlagsChangeJsFunctionNameInternal)({ flags: flags, keyboardType: keyboardType}) }")
        _ = jsContext?.evaluateScript("\(JsNames.onKey) = function(key, flags, isRepeat, isUp, isSysKey, keyboardType){ Key.\(JsNames.emit)( key, { isUp: isUp, keyboardType: keyboardType}) }")
    }


}

