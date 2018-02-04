import Cocoa

func onKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    if (event.getIntegerValueField(CGEventField.eventSourceUserData) == Constants.magicValue) {
        return Unmanaged.passUnretained(event)
    }

    // queue processing worker thread
    DispatchQueue(label: Constants.processQueueName).async {

        // syskey
        if type.rawValue == UInt32(NX_SYSDEFINED) {
            if let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 {
                let keyCode = (nsEvent.data1 & 0xffff0000) >> 16
                let isUp = ((nsEvent.data1 & 0xff00) >> 8) != 0xa
                let isRepeat = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)

                executionLock.lock()
                defer{ executionLock.unlock() }

                // call js code
                if let mainFunc = jsContext?.objectForKeyedSubscript("onSysKey") {
                    if !mainFunc.isUndefined {
                        let result = mainFunc.call(withArguments: [keyCode,
                                                                   event.flags.rawValue,
                                                                   isRepeat,
                                                                   isUp,
                                                                   true])
                        if (result?.isBoolean)! && (result?.toBool())! {
                            return
                        }
                    }
                }
            }
        }

        if [.keyDown, .keyUp].contains(type) {
            let keyCode: Int64 = event.getIntegerValueField(.keyboardEventKeycode)
            let isUp: Bool = type == .keyUp
            let isRepeat: Int64 = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)

            executionLock.lock()
            defer{ executionLock.unlock() }

            // call js code
            if let mainFunc = jsContext?.objectForKeyedSubscript("onKey") {
                if !mainFunc.isUndefined {
                    let result = mainFunc.call(
                            withArguments: [
                                keyCode,
                                event.flags.rawValue,
                                isRepeat,
                                isUp,
                                false
                            ])

                    if (result?.isBoolean)! && (result?.toBool())! { return }
                }
            }
        } else if [.flagsChanged].contains(type) { // on flags changed
            modifierFlags = event.flags
        }

        let keyCode: Int64 = event.getIntegerValueField(.keyboardEventKeycode)
        let isUp: Bool = type == .keyUp
        let isRepeat: Int64 = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)

        executionLock.lock()
        defer{ executionLock.unlock() }

        _ = jsContext?.evaluateScript("var flags=\(event.flags.rawValue)")

        // call js code
        if let mainFunc = jsContext?.objectForKeyedSubscript("onFlagsChanged") {
            if !mainFunc.isUndefined {
                let result = mainFunc.call(withArguments: [keyCode,
                                                           event.flags.rawValue,
                                                           isRepeat,
                                                           isUp,
                                                           false])
                if (result?.isBoolean)! && (result?.toBool())! { return }
            }
        }
    }

    return Unmanaged.passUnretained(event)
}