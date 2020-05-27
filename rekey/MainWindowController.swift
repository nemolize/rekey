import Cocoa
import Foundation

func setBackgroundProcessMode(_ isBackground: Bool) {
    let transformState = ProcessApplicationTransformState(
        isBackground
            ? kProcessTransformToUIElementApplication
            : kProcessTransformToForegroundApplication
    )

    var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    TransformProcessType(&psn, transformState)
}

class MainWindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_: NSWindow) -> Bool {
        window?.orderOut(nil)
        setBackgroundProcessMode(true)
        return false
    }
}
