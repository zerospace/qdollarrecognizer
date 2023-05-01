//
//  ContentView.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 22.12.2022.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var points = [Point]()
    @State private var i: Int = 1
    @State private var flipAnimation = false
    @State private var angleDegrees = 0.0
    @State private var resultIcon = "👻"
    @State private var resultText = "None"
    @State private var showingList = false
    
    private var qDollarRecognizer: QDollarRecognizer
    
    init() {
        var templates = [GestureData]()
        if let path = Bundle.main.path(forResource: "templates", ofType: "plist") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                templates = try PropertyListDecoder().decode([GestureData].self, from: data)
                
                let fetchRequest = NSFetchRequest<TemplateGesture>(entityName: "TemplateGesture")
                let fetched = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
                fetched.forEach { item in
                    if let name = item.name, let emoji = item.emoji, let pointSet = item.points?.array as? [Points], let lutSet = item.lut?.array as? [LUT] {
                        let points = pointSet.map { Point(id: Int($0.id), origin: CGPoint(x: $0.x, y: $0.y), intX: Int($0.intX), intY: Int($0.intY)) }
                        var lut = [[Int]]()
                        lutSet.forEach { obj in
                            if let values = obj.value?.array as? [LUTValue] {
                                lut.append(values.map { Int($0.value) })
                            }
                        }
                        templates.append(GestureData(name: name, emoji: emoji, points: points, lut: lut))
                    }
                }
            }
            catch { print(error) }
        }
        self.qDollarRecognizer = QDollarRecognizer(with: templates)
    }
    
    var gesture: some Gesture {
        DragGesture()
            .onChanged({ points.append(Point(id: i, origin: $0.location)) })
            .onEnded({ _ in endGesture() })
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 15.0) {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        ZStack {
                            Color("blue")
                            DrawShape(points: points)
                                .stroke(lineWidth: 5.0)
                                .foregroundColor(Color("text"))
                        }
                        .gesture(gesture)
                        .cornerRadius(8.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0)
                                .stroke(Color("text"), lineWidth: 1.0)
                        )
                        .padding(.bottom, 35.0)
                        
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(Color("text"), lineWidth: 1.0)
                            .background(RoundedRectangle(cornerRadius: 8.0).fill(Color("green")))
                            .frame(maxWidth: geometry.size.width * 0.7, maxHeight: 70.0)
                            .overlay(
                                HStack(spacing: 10.0) {
                                    Text(resultIcon).font(.system(size: 20.0))
                                    Text(resultText)
                                        .font(.system(size: 18.0, weight: .medium))
                                        .foregroundColor(Color("text"))
                                }
                                .rotation3DEffect(.degrees(angleDegrees), axis: (x: 1.0, y: 0.0, z: 0.0))
                                .onAnimationCompleted(for: angleDegrees) {
                                    angleDegrees = 0
                                }
                            )
                            .rotation3DEffect(.degrees(angleDegrees), axis: (x: 1.0, y: 0.0, z: 0.0))
                            .animation(.easeInOut(duration: 0.25), value: flipAnimation)
                    }
                }
                
                Button(action: { showingList.toggle() }) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15.0))
                        Text("Available gesture templates")
                            .font(.system(size: 15.0))
                    }
                }
                .foregroundColor(Color("text"))
                .sheet(isPresented: $showingList) {
                    ListView(with: qDollarRecognizer.templates)
                }
                
                Spacer(minLength: 30.0)
                
                Button(action: clear) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 22.0, weight: .semibold))
                        Text("Clear")
                            .font(.system(size: 17.0, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 56.0, alignment: .center)
                }
                .background(Color("red"))
                .foregroundColor(Color("background"))
                .cornerRadius(6.0)
            }
            .padding(15.0)
            .background(Color("background"))
            .navigationTitle("$Q Recognizer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddGestureView(qDollarRecognizer: qDollarRecognizer)
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2.weight(.semibold))
                    }
                }
            }
        }
        .tint(Color("text"))
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Actions
    private func add() {
        // TODO: add new gesture
    }
    
    private func clear() {
        points.removeAll()
        i = 1
        angleDegrees = 180
        flipAnimation.toggle()
        resultIcon = "👻"
        resultText = "None"
    }
    
    private func endGesture() {
        i += 1
        if let result = qDollarRecognizer.recognize(points) {
            angleDegrees = 180
            flipAnimation.toggle()
            resultIcon = result.emoji
            resultText = result.name
            return
        }
    }
}
