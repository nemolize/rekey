import Foundation

class Mouse {
    private let mouseLock = NSLock()
    private var acceleration = CGPoint()
    private var velocity = CGPoint()
    private var friction = CGFloat(0.1)

    func getPosition() -> CGPoint { CGEvent(source: nil)!.location }

    func setPosition(_ position: CGPoint) {
        if let moveEvent = CGEvent(source: nil) {
            moveEvent.type = .mouseMoved
            moveEvent.location = position
            moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }

    func start() {
        DispatchQueue(label: "rekey.mouse.loop", qos: .userInteractive).async {
            var lastSeconds = Date().timeIntervalSince1970
            while true {
                let currentSeconds = Date().timeIntervalSince1970
                let deltaSeconds = currentSeconds - lastSeconds
                let frameIntervalBasis = 1.0 / 60

                // get frame delay for precision
                let deltaTime = CGFloat(deltaSeconds / frameIntervalBasis)

                self.advance(deltaTime)

                // save last second
                lastSeconds = Date().timeIntervalSince1970

                // wait for the next frame
                usleep(useconds_t(frameIntervalBasis * 1000 * 1000))
            }
        }
    }

    func setVelocity(_ dx: CGFloat?, _ dy: CGFloat?) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        if let val = dx { velocity.x = val }
        if let val = dy { velocity.y = val }
    }

    func setAcceleration(_ dx: CGFloat?, _ dy: CGFloat?) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        if let val = dx { acceleration.x = val }
        if let val = dy { acceleration.y = val }
    }

    func setFriction(_ attenuation: CGFloat) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }
        self.friction = attenuation
    }

    static let shared = Mouse()

    private func advance(_ deltaTime: CGFloat) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        // apply Acceleration v=v + at
        self.velocity += self.acceleration * deltaTime

        // apply attenuation
        let attenuationDelta = self.friction * deltaTime

        // apply attenuation to velocity
        self.velocity.x = (0 < self.velocity.x) ?
                max(self.velocity.x - attenuationDelta, 0) : min(self.velocity.x + attenuationDelta, 0)
        self.velocity.y = (0 < self.velocity.y) ?
                max(self.velocity.y - attenuationDelta, 0) : min(self.velocity.y + attenuationDelta, 0)

        // apply velocity to mouse position if it moved
        let delayFixedVelocity = self.velocity * deltaTime
        if (delayFixedVelocity).length() > 0 {
            let position = self.getPosition()
            self.setPosition(position + delayFixedVelocity)
        }
    }
}


