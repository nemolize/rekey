import Cocoa

class WindowService {
    func moveWindow(_ velocity: CGPoint) {
        do {
            let appRef = try getFrontmostApplicationElement()

            var windowRef: AnyObject?
            try appRef.copyAttributeValue(kAXFocusedWindowAttribute, &windowRef)
            let windowElement: AXUIElement = windowRef as! AXUIElement

            var positionRef: CFTypeRef?
            try windowElement.copyAttributeValue(kAXPositionAttribute, &positionRef)

            var position = CGPoint()
            if !AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &position) {
                throw AppError.accessibility("AXValueGetValue has failed")
            }

            position += velocity

            if let positionAxValue = AXValueCreate(AXValueType.cgPoint, &position) {
                try windowElement.setAttributeValue(kAXPositionAttribute, positionAxValue)
            }

        } catch AppError.accessibility(let message, let code) {
            debugPrint(message, code ?? "none")
        } catch {
            debugPrint("Unknown error has occurred.")
        }
    }

    static let shared = WindowService()
}
