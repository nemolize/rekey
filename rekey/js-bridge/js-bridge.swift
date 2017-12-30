//
//  js-bridge.swift
//  rekey
//
//  Created by mnemoto on 2017/12/30.
//  Copyright © 2017年 nemoto. All rights reserved.
//  Thanks @dankogai (js-Bridging-Header.h, jsc.m):
//    https://qiita.com/dankogai/items/052a3ad6f32d114a33fc
//    https://github.com/dankogai/swift-jsdemo

import Foundation

// js value accessor.
typealias ID = Any!
extension JSContext {
    func fetch(_ key:String)->JSValue {
        return getJSVinJSC(self, key)
    }
    func store(_ key:String, _ val:ID) {
        setJSVinJSC(self, key, val)
    }
    // Yikes.  Swift 1.2 and its JavaScriptCore no longer allows method overloding by type
    func setb0(_ key:String, _ blk:@escaping ()->ID) {
        setB0JSVinJSC(self, key, blk)
    }
    func setb1(_ key:String, _ blk:@escaping (ID)->ID) {
        setB1JSVinJSC(self, key, blk)
    }
    func setb2(_ key:String, _ blk:@escaping (ID,ID)->ID) {
        setB2JSVinJSC(self, key, blk)
    }
}
