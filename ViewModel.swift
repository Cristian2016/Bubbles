//
//  ViewModel.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 25.03.2022.
//

import SwiftUI
import CoreData

class ViewModel: ObservableObject {
    // MARK: - Publishers
    @Published var stickies = [Sticky]()
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
    
    private let descriptors = [
        NSSortDescriptor(key: "bubble", ascending: false),
        NSSortDescriptor(key: "created", ascending: false)
    ]
    
    // MARK: - Methods
    private func fetchAndUpdateStickies() {
        print(#function)
        let request:NSFetchRequest<Sticky> = Sticky.fetchRequest()
        request.sortDescriptors = descriptors
        do {
            let unsortedStickies = try context.fetch(request)
            DispatchQueue.global().async { [self] in
                //own bubble and other bubbles
                let sortedStickies = self.sort(unsortedStickies)
                DispatchQueue.main.async { self.stickies = sortedStickies }
            }
        }
        catch let error { print(error.localizedDescription) }
    }
    
    ///it splits stickies into 2 subarrays: own and others
    private func sort(_ unsortedStickies:[Sticky]) -> [Sticky] {
        var ownBucket = [Sticky]()
        var otherBucket = [Sticky]()
        
        //sort by own first
        unsortedStickies.forEach {
            if $0.bubble?.id == pair.session?.ct?.id { ownBucket.append($0) }
            else { otherBucket.append($0) }
        }
        
        //used to filter out duplicates in the otherBucket
        var ownBucketContents = [String]()
        
        ownBucket.forEach {
            if $0.content != nil {
                ownBucketContents.append($0.content!)
            }
        }
        let duplicateFreeOtherBucket = otherBucket.filter {
            !ownBucketContents.contains($0.content!)
        }
        let result = ownBucket + duplicateFreeOtherBucket  /* without own elements */
        
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
        
        if let ownSticky = ownSticky {
            print("user chose own")
            ownSticky.created = Date()
        } else {
            print("user chose other")
            let newSticky = Sticky(context: context)
            newSticky.content = content
            newSticky.bubble = bubble
            newSticky.created = Date()
        }
                
        do { try context.save() }
        catch let error { print(error) }
    }
    
    func userDeletesSticky(at indexSet:IndexSet) {
        print(indexSet)
        indexSet.forEach { context.delete(stickies[$0]) }
        try? context.save()
        fetchAndUpdateStickies()
    }
    
    // MARK: -
    init(pair:Pair) {
        self.pair = pair
        fetchAndUpdateStickies()
    }
    deinit {
        print("ok man it's good")
//        print("viewmodel deinit")
//        print("I dont know")
    }
}

