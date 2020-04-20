//
//  intrinsics.swift
//  rekey
//
//  Created by nemoto on 2018/01/03.
//  Copyright © 2018年 nemoto. All rights reserved.
//

import Foundation

extension CGVector {
    public func length() -> CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
}

public func *(vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * CGFloat(scalar), dy: vector.dy * CGFloat(scalar))
}

public func +(left: CGVector, right: CGVector) -> CGVector {
    return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

public func +=(left: inout CGVector, right: CGVector) {
    left = left + right
}

public func +(left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
}

class Mouse {

    private let mouseLoopQueueName = "mouseLoopQueueName"

    private let mouseLock = NSLock()
    private var acceleration = CGVector()
    private var velocity = CGVector()
    private var attenuation = CGFloat(0.1)

    func getPosition() -> CGPoint { return CGEvent(source: nil)!.location }

    func setPosition(_ position: CGPoint) {
        if let moveEvent = CGEvent(source: nil) {
            moveEvent.type = .mouseMoved
            moveEvent.location = position
            moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }

    func start() {
        DispatchQueue(label: mouseLoopQueueName).async {
            var lastSeconds = Date().timeIntervalSince1970
            while true {
                let currentSeconds = Date().timeIntervalSince1970
                let deltaSeconds = currentSeconds - lastSeconds
                let frameIntervalBasis = 1.0 / 60

                // get frame delay for precision
                let deltaTime = CGFloat(deltaSeconds / frameIntervalBasis)

                self.mouseLock.lock()
                defer{ self.mouseLock.unlock() }

                // apply Acceleration v=v + at
                self.velocity += self.acceleration * deltaTime

                // apply attenuation
                let attenuationDelta = self.attenuation * deltaTime

                // apply attenuation to velocity
                self.velocity.dx = (0 < self.velocity.dx) ?
                        max(self.velocity.dx - attenuationDelta, 0) : min(self.velocity.dx + attenuationDelta, 0)
                self.velocity.dy = (0 < self.velocity.dy) ?
                        max(self.velocity.dy - attenuationDelta, 0) : min(self.velocity.dy + attenuationDelta, 0)

                // apply velocity to mouse position if it moved
                let delayFixedVelocity = self.velocity * deltaTime
                if (delayFixedVelocity).length() > 0 {
                    let position = self.getPosition()
                    self.setPosition(position + delayFixedVelocity)
                }

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

        if let val = dx { velocity.dx = val }
        if let val = dy { velocity.dy = val }
    }

    func setAcceleration(_ dx: CGFloat?, _ dy: CGFloat?) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }

        if let val = dx { acceleration.dx = val }
        if let val = dy { acceleration.dy = val }
    }

    func setAttenuation(_ attenuation: CGFloat) {
        self.mouseLock.lock()
        defer{ self.mouseLock.unlock() }
        self.attenuation = attenuation
    }
}

extension Intrinsics {
    func setUpMouse() {

        let mouse = Mouse()
        mouse.start()

        struct JsNames {
            static let getPosition = "getPosition"
            static let setAttenuation = "setAttenuation"
            static let setForce = "setForce"
            static let setVelocity = "setVelocity"
        }

        _ = jsContext?.evaluateScript("var Mouse = {}")

        makeJsObj("Mouse", JsNames.getPosition, { name in
            jsContext?.setb0(name, { return mouse.getPosition() })
        })

        makeJsObj("Mouse", JsNames.setAttenuation, { name in
            jsContext?.setb1(name, { (arg: Any!) in
                guard let attenuation: CGFloat = self.getValue(arg) else {
                    return jsContext?.throwError("arg \(arg!) is not a number")
                }
                return mouse.setAttenuation(attenuation)
            })
        })

        makeJsObj("Mouse", JsNames.setForce, { name in
            jsContext?.setb1(name, { (arg: Any!) in
                guard let option: NSDictionary = self.getValue(arg) else {
                    return jsContext?.throwError("arg \(arg!) is not a number")
                }
                return mouse.setAcceleration(
                        self.getValue(option.value(forKey: "x")),
                        self.getValue(option.value(forKey: "y"))
                )
            })
        })

        makeJsObj("Mouse", JsNames.setVelocity, { name in
            jsContext?.setb1(name, { (arg: Any!) in
                guard let option: NSDictionary = self.getValue(arg) else {
                    return jsContext?.throwError("arg \(arg!) is not an object")
                }
                return mouse.setVelocity(
                        self.getValue(option.value(forKey: "x")),
                        self.getValue(option.value(forKey: "y"))
                )
            })
        })
    }
}

