//
//  BubbleStickyViewModel.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 06.04.2022.
//

import SwiftUI
import CoreData

class BubbleStickyViewModel: ObservableObject {
    // MARK: - Publisher
    @Published var stickies = [BubbleSticky]()
    
    // MARK: -
    var stickyContents = [String]()
    
    private let context = CoreDataStack.shared.viewContext
    
    // MARK: - Methods
    private func fetchAndUpdateStickies() {
        //make request
        let request:NSFetchRequest<BubbleSticky> = BubbleSticky.fetchRequest()
        let sortByDate = NSSortDescriptor(key: #keyPath(BubbleSticky.created), ascending: false)
        request.sortDescriptors = [sortByDate]
        
        //fetch and set self.stickies
        do { stickies = try context.fetch(request) }
        catch let error { print(error.localizedDescription) }
    }
    
    // MARK: - User Intents
    //1. create and assign new sticky
    //2. assign existing sticky
    //3. delete sticky
    
    func userTapsCreateNewStickyButton(_ content:String) {
        let newSticky = Sticky(context: context)
        
        var trimmedContent = content
        trimmedContent.removeAllWhiteSpace()
        
        newSticky.content = trimmedContent.capitalized
        newSticky.created = Date()
        
        do { try context.save() }
        catch let error { print(error) }
    }
    
    func userTapsStickyInTheList(with content:String) {
        //which BubbleSticky was tapped
        //change its created date to now
         
        //save and update cal events for that bubble
        do {
            try context.save()
//            CalManager.shared.updateExistingEvent(.title(<#T##CT#>))
        }
        catch let error { print(error) }
    }
    
    func userDeletesStickyInTheList(at indexSet:IndexSet) {
        guard let index = indexSet.first else { return }
        
        context.delete(stickies[index])
        try? context.save()
        fetchAndUpdateStickies()
    }
    
    // MARK: -
    func bubble(with content:String) -> CT {
        let request:NSFetchRequest = CT.fetchRequest()
        let predicate = NSPredicate(format: "stickyNote = %@", content)
        request.predicate = predicate
        guard let bubble = try? context.fetch(request).first else { fatalError() }
        print(bubble.stickyNote)
        return bubble
    }
    
    // MARK: -
    init() { fetchAndUpdateStickies() }
    deinit {
//        print("BubbleStickyViewModel deinit")
    }
}
