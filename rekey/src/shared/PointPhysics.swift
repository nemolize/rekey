import Foundation

class PointPhysics {
    private let queue = DispatchQueue(label: "rekey.physics.loop", qos: .userInteractive)
    private let mouseLock = NSLock()
    private var acceleration = CGPoint()
    private var velocity = CGPoint()
    private var friction: CGFloat
    private let frameIntervalBasis = 1.0 / 100
    private let onUpdate: ((_ position: CGPoint, _ velocity: CGPoint) -> Void)?

    init(friction: CGFloat? = nil, onSetPosition: @escaping (_ position: CGPoint, _ velocity: CGPoint) -> Void) {
        self.friction = friction ?? 1
        self.onUpdate = onSetPosition
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

    func setAcceleration(_ x: CGFloat, _ y: CGFloat) {
        doThreadSafely {
            self.acceleration.x = x
            self.acceleration.y = y
        }
    }

    func setFriction(_ attenuation: CGFloat) {
        doThreadSafely {
            self.friction = attenuation
        }
    }

    private func doThreadSafely(_ block: @escaping () -> Void) {
        self.mouseLock.lock()
        defer{
            self.mouseLock.unlock()
        }
        block()
    }

    private func advance(_ deltaTime: CGFloat) {
        doThreadSafely {
            // apply Acceleration v=v + at
            self.velocity += self.acceleration * deltaTime

            // apply attenuation
            let attenuationDelta = self.friction * deltaTime

            // apply attenuation to velocity
            self.velocity.x = 0 < self.velocity.x
                    ? max(self.velocity.x - attenuationDelta, 0)
                    : min(self.velocity.x + attenuationDelta, 0)
            self.velocity.y = 0 < self.velocity.y
                    ? max(self.velocity.y - attenuationDelta, 0)
                    : min(self.velocity.y + attenuationDelta, 0)

            // apply velocity to position if it moved
            let delayFixedVelocity = self.velocity * deltaTime
            if delayFixedVelocity.length() > 0 {
                let position = self.getPosition()
                self.onUpdate?(position + delayFixedVelocity, delayFixedVelocity)
            }
        }
    }
}


