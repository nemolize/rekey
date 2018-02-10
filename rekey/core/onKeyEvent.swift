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
        let keyCode: Int64 = event.getIntegerValueField(.keyboardEventKeycode)
        let isUp: Bool = type == .keyUp
        let isRepeat: Int64 = event.getIntegerValueField(CGEventField.keyboardEventAutorepeat)

        executionLock.lock()
        defer{ executionLock.unlock() }

        switch (type.rawValue) {
        case UInt32(NX_SYSDEFINED):
            if let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 {
                let keyCode = (nsEvent.data1 & 0xffff0000) >> 16
                let isUp = ((nsEvent.data1 & 0xff00) >> 8) != 0xa
                _ = jsContext?.fetch("onSysKey").call(withArguments: [keyCode, event.flags.rawValue, isRepeat, isUp, true])
            }
            break;
        case CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue:
            _ = jsContext?.fetch("onKey").call(withArguments: [keyCode, event.flags.rawValue, isRepeat, isUp, false])
            break;
        case CGEventType.flagsChanged.rawValue:
            _ = jsContext?.fetch("onFlagsChanged").call(withArguments: [keyCode, event.flags.rawValue, isRepeat, isUp, false])
            break;
        default:
            print("unknown type \(type)")
        }
    }
    return nil
}