//
//  intrinsics.swift
//  rekey
//
//  Created by nemoto on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

class Intrinsics {

    struct JsNames {
        static let Reload = "reload"
        static let emit = "emit"
    }

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

    private func setUpKey() {
        _ = jsContext?.evaluateScript("Key = {}")
        makeJsObj("Key", JsNames.emit, { name in
            jsContext?.setb2(name) { (arg0, arg1) -> Any! in

                guard let cgKeyCode = arg0 as! UInt16? else {
                    return jsContext?.evaluateScript("throw 'invalid arguments'")
                }

                guard let evSrc = CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                    postLog("failed to create CGEventSource");
                    return nil
                }
                evSrc.userData = Constants.magicValue

                func getFlagsFromOptionsDict(_ options: NSDictionary?) -> CGEventFlags? {
                    guard let flags: NSNumber = self.getValue(options?.value(forKey: "flags")) else {
                        return nil
                    }
                    return CGEventFlags(rawValue: flags.uint64Value)
                }

                if let options: NSDictionary = self.getValue(arg1) {

                    // emit single if "isUp" is not specified
                    if let isUp: Bool = self.getValue(options.value(forKey: "isUp")) {

                        if let ev = CGEvent(
                                keyboardEventSource: evSrc,
                                virtualKey: cgKeyCode,
                                keyDown: !isUp
                        ) {
                            ev.flags = getFlagsFromOptionsDict(options) ??
                                    CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                        }
                    } else { // emit down , up if "isUp" is not specified
                        if let ev = CGEvent(
                                keyboardEventSource: evSrc,
                                virtualKey: cgKeyCode,
                                keyDown: true
                        ) {
                            ev.flags = getFlagsFromOptionsDict(options)
                                    ?? CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                            ev.type = CGEventType.keyUp
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                        }
                    }
                } else {  // emit down , up with current modifier flags if options is not specified
                    if let ev = CGEvent(
                            keyboardEventSource: evSrc,
                            virtualKey: cgKeyCode,
                            keyDown: true
                    ) {
                        ev.flags = CGEventFlags(rawValue: jsContext?.fetch(Constants.flagsJsVarName).toNumber() as! UInt64)
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                        ev.type = CGEventType.keyUp
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                    }
                }
                return nil
            }
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

        _ = jsContext?.evaluateScript("onFlagsChanged = function(key, flags, isRepeat, isUp, isSysKey){ \(Constants.emitFlagsChangeJsFunctionNameInternal)({flags: flags}) }")
        _ = jsContext?.evaluateScript("onKey = function(key, flags, isRepeat, isUp, isSysKey){ Key.\(JsNames.emit)( key,{isUp: isUp}) }")
    }


}
