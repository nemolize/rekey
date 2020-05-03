import Cocoa

enum AppError: Error {
    case accessibility(_ message: String, _ code: Int32? = nil)
}

func getFrontmostApplicationElement() throws -> AXUIElement {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
        throw AppError.accessibility("Failed to get process identifier of the frontmost application.")
    }

    return AXUIElementCreateApplication(pid)
}

extension AXUIElement {
    func copyAttributeValue(_ attribute: String, _ destination: UnsafeMutablePointer<CFTypeRef?>) throws {
        let result = AXUIElementCopyAttributeValue(self, attribute as CFString, destination)
        if result != AXError.success {
            throw AppError.accessibility("AXUIElementCopyAttributeValue has failed.", result.rawValue)
        }
    }

    func setAttributeValue(_ attribute: String, _ value: AXValue) throws {
        let result = AXUIElementSetAttributeValue(self, kAXPositionAttribute as CFString, value)
        if result != AXError.success {
            throw AppError.accessibility("AXUIElementSetAttributeValue has failed", result.rawValue)
        }
    }
}