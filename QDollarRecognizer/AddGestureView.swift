//
//  AddGestureView.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 13.04.2023.
//

import SwiftUI

struct AddGestureView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentation
    
    @State private var points = [Point]()
    @State private var i = 1
    @State private var name = ""
    @State private var icon = ""
    @State private var showingList = false
    @State private var isSaveError = false
    
    private enum SaveError: Error, LocalizedError {
        case name, icon, points
        
        var errorDescription: String? {
            switch self {
            case .name: return "Name can't be empty."
            case .icon: return "Icon can't be empty."
            case .points: return "Please draw the desired shape."
            }
        }
    }
    @State private var saveError: SaveError?
    
    let qDollarRecognizer: QDollarRecognizer
    var gesture: some Gesture {
        DragGesture()
            .onChanged({ points.append(Point(id: i, origin: $0.location)) })
            .onEnded({ _ in
                i += 1
            })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 15.0) {
                    VStack(alignment: .center, spacing: 8.0) {
                        Text("Icon")
                            .font(.system(size: 15.0))
                            .foregroundColor(Color("text").opacity(0.5))
                        Button(action: { showingList.toggle() }) {
                            if icon.isEmpty {
                                Image(systemName: "plus.viewfinder").font(.system(size: 36.0))
                            }
                            else {
                                Text(icon).font(.system(size: 36.0))
                            }
                        }
                        .frame(width: 36.0, height: 36.0, alignment: .center)
                        .sheet(isPresented: $showingList) {
                            EmojiList($icon)
                                .presentationDetents([.fraction(0.45)])
                                .presentationDragIndicator(.hidden)
                        }
                    }
                        
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text("Name")
                            .font(.system(size: 15.0))
                            .foregroundColor(Color("text").opacity(0.5))
                        VStack(spacing: 0.0) {
                            TextField("Gesture Name", text: $name)
                                .font(.system(size: 17.0, weight: .medium))
                                .foregroundColor(Color("text"))
                                .submitLabel(.done)
                                .frame(height: 35.0)
                            Divider()
                                .frame(height: 1.0)
                                .background(Color("text").opacity(0.5))
                        }
                    }
                }
                
                Spacer(minLength: 20.0)
                
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
                
                Spacer(minLength: 20.0)
                
                Button(action: {
                    if name.isEmpty {
                        isSaveError = true
                        saveError = .name
                    }
                    else if icon.isEmpty {
                        isSaveError = true
                        saveError = .icon
                    }
                    else if points.isEmpty {
                        isSaveError = true
                        saveError = .points
                    }
                    else {
                        save()
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 17.0, weight: .semibold))
                        .frame(maxWidth: .infinity, maxHeight: 56.0, alignment: .center)
                }
                .background(Color("darkBlue"))
                .foregroundColor(Color("background"))
                .cornerRadius(6.0)
                .alert("Error", isPresented: $isSaveError, presenting: saveError) { error in
                    Button("OK", role: .cancel) { }
                } message: { error in
                    Text(error.localizedDescription)
                }

            }
            .padding(15.0)
            .background(Color("background"))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    i = 1
                    points.removeAll()
                    icon = ""
                    name = ""
                }
            }
        }
        .navigationTitle("Add Gesture")
        .navigationBarTitleDisplayMode(.large)
        .navigationViewStyle(.stack)
    }
    
    private func save() {
        let data = qDollarRecognizer.normalize(points, name: name, emoji: icon)
        let item = TemplateGesture(context: viewContext)
        item.name = data.name
        item.emoji = data.emoji

        let pointsSet = NSMutableOrderedSet()
        data.points.forEach {
            let point = Points(context: viewContext)
            point.id = Int64($0.id)
            point.x = $0.origin.x
            point.y = $0.origin.y
            point.intX = Int64($0.x)
            point.intY = Int64($0.y)
            pointsSet.add(point)
        }
        item.points = pointsSet

        let lutSet = NSMutableOrderedSet()
        data.lut.forEach{ array in
            let values = NSMutableOrderedSet()
            array.forEach { value in
                let lutValue = LUTValue(context: viewContext)
                lutValue.value = Int64(value)
                values.add(lutValue)
            }

            let lut = LUT(context: viewContext)
            lut.value = values
            lutSet.add(lut)
        }

        item.lut = lutSet

        do {
            try viewContext.save()
            self.qDollarRecognizer.addTemplate(data)
        }
        catch { print(error) }
        
        self.presentation.wrappedValue.dismiss()
    }
}

fileprivate struct EmojiList: View {
    @Environment(\.dismiss) var dismiss
    @Binding var emoji: String
    
    private(set) var icons = [String]()
    
    init(_ emoji: Binding<String>) {
        _emoji = emoji
        
        let codes = [
            [0x1F600...0x1F64F],    // Emoticons
            [0x2600...0x26FF],      // Misc Symbols
            [0x1F300...0x1F5FF],    // Misc Symbols and Pictographs
            [0x1F900...0x1F9FF]     // Supplemental Symbols and Pictographs
        ]
        
        for list in codes {
            for code in list.joined() {
                guard let scalar = UnicodeScalar(code) else { continue }
                if scalar.properties.isEmoji {
                    self.icons.append(String(scalar))
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Icons")
                    .font(.system(size: 20.0, weight: .heavy))
                    .foregroundColor(Color("text"))
                    .layoutPriority(1.0)
                Spacer(minLength: 8.0)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 27.0))
                        .tint(.gray)
                }
            }
            .padding(EdgeInsets(top: 17.0, leading: 15.0, bottom: 0.0, trailing: 15.0))
            
            ScrollView(.horizontal) {
                LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8.0) {
                    ForEach(icons, id: \.self) { value in
                        Text(value).font(.system(size: 30.0))
                            .onTapGesture {
                                self.emoji = value
                                self.dismiss()
                            }
                    }
                }
                .padding(EdgeInsets(top: 0.0, leading: 15.0, bottom: 0.0, trailing: 15.0))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(alignment: .topLeading)
        .background(Color("background"))
    }
}
