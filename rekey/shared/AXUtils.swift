import Cocoa

private var pidAppRefCache: (pid: pid_t, appRef: AXUIElement)?

func getFrontmostApplicationElement() throws -> AXUIElement {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
        throw AppError.accessibility("Failed to get process identifier of the frontmost application.")
    }

    // NOTE: use last appRef if pid is not changed
    if let pidAppRefCache = pidAppRefCache, pidAppRefCache.pid == pid {
        return pidAppRefCache.appRef
    }

    let appRef = AXUIElementCreateApplication(pid)
    pidAppRefCache = (pid, appRef) // NOTE: update cache

    return appRef
}

extension AXUIElement {
    func copyAttributeValue(_ attribute: String, _ destination: UnsafeMutablePointer<CFTypeRef?>) throws {
        let result = AXUIElementCopyAttributeValue(self, attribute as CFString, destination)
        if result != AXError.success {
            throw AppError.accessibility("AXUIElementCopyAttributeValue has failed.", result.rawValue)
        }
    }

    func setAttributeValue(_ attribute: String, _ value: AXValue) throws {
        let result = AXUIElementSetAttributeValue(self, attribute as CFString, value)
        if result != AXError.success {
            throw AppError.accessibility("AXUIElementSetAttributeValue has failed", result.rawValue)
        }
    }
}
