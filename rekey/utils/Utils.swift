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
}

func postLog(_ msg : String!){
    NotificationCenter.default.post(name: .appendLog, object: "\(msg ?? "")")
}
