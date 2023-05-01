//
//  QDollarRecognizerApp.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 22.12.2022.
//

import SwiftUI

@main
struct QDollarRecognizerApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        let navigationBarAppearence = UINavigationBarAppearance()
        navigationBarAppearence.configureWithTransparentBackground()
        navigationBarAppearence.titleTextAttributes = [.foregroundColor : UIColor(Color("text"))]
        navigationBarAppearence.largeTitleTextAttributes = [.foregroundColor : UIColor(Color("text"))]
        UINavigationBar.appearance().standardAppearance = navigationBarAppearence
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearence
        UINavigationBar.appearance().compactAppearance = navigationBarAppearence
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
