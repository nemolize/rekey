import Cocoa
import Foundation

class MainWindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(window: NSWindow) -> Bool {
        window.orderOut(nil)
        return false
    }
}
