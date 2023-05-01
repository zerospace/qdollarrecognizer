//
//  DrawShape.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 14.04.2023.
//

import SwiftUI

struct DrawShape: Shape {
    var points: [Point]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if let firstPoint = points.first {
            path.move(to: firstPoint.origin)
            var index = firstPoint.id
            for i in 1..<points.count {
                if index != points[i].id {
                    index = points[i].id
                    path.move(to: points[i].origin)
                    continue
                }
                path.addLine(to: points[i].origin)
            }
        }
        return path
    }
}
