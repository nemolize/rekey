import Foundation

class PointPhysics {
    private let queue = DispatchQueue(label: "rekey.physics.loop", qos: .userInteractive)
    private let mouseLock = NSLock()
    private var force = CGPoint()
    private var velocity = CGPoint()
    private var friction: CGFloat
    private let frameInterval: Double
    private let gravity: CGFloat
    private let mass: CGFloat
    private let onUpdate: ((_ velocity: CGPoint) -> Void)?

    init(
        friction: CGFloat = 1,
        gravity: CGFloat = 9.8,
        mass: CGFloat = 1,
        frameRate: Double = 60,
        onUpdate: @escaping (_ velocity: CGPoint) -> Void
    ) {
        self.friction = friction
        self.gravity = gravity
        self.mass = mass
        frameInterval = 1.0 / frameRate
        self.onUpdate = onUpdate
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

    func setForce(_ force: CGPoint) {
        doThreadSafely {
            self.force.x = force.x
            self.force.y = force.y
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
            // a = F/m
            let acceleration = force / mass

            // update velocity: v = v + at
            velocity += acceleration * deltaTime
            // apply frictional attenuation of velocity: F = μN, where N = m * g
            // TODO: integrate in acceleration
            let velocityAttenuation = friction * gravity * mass * deltaTime

            // apply attenuation to velocity
            velocity.x = velocity.x > 0
                ? max(velocity.x - velocityAttenuation, 0)
                : min(velocity.x + velocityAttenuation, 0)
            velocity.y = velocity.y > 0
                ? max(velocity.y - velocityAttenuation, 0)
                : min(velocity.y + velocityAttenuation, 0)

            let willSuspend = velocity.length == 0 && force.length == 0
            onUpdate?(velocity)

            return !willSuspend
        }
    }
}
