import UIKit
import CoreData
import UserNotifications
import WidgetKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var context:NSManagedObjectContext = CoreDataStack.shared.viewContext
    
    func applicationWillTerminate(_ application: UIApplication) {
        /*
         ⚠️
         called if user kills the app
         NOT called if user kills the app from the app switcher
         */
        UserDefaults.standard.saveDate(Date(), key: .appDidEnterBackground)
        CoreDataStack.shared.saveContext()
    }
    
    static var appLaunchDate:Date!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppDelegate.appLaunchDate = Date()
        
        QuickAction().addToShortcutItems()
        let key = UserDefaults.Key.isAnimationOnAppearEnabled
        if UserDefaults.standard.value(forKey: key) as? Bool == nil {
            UserDefaults.standard.setValue(true, forKey: key)
        }
        
        //user presented with a quickTutorial at the beginning to learn the basics
        UserDefaults.standard.manage_QuickStartGuideDone_Key()
        
        return true
    }
    
    // MARK: - Shared CoreData between app and its extensions
    private var sharedContainer:NSPersistentContainer {
        
        //description
        let sharedFolder = FileManager.sharedFolder
        let description = NSPersistentStoreDescription(url: sharedFolder)
        
        let persistentContainer = NSPersistentContainer(name: "SharedContainer")
        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("not good", error.localizedDescription)
            }
        }
        return persistentContainer
    }
}

// MARK: - Shared CoreData between app and its extensions
extension AppDelegate {
    
    ///use one single shared CoreData container so app and extensions have access to Coredata storage
    private func shouldMigrateCoreData() {
        let key = UDKey.isCoreDataShared
        guard
            UserDefaults.standard.value(forKey: key) == nil
        else { return }
        
        let container = sharedContainer
        //migrate logic
        let coordinator = container.persistentStoreCoordinator
        let sharedFolder = FileManager.sharedFolder
        let storeType = NSSQLiteStoreType
        guard let store = container.persistentStoreCoordinator.persistentStores.first else { return }
        
        do {
            try coordinator.migratePersistentStore(store, to: sharedFolder, options: nil, withType: storeType)
            UserDefaults.standard.setValue(true, forKey: key)
        }
        catch let error { print(error.localizedDescription) }
    }
}
