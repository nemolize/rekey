import Foundation

extension CGPoint {
    public var length: CGFloat { sqrt(x * x + y * y) }

    public static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
    }

    public static func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
    }

    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    public static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}
