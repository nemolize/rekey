//
//  intrinsics.swift
//  rekey
//
//  Created by nemoto on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

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
        makeJsObj(nil, JsNames.System.Reload.rawValue, { name in
            jsContext?.setb0(name, {
                NotificationCenter.postReload();
                return nil
            })
        })
    }

    func setUpAppIntrinsicJsObjects() {
        setUpConsole()
        setUpSystemFuncs()
        setUpKey()
        setUpMouse()

        _ = jsContext?.evaluateScript("\(JsNames.Key.onFlagsChanged) = function(key, flags, isRepeat, isUp, isSysKey, keyboardType){ \(Constants.emitFlagsChangeJsFunctionName.appJsIntrinsicName)({ flags: flags, keyboardType: keyboardType}) }")
        _ = jsContext?.evaluateScript("\(JsNames.Key.onKey) = function(key, flags, isRepeat, isUp, isSysKey, keyboardType){ Key.\(JsNames.Key.emit.rawValue)( key, { isUp: isUp, keyboardType: keyboardType}) }")
    }
}

