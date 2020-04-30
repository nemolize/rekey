import Foundation

class PointPhysics {
    let queue = DispatchQueue(label: "rekey.physics.loop", qos: .userInteractive)
    private let mouseLock = NSLock()
    private var acceleration = CGPoint()
    private var velocity = CGPoint()
    private var friction: CGFloat
    private let frameIntervalBasis = 1.0 / 100

    init(friction: CGFloat? = nil) {
        self.friction = friction ?? 1
    }

    func getPosition() -> CGPoint {
        CGEvent(source: nil)!.location
    }

    func setPosition(_ position: CGPoint) {
        if let moveEvent = CGEvent(source: nil) {
            moveEvent.type = .mouseMoved
            moveEvent.location = position
            moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }

    func start() {
        queue.async {
            var lastSeconds = Date().timeIntervalSince1970
            while true {
                let currentSeconds = Date().timeIntervalSince1970
                let deltaSeconds = currentSeconds - lastSeconds
                let deltaTime = CGFloat(deltaSeconds / self.frameIntervalBasis) // get frame delay for precision

                self.advance(deltaTime)

                lastSeconds = Date().timeIntervalSince1970 // save last second
                usleep(useconds_t(self.frameIntervalBasis * 1000 * 1000)) // wait for the next frame
            }
        }
    }

    func setVelocity(_ dx: CGFloat?, _ dy: CGFloat?) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        if let val = dx { velocity.x = val }
        if let val = dy { velocity.y = val }
    }

    func setAcceleration(_ x: CGFloat?, _ y: CGFloat?) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        if let val = x { acceleration.x = val }
        if let val = y { acceleration.y = val }
    }

    func getFriction() -> CGFloat {
        self.friction
    }

    func setFriction(_ attenuation: CGFloat) {
        self.mouseLock.lock()
        defer{
            self.mouseLock.unlock()
        }
        self.friction = attenuation
    }

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


