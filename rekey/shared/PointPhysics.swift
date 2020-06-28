import Foundation

class PointPhysics {
    private let queue = DispatchQueue(label: "rekey.physics.loop", qos: .userInteractive)
    private var force = CGPoint()
    private var velocity = CGPoint()
    private var friction: CGFloat
    private var frameInterval: Double
    private var gravity: CGFloat
    private var mass: CGFloat
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
        running = true
        queue.async {
            defer { self.running = false }

            var lastDate = Date()
            var deltaTime: CGFloat = 0
            repeat {
                // NOTE: wait 1ms at least to make time to accept update by user input
                usleep(useconds_t(1000))

                if -lastDate.timeIntervalSinceNow < self.frameInterval {
                    let diffSeconds = self.frameInterval + lastDate.timeIntervalSinceNow
                    usleep(useconds_t(diffSeconds * 1000 * 1000))
                }

                deltaTime = CGFloat(-lastDate.timeIntervalSinceNow)
                lastDate = Date()
            } while self.advance(deltaTime)
        }
    }

    func setForce(_ force: CGPoint) {
        self.force = force
        if !running { start() }
    }

    private func advance(_ deltaTime: CGFloat) -> Bool {
        // a = F/m
        let acceleration = force / mass
        // update velocity: v = v + at
        velocity += acceleration * deltaTime
        // apply frictional attenuation of velocity: F = μN, where N = m * g
        let frictionForce = friction * mass * gravity

        // apply attenuation to velocity
        let velocityAttenuation = frictionForce / mass * deltaTime
        velocity.x = velocity.x > 0
            ? max(velocity.x - velocityAttenuation, 0)
            : min(velocity.x + velocityAttenuation, 0)
        velocity.y = velocity.y > 0
            ? max(velocity.y - velocityAttenuation, 0)
            : min(velocity.y + velocityAttenuation, 0)

        onUpdate?(velocity * deltaTime)

        return velocity.length != 0 || force.length != 0 // NOTE: suspend when no movements
    }

    func applyConfig(_ root: [String: Any]) {
        if let value = root["friction"] as? CGFloat { friction = value }
        if let value = root["gravity"] as? CGFloat { gravity = value }
        if let value = root["mass"] as? CGFloat { mass = value }
        if let value = root["framerate"] as? Double {
            if value > 0 { frameInterval = 1 / value }
        }
    }
}
