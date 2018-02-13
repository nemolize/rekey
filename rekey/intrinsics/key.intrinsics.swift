extension JsNames {
    static let emit = "emit"
    static let onKey = "onKey"
    static let onFlagsChanged = "onFlagsChanged"
    static let onSysKey = "onSysKey"
}

extension Intrinsics {
    func setUpKey() {
        _ = jsContext?.evaluateScript("Key = {}")
        makeJsObj("Key", JsNames.emit, { name in
            jsContext?.setb2(name) { (arg0, arg1) -> Any! in

                guard let cgKeyCode = arg0 as! UInt16? else { return jsContext?.evaluateScript("throw 'invalid arguments'") }

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
                    if let keyboardType: NSNumber = self.getValue(options.value(forKey: "keyboardType")) {
                        evSrc.keyboardType = CGEventSourceKeyboardType(keyboardType)
                    }
                    // emit single if "isUp" is not specified
                    if let isUp: Bool = self.getValue(options.value(forKey: "isUp")) {
                        if let ev = CGEvent(keyboardEventSource: evSrc, virtualKey: cgKeyCode, keyDown: !isUp) {
                            ev.flags = getFlagsFromOptionsDict(options) ?? getCurrentModifierFlags()
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                        }
                    } else { // emit down , up if "isUp" is not specified
                        if let ev = CGEvent(keyboardEventSource: evSrc, virtualKey: cgKeyCode, keyDown: true) {
                            ev.flags = getFlagsFromOptionsDict(options) ?? getCurrentModifierFlags()
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                            ev.type = CGEventType.keyUp
                            ev.post(tap: CGEventTapLocation.cghidEventTap)
                        }
                    }
                } else {  // emit down , up with current modifier flags if options is not specified
                    if let ev = CGEvent(keyboardEventSource: evSrc, virtualKey: cgKeyCode, keyDown: true) {
                        ev.flags = getCurrentModifierFlags()
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                        ev.type = CGEventType.keyUp
                        ev.post(tap: CGEventTapLocation.cghidEventTap)
                    }
                }
                return nil
            }
        })
    }

}