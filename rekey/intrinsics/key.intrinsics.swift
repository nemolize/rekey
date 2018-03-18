extension JsNames {
    enum Key: String {
        case emit
        case onKey
        case onFlagsChanged
        case onSysKey
    }
}

extension Intrinsics {
    func setUpKey() {
        _ = jsContext?.evaluateScript("Key = {}")
        makeJsObj("Key", JsNames.Key.emit.rawValue, { name in
            jsContext?.setb2(name) { (arg0, arg1) -> Any! in

                guard let cgKeyCode = arg0 as! UInt16? else { return jsContext?.throwError("invalid arguments") }

                guard let evSrc = CGEventSource(stateID: CGEventSourceStateID.privateState) else {
                    return jsContext?.throwError("failed to create CGEventSource")
                }
                evSrc.userData = Constants.magicValue

                let options = arg1 as? NSDictionary

                if let keyboardType = options?.value(forKey: "keyboardType") as? NSNumber {
                    evSrc.keyboardType = CGEventSourceKeyboardType(keyboardType)
                }

                guard let ev = CGEvent(keyboardEventSource: evSrc, virtualKey: cgKeyCode, keyDown: true) else {
                    return jsContext?.throwError("Failed to instantiate CGEvent")
                }

                if let flagsInOption = options?.value(forKey: "flags") as? UInt64 {
                    ev.flags = CGEventFlags(rawValue: flagsInOption)
                } else {
                    ev.flags = getCurrentModifierFlags()
                }

                if let isUp = options?.value(forKey: "isUp") as? Bool {
                    ev.type = isUp ? .keyUp : .keyDown
                    ev.post(tap: CGEventTapLocation.cghidEventTap)
                } else {
                    ev.post(tap: CGEventTapLocation.cghidEventTap)
                    ev.type = CGEventType.keyUp
                    ev.post(tap: CGEventTapLocation.cghidEventTap)
                }
                return nil
            }
        })
    }

}