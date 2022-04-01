//
//  StickiesViewModel.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 31.03.2022.
//

import Foundation
import CoreData

class StickiesViewModel: ObservableObject {
    init(_ context:NSManagedObjectContext) {
        self.context = context
    }
    
    private let context:NSManagedObjectContext
    
    // MARK: - User Intents
    func delete(_ sticky:Sticky) {
        //use viewContext to delete
        context.delete(sticky)
        try? context.save()
    }
    
    func createNewSticky(with content:String) {
        <#function body#>
    }
}
