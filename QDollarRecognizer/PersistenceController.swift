//
//  PersistenceController.swift
//  QDollarRecognizer
//
//  Created by Oleksandr Fedko on 19.04.2023.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init() {
        self.container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as? NSError {
                fatalError("[ERROR] Load Persistent Stores \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
