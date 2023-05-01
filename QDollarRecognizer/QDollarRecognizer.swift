//
//  QDollarRecognizer.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 27.12.2022.
//

import Foundation
import CoreGraphics.CGGeometry

struct Point: Codable, Hashable {
    let id: Int
    let origin: CGPoint
    var x: Int
    var y: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(origin.x)
        hasher.combine(origin.y)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, originX, originY, x, y
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(origin.x, forKey: .originX)
        try container.encode(origin.y, forKey: .originY)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.x = try container.decode(Int.self, forKey: .x)
        self.y = try container.decode(Int.self, forKey: .y)
        
        let originX = try container.decode(Double.self, forKey: .originX)
        let originY = try container.decode(Double.self, forKey: .originY)
        self.origin = CGPoint(x: originX, y: originY)
    }
    
    init(id: Int, origin: CGPoint) {
        self.id = id
        self.origin = origin
        self.x = 0
        self.y = 0
    }
    
    init(id: Int, origin: CGPoint, intX: Int, intY: Int) {
        self.id = id
        self.origin = origin
        self.x = intX
        self.y = intY
    }
}

struct GestureData: Codable, Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let points: [Point]
    let lut: [[Int]]
    
    enum CodingKeys: String, CodingKey {
        case name, emoji, points, lut
    }
    
    init(name: String, emoji: String, points: [Point], lut: [[Int]]) {
        self.id = points.reduce(1, { $0.hashValue ^ $1.hashValue })
        self.name = name
        self.emoji = emoji
        self.points = points
        self.lut = lut
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.points = try container.decode([Point].self, forKey: .points)
        self.lut = try container.decode([[Int]].self, forKey: .lut)
        self.id = self.points.reduce(1, { $0.hashValue ^ $1.hashValue })
    }
}

class QDollarRecognizer {
    private let defaultCloudSize: Int
    private let lutSize: Int
    private let lutScaleFactor: Int
    private let maxIntCoordinates = 1024
    private(set) var templates: [GestureData]
    
    init(with templates: [GestureData], cloudSize: Int = 64, lutSize: Int = 64) {
        self.templates = templates
        self.defaultCloudSize = cloudSize
        self.lutSize = lutSize
        self.lutScaleFactor = self.maxIntCoordinates / lutSize
    }
    
    func addTemplate(_ name: String, emoji: String, from points: [Point]) {
        let data = normalize(points, name: name, emoji: emoji)
        addTemplate(data)
    }
    
    func addTemplate(_ data: GestureData) {
        templates.append(data)
    }
    
    func recognize(_ points: [Point]) -> GestureData? {
        let data = normalize(points, name: "", emoji: "")
        var minDistance = Double.greatestFiniteMagnitude
        var result: GestureData? = nil
        templates.forEach {
            let distance = cloudMatch(data: data, template: $0, minSoFar: minDistance)
            if distance < minDistance {
                minDistance = distance
                result = $0
            }
        }
        return result
    }
    
    private func cloudMatch(data: GestureData, template: GestureData, minSoFar: Double) -> Double {
        let count = data.points.count
        var minSoFar = minSoFar
        let step = Int(pow(Double(count), 0.5).rounded(.towardZero))
        let lowerBound1 = computeLowerBound(points: data.points, template: template.points, step: step, lut: template.lut)
        let lowerBound2 = computeLowerBound(points: template.points, template: data.points, step: step, lut: data.lut)
        var indexLB = 0
        for i in stride(from: 0, to: count, by: step) {
            if lowerBound1[indexLB] < minSoFar {
                minSoFar = min(minSoFar, cloudDistance(points: data.points, template: template.points, startIndex: i, minSoFar: minSoFar))
            }
            if lowerBound2[indexLB] < minSoFar {
                minSoFar = min(minSoFar, cloudDistance(points: template.points, template: data.points, startIndex: i, minSoFar: minSoFar))
            }
            indexLB += 1
        }
        return minSoFar
    }

    private func cloudDistance(points: [Point], template: [Point], startIndex: Int, minSoFar: Double) -> Double {
        let count = points.count
        var unmatched = Array(0..<count)
        var i = startIndex
        var weight = Double(count)
        var sum = 0.0
        var indexNotMatched = 0
        repeat {
            var index = -1
            var minDistance = Double.greatestFiniteMagnitude
            for j in indexNotMatched..<count {
                let distance = sqrEuclidenDistance(pointA: points[i], pointB: template[unmatched[j]])
                if distance < minDistance {
                    minDistance = distance
                    index = j
                }
            }
            unmatched[index] = unmatched[indexNotMatched]
            sum += weight * minDistance
            weight -= 1
            if sum >= minSoFar {
                return sum
            }
            i = (i + 1) % count
            indexNotMatched += 1
        }
        while( i != startIndex )
        return sum
    }

    private func computeLowerBound(points: [Point], template: [Point], step: Int, lut: [[Int]]) -> [Double] {
        let count = points.count
        var lowerBound = Array(repeating: 0.0, count: count / step + 1)
        lowerBound[0] = 0
        var sat = Array(repeating: 0.0, count: count)
        for i in 0..<count {
            let index = lut[points[i].y / lutScaleFactor][points[i].x / lutScaleFactor]
            let distance = sqrEuclidenDistance(pointA: points[i], pointB: template[index])
            sat[i] = i == 0 ? distance : sat[i - 1] + distance
            lowerBound[0] += Double(count - i) * distance
        }
        var indexLB = 1
        for i in stride(from: step, to: count, by: step) {
            lowerBound[indexLB] = lowerBound[0] + Double(i) * sat[count - 1] - Double(count) * sat[i - 1]
            indexLB += 1
        }
        return lowerBound
    }
    
    // MARK: - Gesture Preprocessing
    func normalize(_ data: [Point], name: String, emoji: String) -> GestureData {
        var points = resample(data)
        scale(&points)
        translateToOrigin(&points)
        return GestureData(name: name, emoji: emoji, points: points, lut: computeLut(for: points))
    }
    
    private func resample(_ points: [Point]) -> [Point] {
        let intervalLength = pathLength(for: points) / Double(defaultCloudSize - 1)
        var distance = 0.0
        var newPoints = [points[0]]
        var numPoints = 1
        for i in 1..<points.count {
            if points[i].id == points[i - 1].id {
                var euclidenDistance = euclidenDistance(pointA: points[i - 1], pointB: points[i])
                if distance + euclidenDistance >= intervalLength {
                    var firstPoint = points[i - 1]
                    while (distance + euclidenDistance >= intervalLength) {
                        let t = euclidenDistance == 0 ? 0.5 : min(max((intervalLength - distance) / euclidenDistance, 0.0), 1.0)
                        let x = (1 - t) * firstPoint.origin.x + t * points[i].origin.x
                        let y = (1 - t) * firstPoint.origin.y + t * points[i].origin.y
                        newPoints.insert(Point(id: points[i].id, origin: CGPoint(x: x, y: y)), at: numPoints)
                        
                        euclidenDistance = distance + euclidenDistance - intervalLength
                        distance = 0
                        firstPoint = newPoints[numPoints]
                        numPoints += 1
                    }
                    distance = euclidenDistance
                }
                else {
                    distance += euclidenDistance
                }
            }
        }
        
        if numPoints == defaultCloudSize - 1 {
            newPoints.insert(points[points.count - 1], at: numPoints)
        }
        return newPoints
    }
    
    private func translateToOrigin(_ points: inout [Point]) {
        var centroid = CGPoint.zero
        points.forEach {
            centroid.x += $0.origin.x
            centroid.y += $0.origin.y
        }
        centroid.x /= Double(points.count)
        centroid.y /= Double(points.count)
        for i in 0..<points.count {
            var point = Point(id: points[i].id, origin: CGPoint(x: points[i].origin.x - centroid.x, y: points[i].origin.y - centroid.y ))
            point.x = Int((point.origin.x + 1.0) / 2.0 * Double(maxIntCoordinates - 1))
            point.y = Int((point.origin.y + 1.0) / 2.0 * Double(maxIntCoordinates - 1))
            points[i] = point
        }
    }
    
    private func scale(_ points: inout [Point]) {
        var xMin = Double.greatestFiniteMagnitude
        var xMax = Double.leastNormalMagnitude
        var yMin = Double.greatestFiniteMagnitude
        var yMax = Double.leastNormalMagnitude
        points.forEach {
            xMin = min(xMin, $0.origin.x)
            yMin = min(yMin, $0.origin.y)
            xMax = max(xMax, $0.origin.x)
            yMax = max(yMax, $0.origin.y)
        }
        let scale = max(xMax - xMin, yMax - yMin)
        for i in 0..<points.count {
            points[i] = Point(id: points[i].id, origin: CGPoint(x: (points[i].origin.x - xMin) / scale, y: (points[i].origin.y - yMin) / scale))
        }
    }
    
    private func computeLut(for points: [Point]) -> [[Int]] {
        var lut = Array(repeating: Array(repeating: 0, count: lutSize), count: lutSize)
        for x in 0..<lutSize {
            for y in 0..<lutSize {
                var index = -1
                var min = Int.max
                for i in 0..<points.count {
                    let col = points[i].x / lutScaleFactor
                    let row = points[i].y / lutScaleFactor
                    let distance = (row - x) * (row - x) + (col - y) * (col - y)
                    if distance < min {
                        min = distance
                        index = i
                    }
                }
                lut[x][y] = index
            }
        }
        return lut
    }
    
    private func pathLength(for points: [Point]) -> Double {
        var length = 0.0
        for i in 1..<points.count {
            if points[i].id == points[i - 1].id {
                length += euclidenDistance(pointA: points[i - 1], pointB: points[i])
            }
        }
        return length
    }
    
    private func sqrEuclidenDistance(pointA: Point, pointB: Point) -> Double {
        return (pointA.origin.x - pointB.origin.x) * (pointA.origin.x - pointB.origin.x) + (pointA.origin.y - pointB.origin.y) * (pointA.origin.y - pointB.origin.y)
    }
    
    private func euclidenDistance(pointA: Point, pointB: Point) -> Double {
        return sqrt(sqrEuclidenDistance(pointA: pointA, pointB: pointB))
    }
}
