//
//  Geometry+Triangle.swift
//  SwiftGraphics
//
//  Created by Jonathan Wight on 1/16/15.
//  Copyright (c) 2015 schwa.io. All rights reserved.
//

import CoreGraphics

import SwiftUtilities

public struct Triangle {
    public let vertex: (CGPoint, CGPoint, CGPoint)

    public init(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint) {
        self.vertex = (p0, p1, p2)
    }
}

public extension Triangle {
    /**
     Convenience initializer creating trangle from points in a rect.
     p0 is top middle, p1 and p2 are bottom left and bottom right
     */
    init(rect: CGRect, rotation: CGFloat = 0.0) {

        var p0 = rect.midXMinY
        var p1 = rect.minXMaxY
        var p2 = rect.maxXMaxY

        if rotation != 0.0 {
            let mid = rect.mid
            let transform = CGAffineTransform(rotation: rotation, origin: mid)
            p0 *= transform
            p1 *= transform
            p2 *= transform
        }

        self.vertex = (p0, p1, p2)
    }
}

public extension Triangle {

    init(points: [CGPoint]) {
        assert(points.count == 3)
        self.vertex = (points[0], points[1], points[2])
    }

    public var pointsArray: [CGPoint] {
        return [vertex.0, vertex.1, vertex.2]
    }

}

public extension Triangle {

    public var lengths: (CGFloat, CGFloat, CGFloat) {
        return (
            (vertex.0 - vertex.1).magnitude,
            (vertex.1 - vertex.2).magnitude,
            (vertex.2 - vertex.0).magnitude
        )
    }

    public var angles: (CGFloat, CGFloat, CGFloat) {
        let a1 = angle(vertex.0, vertex.1, vertex.2)
        let a2 = angle(vertex.1, vertex.2, vertex.0)
        let a3 = degreesToRadians(180) - a1 - a2
        return (a1, a2, a3)
    }

    public var isEquilateral: Bool {
        return equalities(self.lengths, test: { $0 ==% $1 }) == 3
    }

    public var isIsosceles: Bool {
        return equalities(self.lengths, test: { $0 ==% $1 }) == 2
    }

    public var isScalene: Bool {
        return equalities(self.lengths, test: { $0 ==% $1 }) == 1
    }

    public var isRightAngled: Bool {
        let a = self.angles
        let rightAngle = CGFloat(0.5 * M_PI)
        return a.0 ==% rightAngle || a.1 ==% rightAngle || a.2 ==% rightAngle
    }

    public var isOblique: Bool {
        return isRightAngled == false
    }

    public var isAcute: Bool {
        let a = self.angles
        let rightAngle = CGFloat(0.5 * M_PI)
        return a.0 < rightAngle && a.1 < rightAngle && a.2 < rightAngle
    }

    public var isObtuse: Bool {
        let a = self.angles
        let rightAngle = CGFloat(0.5 * M_PI)
        return a.0 > rightAngle || a.1 > rightAngle || a.2 > rightAngle
    }

    public var isDegenerate: Bool {
        let a = self.angles
        let r180 = CGFloat(M_PI)
        return a.0 ==% r180 || a.1 ==% r180 || a.2 ==% r180
    }

    public var signedArea: CGFloat {
        let (a, b, c) = vertex
        let signedArea = 0.5 * (
            a.x * (b.y - c.y) +
            b.x * (c.y - a.y) +
            c.x * (a.y - b.y)
        )
        return signedArea
    }

    public var area: CGFloat { return abs(signedArea) }

    // https: //en.wikipedia.org/wiki/Circumscribed_circle
    public var circumcenter: CGPoint {
        let (a, b, c) = vertex

        let D = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))

        let a2 = a.x ** 2 + a.y ** 2
        let b2 = b.x ** 2 + b.y ** 2
        let c2 = c.x ** 2 + c.y ** 2

        let X = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / D
        let Y = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / D

        return CGPoint(x: X, y: Y)
    }

    public var circumcircle: Circle {
        let (a, b, c) = lengths
        let diameter = (a * b * c) / (2 * area)
        return Circle(center: circumcenter, diameter: diameter)
    }

    public var inradius: CGFloat {
        let (a, b, c) = lengths
        return 2 * area / (a + b + c)
    }
}

// Cartesian coordinates
public extension Triangle {

    public var incenter: CGPoint {
        let (oppositeC, oppositeA, oppositeB) = lengths
        let (a, b, c) = vertex

        let x = (oppositeA * a.x + oppositeB * b.x + oppositeC * c.x) / (oppositeC + oppositeB + oppositeA)
        let y = (oppositeA * a.y + oppositeB * b.y + oppositeC * c.y) / (oppositeC + oppositeB + oppositeA)

        return CGPoint(x: x, y: y)
    }

    // converts trilinear coordinates to Cartesian coordinates relative
    // to the incenter; thus, the incenter has coordinates (0.0, 0.0)
    public func toLocalCartesian(alpha alpha: CGFloat, beta: CGFloat, gamma: CGFloat) -> CGPoint {
        let area = self.area
        let (a, b, c) = lengths

        let r = 2 * area / (a + b + c)
        let k = 2 * area / (a * alpha + b * beta + c * gamma)
        let C = angles.2

        let x = (k * beta - r + (k * alpha - r) * cos(C)) / sin(C)
        let y = k * alpha - r

        return CGPoint(x: x, y: y)
    }

    // TODO: This seems broken! --- validate that this is still needed..
    public func toCartesian(alpha  alpha: CGFloat, beta: CGFloat, gamma: CGFloat) -> CGPoint {
        let a = toLocalCartesian(alpha: alpha, beta: beta, gamma: gamma)
        let delta = toLocalCartesian(alpha: 0, beta: 0, gamma: 1)
        return vertex.0 + a - delta
    }
}

// MARK: Utilities

func equalities <T> (e: (T, T, T), test: ((T, T) -> Bool)) -> Int {
    var c = 1
    if test(e.0, e.1) {
        c += 1
    }
    if test(e.1, e.2) {
        c += 1
    }
    if test(e.2, e.0) {
        c += 1
    }
    return min(c, 3)
}

extension Triangle: Geometry {
    public var frame: CGRect {
        // TODO faster to just do min/maxes
        return CGRect.unionOfPoints([vertex.0, vertex.1, vertex.2])
    }
}
