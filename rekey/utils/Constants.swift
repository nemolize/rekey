//
//  Constants.swift
//  rekey
//
//  Created by nemopvt on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

struct Constants {
    static let magicValue: Int64=0xfedcba
    static let httpServerQueueName = "rekey.app.httpserver"
    static let captureEventQueueName = "rekey.app.capture.eventtap"
    static let processQueueName = "rekey.app.queue.process"
    static let configFilePathUnderHomeDirectory = "/.config/rekey/onstart.js"
    static let flagsJsVarName = "_rekey_internal_flags_"
    static let emitFlagsChangeJsFunctionName="emitFlagsChange"
    static let emitFlagsChangeJsFunctionNameInternal="_rekey_internal_emitFlagsChange_"
}
