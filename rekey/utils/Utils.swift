//
//  Utils.swift
//  rekey
//
//  Created by nemopvt on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let appendLog = Notification.Name("appendLog")
    static let executeJs = Notification.Name("executeJs")
    static let compileAndExecuteJs = Notification.Name("compileAndExecuteJs")
    static let reload = Notification.Name("reload")
}

func postLog(_ msg: String!) {
    NotificationCenter.default.post(name: .appendLog, object: "\(msg ?? "")")
}

extension NotificationCenter {
    static func postExecuteJS(_ jsSrc: String) {
        NotificationCenter.default.post(name: .compileAndExecuteJs, object: jsSrc)
    }

    static func postReload() {
        NotificationCenter.default.post(name: .reload, object: nil)
    }
}

extension JSContext {
    func throwError(_ message: String) {
        _ = self.evaluateScript("throw new Error(\"\(message)\")")
    }
}