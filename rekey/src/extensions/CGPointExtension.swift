import Foundation

extension CGPoint {
    public func length() -> CGFloat {
        sqrt(x * x + y * y)
    }

    static public func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }

    static public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static public func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
    }
}

