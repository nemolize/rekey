import Cocoa
import Foundation

class MainWindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}
