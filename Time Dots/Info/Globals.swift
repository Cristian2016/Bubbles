//
//  Post.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Tue  23.02.2021.
//

import UIKit
import SwiftUI

var superImportant = true
var isMainThread:Bool {
    Thread.isMainThread
}

extension UIImage {
    func combine(with image:UIImage,
                 of scale:CGFloat = 0.5,
                 color:UIColor,
                 in size:CGSize) -> UIImage {
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
                    
        draw(in: CGRect(origin: .zero, size: size))
        image.withTintColor(color).draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    func ofSize(_ size:CGSize, _ color:UIColor? = nil) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        if let tintColor = color {
            withTintColor(tintColor).draw(in: CGRect(origin: .zero, size: size))
        } else {
            draw(in: CGRect(origin: .zero, size: size))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        
        return image
    }
}

extension Color {
    static let lightGray =  Color("lightGray")
    static let darkGray =  Color("darkGray")
    static let mediumGray =  Color("mediumGray")
    static let shadowGray =  Color("shadowGray").opacity(0.4)
}

extension UIView {
    func viewController() -> UIViewController? {
        if let vc = next as? UIViewController { return vc }
        if let parentView = next as? UIView { return parentView.viewController() }
        return nil
    }
}

extension UIView {
    enum Position {
        case bottomCenter
        case topCenter
        case leadingCenter
        case trailingCenter
    }
    
    func position(_ position:Position, _ widthMultiplier:CGFloat = 1.0) {
        guard
            let superview = superview,
            frame.size != .zero else { fatalError() }
        translatesAutoresizingMaskIntoConstraints = false
        
        switch position {
            case .bottomCenter:
                superview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                superview.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                superview.widthAnchor.constraint(equalTo:widthAnchor , multiplier: widthMultiplier).isActive = true
                
            default: break
        }
    }
}

///an array that holds an element for a certain time (lifespan), then removes that element
class EphemeralArray<Element> where Element:Equatable {
    init(lifespan:TimeInterval) { self.dispatchTime = .now() + lifespan }
    private(set) var array = [Element]() {didSet{ if array.isEmpty { timers = [] } }}
    private let dispatchTime:DispatchTime
    private lazy var queue:DispatchQueue = {
        let queue = DispatchQueue(label: "Ephemeral")
        return queue
    }()
    
    private var timers = [DispatchSourceTimer]()
    
    func add(_ element:Element) {
        queue.async {[weak self] in
            guard let self = self else { return }
            
            //add to array
            self.array.append(element) //write
            //set timer
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: self.dispatchTime)
            self.timers.append(timer)
            timer.setEventHandler {
                for (index, item) in self.array.enumerated() {
                    if item == element {
                        self.array.remove(at: index) //write
                        break
                    }
                }
            }
            timer.activate()
        }
    }
}

extension Date {
    var timeOnly:String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }
    
    var dayOnly:String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "E d"
        return formatter.string(from: self)
    }
}

extension String {
    //https://smashswift.com/how-to-add-text-to-file/
    func appendToFile(_ date:Date) {
        let manager = FileManager.default
        let path = manager.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        let url = URL(fileURLWithPath: path.appending("/troubleshoot.text"))
        
        if !manager.fileExists(atPath: url.path) {
            manager.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
                
        guard
            let handle = try? FileHandle(forWritingTo: url),
            let textData = data(using: .utf8) else { return }
        
        try! handle.seekToEnd()
        try! handle.write(contentsOf: textData)
        try! handle.close()
//        print("duration ", Date().timeIntervalSince(date))
    }
}

extension CGRect {
    enum Dimension {
        case fractional(CGFloat)
        case absolute(CGFloat)
    }
    
    func concentric(x offsetX:Dimension, y offsetY:Dimension) -> CGRect {
        
        let newWidth:CGFloat
        let newHeight:CGFloat
        
        switch offsetX {
        case .fractional(let value):
            guard value >= 0 else { fatalError() }
            newWidth = size.width * value
        case .absolute(let value):
            newWidth = size.width + 2 * value
        }
        
        switch offsetY {
        case .fractional(let value):
            guard value >= 0 else { fatalError() }
            newHeight = size.height * value
        case .absolute(let value):
            newHeight = size.height + 2 * value
        }
        
        let concentricOrigin = CGPoint(x: origin.x - (newWidth - size.width)/2, y: origin.y - (newHeight - size.height)/2)
        let concentricSize = CGSize(width: newWidth, height: newHeight)
        return CGRect(origin: concentricOrigin, size: concentricSize)
    }
}


extension String {
    // FIXME: not done!
    func split(into segmentLength:Int) -> [String] {
        
        var bucket = [String]()
        var subbucket = String()
        
        for (_, char) in enumerated() {
            subbucket.append(char)
            if subbucket.count == segmentLength {
                bucket.append(subbucket)
                subbucket = String()
            }
        }
        return bucket
    }
}


extension Int {
    ///used in durationPickerVC
    var secondsFormat:String? {
        //2 integer digits. ex: 2 -> 02, 12 -> 12, 9 -> 09
        let formatter:NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = 2
            return formatter
        }()
        
        return formatter.string(from: NSNumber(integerLiteral: self))
    }
}

public extension UIView {
    func disable(_ isDisabled:Bool) {
        isUserInteractionEnabled = isDisabled ? false : true
        alpha = isDisabled ? 0.1 : 1.0
    }
}

extension Array {
    var randomIndex:Int {
        Int(arc4random_uniform(UInt32(count - 1)))
    }
}

var isScreenHighResolution:Bool {
    UIScreen.main.scale > 2
}

public extension NumberFormatter {
    //2 integer digits. ex: 2 -> 02, 12 -> 12, 9 -> 09
    static let secondsStyleFormatter:NumberFormatter  = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
}

struct Speed {
    static let needleMover = 20 /* times per second */
}

struct EntityName {
    static let ct = "CT"
}

typealias LongPress = UILongPressGestureRecognizer

struct Segue {
    private init(){}
    static let toDetailVC = "toDetailVC"
    static let toPaletteVC = "toPaletteVC"
    static let toTimerDurationVC = "toTimerDurationVC"
}
struct Cell {
    private init(){}
    static let ctCell = "chronoTimerCell"
    static let timerCell = "timerCell"
}
struct VC {
    private init(){}
    static let chronoTimers = "ChronoTimersTVC"
    static let palette = "PaletteVC"
    static let timerDuration = "TimerDurationVC"
    static let detail = "DetailVC"
}

struct Duration {
    private init(){}
    static let vcTransition = 0.35
}

struct GestureProperties {
    static let pushVelocityX:CGFloat = 1500
    static let popVelocityX:CGFloat = -1500
}

///tags used for various views such as infoLabel etc
struct /*View*/Tag {
    static let infoView = "infoView"
}
struct RestorationID {
    static let whiteMarbel = "whiteMarbel"
    ///table view's cell's contentView
    static let contentView = "contentView"
}

struct Info {
    struct CTTVC {
        static let title = "Make a new timer or chronometer"
        static let subtitle = "|→ Swipe right from the left screen edge"
    }
    
    struct Palette {
        static let title = "Choose a color"
        static let subtitle = "Long press for timer or tap for chronometer"
    }
    
    struct TimerDuration {
        enum Moment {
            case start
            case editing
            case complete
        }
        static let title:[Moment:String] = [
            .start : "Enter up to 48 Hours",
            .editing : "Bla",
            .complete : "It's complete"
        ]
        static let subtitle:[Moment:String] = [
            .start : String.empty,
            .editing : "Hr:Min:Sec",
            .complete : "Done"
        ]
    }
}

struct UI {
    struct Constants {
        static let marbelDistanceFromTopMargin = CGFloat(12)
        static let marbelDiameter = CGFloat(0.19)
    }
}

enum InfoPictureSituation:String {
    case firstWelcome
    case welcome
    case cttvc
    case palette
    case durationPicker
    case speechBubble
}

///userdefaults key
struct UDKey {
    static let localNotificationsAuthorizationRequestedAlready = "localNotificationsAuthorizationRequestedAlready"
    static let calendarAuthorizationRequestedAlready = "calendarAuthorizationRequestedAlready"
    static let ctsCount = "ctsCount"
    static let defaultCalendarIdentifier = "defaultCalendarIdentifier"
    
    static let notificationReceivalMoment = "notificationReceivalMoment"
    static let infoBannerNotShownAlready = "infoBannerNotShownAlready"
    
    static let widgetEnabledTimeBubble = "widgetEnabledTimeBubble"
    static let isCoreDataShared = "isCoreDataShared"
    static let shouldExplainingTextBeVisible = "shouldExplainingTextBeVisible"
    
    static let firstAppLaunchEver = "firstAppLaunchEver"
    static let quickStartGuidePresentedAlready = "quickStartGuidePresentedAlready"
}

struct ViewControllerID {
    static let paletteVC = "PaletteVC"
    static let chronoTimersTVC = "ChronoTimersTVC"
    static let timerDurationVC = "TimerDurationVC"
    static let detailVC = "DetailVC"
}

struct Post {
    static let didBecomeActive = UIApplication.didBecomeActiveNotification
    static let didEnterBackground = UIScene.didEnterBackgroundNotification
    static let willTerminate = UIApplication.willTerminateNotification
    
    static let needleUpdated = Notification.Name("needleUpdated")
    static let offscreenDurationUpdated = Notification.Name("offscreenDurationUpdated")
    static let timerReachedZero = NSNotification.Name("timerReachedZero")
    
    static let textFieldDidBeginEditing = NSNotification.Name("textFieldDidBeginEditing")
    
    //debug only! ⚠️
    static let pairComplete = NSNotification.Name("pairComplete")
    
    //
    static let animatePairCell = NSNotification.Name("animatePairCell")
}

// TODO: fix dateformatter
extension DateFormatter {
    func  bubbleStyle(_ date:Date) -> String {
        
        locale = Locale(identifier: "ro_RO")
        dateStyle = .full
        timeStyle = .medium
        calendar = Calendar(identifier:.gregorian)
        weekdaySymbols =  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        monthSymbols = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec"]
        let result = string(from: date)
        
        return result
    }
}

extension NumberFormatter {
    ///formats digits. ex: 9 -> 09 , 10 -> 10, 3 -> 03
    static let zeroPadding:NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    func intAsString(_ int:Int) -> String? {
        string(from: NSNumber(integerLiteral: int))
    }
}

extension UIColor {
    static let charcoal = UIColor.rgb(33, 33, 33)
    static let chocolate = UIColor.rgb(102, 65, 52)
    static let bubbleRed = #colorLiteral(red: 0.9946810603, green: 0.05774473399, blue: 0.01797534339, alpha: 1)
}

extension Array {
    // FIXME: -better name!!!!
    mutating func makePairs(ignoring firstItems:Int) -> [(Element, Element?)] {
        guard firstItems < count else {return []}
        
        removeFirst(firstItems)
        
        var evenBucket = [Element]()
        var oddBucket = [Element]()
        
        for index in 0..<count {
            if index%2 == 0 {
                evenBucket.append(self[index])
            } else {
                oddBucket.append(self[index])
            }
        }
        
        var pairs = [(Element, Element?)]()
        for index in 0..<oddBucket.count {
            pairs.append((evenBucket[index], oddBucket[index]))
        }
        
        if oddBucket.count < evenBucket.count {
            pairs.append((evenBucket.last!, nil))
        }
        
        return pairs
    }
}

extension UILabel {
    var image:UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {fatalError()}
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    ///puts a label on it and then apend it as if it's the label itself
    func addBackground(cornerRadius:CGFloat = 15.0, _ color:UIColor = .clear, inverseInsets:(w:CGFloat, h:CGFloat) = (1.1,1.1)) -> UILabel {
        guard superview == nil else {
            fatalError("put background first then add it to a superview")
        }
        
        let background = UIView()
        
        //maybe you want to use you method to remove a view from superview by its restorationIdentifier
        background.restorationIdentifier = restorationIdentifier
        
        //add background first and then set constraints
        addSubview(background)
        
        //set constraints
        background.translatesAutoresizingMaskIntoConstraints = false
        background.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        background.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        background.widthAnchor.constraint(equalTo: widthAnchor, multiplier: inverseInsets.w, constant: 0).isActive = true
        background.heightAnchor.constraint(equalTo: heightAnchor, multiplier: inverseInsets.h, constant: 0).isActive = true
        
        //set color and shit
        background.layer.cornerRadius = cornerRadius
        background.backgroundColor = color
        
        return self
    }
}

extension Array {
    func intersect(with secondArray:[Element]) -> [Element] where Element:Equatable {
        
        let maxCount = Swift.max(count, secondArray.count)
        
        var longerArray = [Element]()
        var shorterArray = [Element]()
        
        if count == maxCount {
            longerArray = self
            shorterArray = secondArray
        } else {
            longerArray = secondArray
            shorterArray = self
        }
        
        let result = longerArray.compactMap { newValue -> Element? in
            
            guard let index = shorterArray.firstIndex(of: newValue) else {return newValue}
            
            if shorterArray[index] == newValue {return nil}
            return newValue
        }
        
        return result
    }
    
    //splits into pairs and the rest is as remainder
    func split(intoPairs pairCount:Int) -> (pairs:[[Element]], remainder:[Element]) {
        guard pairCount != 0 else { fatalError() }
        
        var buckets = [[Element]]()
        var bucket = [Element]()
        var remainder = [Element]()
        
        for (index, int) in enumerated() {
            if index%pairCount == 0 && !bucket.isEmpty{
                buckets.append(bucket)
                bucket = []
            }
            bucket.append(int)
        }
        
        if bucket.count == pairCount {
            buckets.append(bucket) //the last bucket must be added too!
        } else {
            remainder = bucket
        }
        
        return (buckets, remainder)
    }
}

extension NSMutableAttributedString {
    func durationPickerStyle(kern:CGFloat = -3) -> NSAttributedString {
        
        let range0 = NSRange(location: 1, length: 1)
        addAttribute(NSAttributedString.Key.kern, value: -3, range: range0)
        
        let range1 = NSRange(location: 8, length: 1)
        addAttribute(NSAttributedString.Key.kern, value: -3, range: range1)
        
        let range2 = NSRange(location: 14, length: 1)
        addAttribute(NSAttributedString.Key.kern, value: -3, range: range2)
        
        return self
    }
}

extension UserDefaults {
    
    struct Key {
        static let isAnimationOnAppearEnabled = "isAnimationOnAppearEnabled"
    }
    
    enum DateUsage:String, CustomStringConvertible {
        var description: String { rawValue }
        
        case appWillTerminate
        case appDidEnterBackground
    }
    
    func saveDate(_ date:Date, key:DateUsage) {
        DispatchQueue.global().async {
            UserDefaults.standard.setValue(date, forKey: key.rawValue)
        }
    }
    func retrieveDate(key:DateUsage) -> Date? {
        if let date = UserDefaults.standard.value(forKey: key.rawValue) as? Date {
            return date
        } else { return nil }
    }
    
    ///if key is nil {set key to true} else {set it to false}
    func manage_FirstAppLaunchEver_Key() {
        let key = UDKey.firstAppLaunchEver
        if UserDefaults.standard.value(forKey: key) == nil {
            UserDefaults.standard.set(true, forKey: key)
        } else {
            UserDefaults.standard.set(false, forKey: key)
        }
    }
    
    func manage_QuickStartGuideDone_Key() {
        let key = UDKey.quickStartGuidePresentedAlready
        if UserDefaults.standard.value(forKey: key) == nil {
            UserDefaults.standard.set(false, forKey: key)
        }
    }
}

extension FileManager {
    func storeInDocs(_ content:String) {
        guard let docDir =
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let filePath = docDir.appendingPathComponent("myFile.txt").path
        try? content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
    
    func appendToDocs(_ content:String) {
        guard let docDir =
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let filePath = docDir.appendingPathComponent("myFile.txt").path
        
        if let fileHandle = FileHandle(forWritingAtPath: filePath) {
            
            fileHandle.seekToEndOfFile()
            if let data = (" \n" + content).data(using: .utf8) {
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
}

extension Int {
    func timeAsString() -> String {
        let components = time()
        let hr = components.hr
        let min = components.min
        let sec = components.sec
        
        let hours = (hr > 0) ? String(hr) + " h " : String.empty
        let minutes = (min > 0) ? String(min) + " m " : String.empty
        let seconds = (sec > 0) ? String(sec) + " s" : String.empty
        
        return (hours + minutes + seconds)
    }
    var isEven:Bool { self%2 == 0 ? true : false }
}

extension TimeInterval {
    func timeAsString() -> String {
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        let components = time()
        let hr = components.hr
        let min = components.min
        let sec = components.sec as Double
        let secString = formatter.string(from:NSNumber(value: sec))!
        
        let hours = (hr > 0) ? String(hr) + " h " : String.empty
        let minutes = (min > 0) ? String(min) + " m " : String.empty
        let seconds = (secString != "0") ? secString + " s" : String.empty
        
        return (hours + minutes + seconds)
    }
}

func delayExecution(_ delay:DispatchTime, code:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: delay, execute: code)
}

extension UIViewController {
    func viewController(with identifier:String, from storyboardName:String = "Main") -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(identifier: identifier)
    }
}

extension Data {
    ///credit: Kilo Loco tutorial on push notifications
    var deviceToken:String {
        //the device token is like a combined address of 1.the device and 2.the app using the push notification service. any push notification you want to send to the device, send it on this address!
        map { String(format: "02.2hhx", $0) }
            .joined()
    }
}

extension NSUserActivity {
    ///title is what the user sees
    static func activity(_ title:String, _ activityType:String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: activityType)
        activity.isEligibleForPrediction = true
        activity.isEligibleForSearch = true
        return activity
    }
}

public extension UIColor {
    ///get color from rgb values such as 233 83 92
    static func rgb(_ red:Int, _ green:Int, _ blue:Int) -> UIColor {
     UIColor(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
     }
 }

extension FileManager {
    static func sharedContainerURL () -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.widgetExtensionGroup")
    }
    static func sharedFile() -> URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.widgetExtensionGroup")!.appendingPathExtension("WidgetBucket")
    }
}

extension String {
    ///if user enters "Gym ", it will be corrected to "Gym"
    mutating func trimWhiteSpaceAtTheEnd() {
        while last == " " { removeLast() }
    }
    mutating func trimWhiteSpaceAtTheBeginning() {
        while first == " " { removeFirst() }
    }
    
    mutating func removeAllWhiteSpace() {
        trimWhiteSpaceAtTheBeginning()
        trimWhiteSpaceAtTheEnd()
    }
    
    ///empty string: ""
    static let empty = ""
    
    static let space = " "
}

extension UITextField {
    ///used in Time Bubbles App
    func setupAsStickyNote() {
        autocorrectionType = .no
        autocapitalizationType = .sentences
        keyboardType = .alphabet
    }
}

extension UIPickerView {
    func changeSelectionViewLook(borderWidth:CGFloat = 4.0, borderColor:UIColor? = .black) {
        //make sure selectionView is in the usual spot
        guard let selectionView = subviews.last else {
            fatalError("selection view not there. yet?")
        }
        
        selectionView.backgroundColor = nil
        selectionView.layer.borderColor = (borderColor ?? .clear).cgColor
        selectionView.layer.borderWidth = borderWidth
    }
}

extension UserDefaults {
    //ex.: show on OkButton, 3 times only!, the following text: "Tap to change Duration"
    static let showInfoTimes = 3
    
    enum Info:String {
        case editDurationVC_ShowExtraText
        case durationPickerVC_ShowExtraText
    }
}

extension UIView {
    func enableAutolayout(_ enable:Bool) {
        translatesAutoresizingMaskIntoConstraints = enable ? false : true
    }
    
    ///view.frame in screen window coordinate system
    func absoluteFrame() -> CGRect {
        guard window != nil else { fatalError("no window")}
        return convert(bounds, to: nil)
    }
    
    ///(midX,midY) point  in screen window coordinate system
    func absoluteCenter() -> CGPoint {
        guard window != nil else { fatalError()}
        let centerInOwnCoordinateSpace = CGPoint(x: bounds.midX, y: bounds.midY)
        return convert(centerInOwnCoordinateSpace, to: nil)
    }
    
    ///the entire frame of the view must be visible to the user
    var isFullyVisibleOnscreen:Bool {
        let screenHeight = UIScreen.main.bounds.height
        let absoluteFrame = absoluteFrame()
        let condition0 = absoluteFrame.origin.y >= 0
        let condition2 = absoluteFrame.origin.y + absoluteFrame.height <= screenHeight
        
        return (condition0 && condition2) ? true : false
    }
}
