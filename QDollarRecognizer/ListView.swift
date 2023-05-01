//
//  ListView.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 13.04.2023.
//

import SwiftUI

struct ListView: View {
    @Environment(\.dismiss) var dismiss
    
    private let data: [GestureData]
    
    private struct ListItem: View {
        var data: GestureData
        
        var body: some View {
            RoundedRectangle(cornerRadius: 8.0)
                .stroke(Color("text"), lineWidth: 1.0)
                .background(RoundedRectangle(cornerRadius: 8.0).fill(Color("green").opacity(0.3)))
                .overlay {
                    HStack {
                        Text(data.emoji)
                            .frame(width: 25.0, alignment: .center)
                        Text(data.name)
                            .foregroundColor(Color("text"))
                        Spacer(minLength: 10.0)
                    }
                    .padding(EdgeInsets(top: 8.0, leading: 15.0, bottom: 8.0, trailing: 15.0))
                }
                .frame(minHeight: 40.0)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }
    
    init(with data: [GestureData]) {
        self.data = data
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Available Gestures")
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
            
            Spacer()
            
            List(data) {
                ListItem(data: $0)
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("background"))
    }
}
