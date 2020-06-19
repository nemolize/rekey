import Foundation

class PointPhysics {
    private let queue = DispatchQueue(label: "rekey.physics.loop", qos: .userInteractive)
    private let mouseLock = NSLock()
    private var acceleration = CGPoint()
    private var velocity = CGPoint()
    private var friction: CGFloat
    private let frameInterval = 1.0 / 60.0
    private let onUpdate: ((_ position: CGPoint, _ velocity: CGPoint) -> Void)?

    init(friction: CGFloat? = nil, onUpdate: @escaping (_ position: CGPoint, _ velocity: CGPoint) -> Void) {
        self.friction = friction ?? 1
        self.onUpdate = onUpdate
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

    private var running = false

    func start() {
        queue.async {
            self.running = true
            defer { self.running = false }
            var lastDate: Date
            repeat {
                lastDate = Date()
                if -lastDate.timeIntervalSinceNow < self.frameInterval {
                    let diffSeconds = self.frameInterval + lastDate.timeIntervalSinceNow
                    usleep(useconds_t(diffSeconds * 1000 * 1000))
                }
            } while self.advance(CGFloat(-lastDate.timeIntervalSinceNow))
        }
    }

    func setAcceleration(_ acceleration: CGPoint) {
        doThreadSafely {
            self.acceleration.x = acceleration.x
            self.acceleration.y = acceleration.y
        }
        if !running { start() }
    }

    func setFriction(_ attenuation: CGFloat) {
        doThreadSafely {
            self.friction = attenuation
        }
        if !running { start() }
    }

    private func doThreadSafely<T>(_ block: () -> T) -> T {
        mouseLock.lock()
        defer { self.mouseLock.unlock() }
        return block()
    }

    private func advance(_ deltaTime: CGFloat) -> Bool {
        doThreadSafely {
            // apply Acceleration v=v + at
            self.velocity += self.acceleration * deltaTime

            // apply attenuation
            let attenuationDelta = self.friction * deltaTime

            // apply attenuation to velocity
            self.velocity.x = self.velocity.x > 0
                ? max(self.velocity.x - attenuationDelta, 0)
                : min(self.velocity.x + attenuationDelta, 0)
            self.velocity.y = self.velocity.y > 0
                ? max(self.velocity.y - attenuationDelta, 0)
                : min(self.velocity.y + attenuationDelta, 0)

            // apply velocity to position if it moved
            let delayFixedVelocity = self.velocity * deltaTime

            if delayFixedVelocity.length == 0, self.acceleration.length == 0 {
                return false
            }

            let position = self.getPosition()
            self.onUpdate?(position + delayFixedVelocity, delayFixedVelocity)
            return true
        }
    }
}
