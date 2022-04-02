//
//  ViewModel.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 25.03.2022.
//

import SwiftUI
import CoreData

class ViewModel: ObservableObject {
    // MARK: - Publisher
    @Published var stickies = [Sticky]()
    
    // MARK: -
    private var pair:Pair
    var stickyContents = [String]()
    
    // MARK: -
    private lazy var bubble:CT = {
        guard let bubble = pair.session?.ct else { fatalError() }
        return bubble
    }()
    
    private lazy var context:NSManagedObjectContext = {
        guard let context = bubble.managedObjectContext else { fatalError() }
        return context
    }()
    
    // MARK: - Methods
    private func fetchAndUpdateStickies() {
        //make request
        let request:NSFetchRequest<Sticky> = Sticky.fetchRequest()
        let sortByDate = NSSortDescriptor(key: #keyPath(Sticky.created), ascending: false)
        request.sortDescriptors = [sortByDate]
        
        //fetch
        let unsortedStickies = try? context.fetch(request)
        
        DispatchQueue.global().async { [self] in
            //own bubble and other bubbles
            let sortedStickies = self.sort(unsortedStickies ?? [])
            DispatchQueue.main.async { self.stickies = sortedStickies }
        }
    }
    
    // MARK: - ⚠️ important method
    ///it splits stickies into 2 subarrays: own and others
    private func sort(_ unsortedStickies:[Sticky]) -> [Sticky] {
        var ownStickies = [Sticky]()
        var otherStickies = [Sticky]()
        
        //sort by own first
        unsortedStickies.forEach {
            if $0.bubble?.id == pair.session?.ct?.id { ownStickies.append($0) }
            else { otherStickies.append($0) }
        }
                
        //used to filter out duplicates in the otherBucket
        let ownStickiesContents = ownStickies.compactMap { $0.content }
        
        let duplicateFreeOtherStickies = otherStickies.filter {
            !ownStickiesContents.contains($0.content!)
        }
        let result = ownStickies + duplicateFreeOtherStickies  /* without own elements */
        
        let contents = result.compactMap { $0.content }
        DispatchQueue.main.async { self.stickyContents = contents }
        return result
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
        newSticky.bubble = bubble
    
        pair.sticky = newSticky.content ?? "pula"
        pair.isStickyVisible = true
        
        if bubble.maxStickyCount > 100 {
            //remove oldest sticky
            print("oldest sticky removed! max \(bubble.maxStickyCount) stickies allowed")
            bubble.removeFromStickies(at: 0)
        }
        
        do { try context.save() }
        catch let error { print(error) }
    }
    
    func userTapsStickyInTheList(with content:String) {
        pair.sticky = content
        pair.isStickyVisible = true
        
        //stickies that have the same content, but might belong to different bubbles
        let identicalStickies = stickies.filter { $0.content == content }
        //is existing sticky own or other
        let ownSticky = identicalStickies.filter { $0.bubble == bubble }.first
        
        //if "own sticky", change its date only
        //if "other sticky", create new "own sticky" sticky with same content
        if let ownSticky = ownSticky { ownSticky.created = Date() }
        else {
            let newSticky = Sticky(context: context)
            newSticky.content = content
            newSticky.bubble = bubble
            newSticky.created = Date()
        }
                
        do { try context.save() }
        catch let error { print(error) }
    }
    
    func userDeletesSticky(at indexSet:IndexSet) {
        guard let index = indexSet.first else { return }
        
        context.delete(stickies[index])
        try? context.save()
        fetchAndUpdateStickies()
    }
    
    // MARK: -
    init(pair:Pair) {
        self.pair = pair
        fetchAndUpdateStickies()
    }
    deinit {
//        print("viewmodel deinit")
    }
}

