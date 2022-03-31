// https://stackoverflow.com/questions/25812268/core-data-error-exception-was-caught-during-core-data-change-processing
// https://www.youtube.com/watch?v=OrCRizFIR0s
//  CoreDataStack.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Tue  23.02.2021.
//

import CoreData


class CoreDataStack {
    let name:String
    let sharedDataBaseFile:URL?
    
    static let shared = CoreDataStack("Model")
    
    ///do not add file extension!!! Only the name of the file without any extension
    private init(_ nameOf_xcDataModeld_File:String) {
        self.name = nameOf_xcDataModeld_File
        self.sharedDataBaseFile = FileManager.sharedDatabase
    }
    
    lazy var container:NSPersistentContainer = {
        let container = NSPersistentContainer(name: name)
        
        //put entire CoreData in a shared file
        //so that all extensions have access to it
        if let sharedFile = sharedDataBaseFile {
            let storeDescription = NSPersistentStoreDescription(url: sharedFile)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error { print(error.localizedDescription) }
        }
        let persistentStores = container.persistentStoreCoordinator.persistentStores.count
        return container
    }()
    
    lazy var viewContext:NSManagedObjectContext = {
        container.viewContext
    }()
    
    func saveContext() {
        if viewContext.hasChanges {
//            print(#function)
            do { try viewContext.save() }
            catch let error { print(error.localizedDescription) }
        }
    }
    
//    public lazy var cacheContext: NSManagedObjectContext = {
//        return container.newBackgroundContext()
//    }()
//    
    public lazy var updateContext: NSManagedObjectContext = {
        let _updateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        _updateContext.parent = viewContext
        return _updateContext
    }()
}

extension CoreDataStack {
    func bubble(for id:String?) -> CT? {
        guard let id = id else { return nil }
        
        let request:NSFetchRequest<CT> = CT.fetchRequest()
        var result:CT?
        
        if let bubbles = try? viewContext.fetch(request) {
            bubbles.forEach {
                if $0.id!.uuidString == id { result = $0 }
            }
        }
        return result
    }
}
