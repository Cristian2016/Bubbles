//
//  CT+CoreDataClass.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Tue  23.02.2021.
// https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9

import CoreData
import UIKit

public class CT: NSManagedObject {
    let maxStickyCount = 100 //100 stickies/ bubble
    static let recentlyUsedDurationsLimit = 8
    private(set) var sessionsCountLimit = 15
    var lastUsedTimerDuration:Float?
    
    // MARK: -
    //use this value to populate content of cells when ct.running since currentClock hasn't been corrected
    private(set) var fakeClock:Int?
    
    // MARK: -
    deinit { print("CT deinit") }
    
    enum TapKind {
        case start
        case pause
    }
    
    var bubbleSessions:[Session] { sessions?.array as? [Session] ?? [] }
    
    ///last added session
    var currentSession:Session? {
        guard !bubbleSessions.isEmpty else { return nil }
        return bubbleSessions.last!
    }
    
    // MARK: -
    private func startCounter(from value:Float) {
        /*
         makes copy of value
         sets handler (to increase or decrease)
         starts and notifies every second
         */
        
        var valueCopy = value
        
        if state != .zeroTimer, counter == nil {
            counter = DST(backgroundQueue)
            
            counter?.eventHandler = {[weak self] in
                let needle = Int(valueCopy.rounded(.toNearestOrEven))
                let message = ["needle":needle]
                
                //CTTVC will use fakeValue to set running time bubbles to that value on cellForRowAtIndexPath
                DispatchQueue.main.async {
                    self?.fakeClock = needle
                    self?.sendToCTTVC(Post.needleUpdated, message)
                }
                
                switch self?.kind {
                case .stopwatch: valueCopy += 1
                case .timer(limit: _): valueCopy -= 1
                default: break
                }
            }
        }
        counter?.resume()
    }
    
    private func stopCounter() {
        counter?.suspend()
        counter?.eventHandler = {}
        counter = nil
    }
    
    // MARK: -
    func run(_ mode:RunMode) {
        guard state != .zeroTimer else {return}
        if state == .brandNew { createNewSession() }
        
        switch mode {
        case .user: /* user tapped start button */
            guard state != .running else {fatalError()}
            
            state = .running
            updatePairs()
            startCounter(from: currentClock)
            
        case .system: /* app returned from background */
            recalibrateClock()/* runs on background thread! so you have to call startCounter afterwards */
        }
    }
    
    func pause(_ mode:RunMode) {
        guard state == .running, state != .zeroTimer else { return }
        
        switch mode {
        case .user:
            state = .paused
            stopCounter()
            
            self.updatePairs()
            recalibrateClock()
            
        case .system: //paused when app enters background or killed
            stopCounter()
            CoreDataStack.shared.saveContext()
        }
    }
    
    func endCurrentSession() { /*
                                make sure state is not brandnew
                                state = paused
                                stop counter
                                add new time point
                                recalibrate clock
                                
                                - with delay
                                - reset currentClock to reference
                                - notify CTTVC about the new currentClock value
                                */
        guard state != .brandNew  else {
            sessionEndedByUser = nil
            return
        }
        
        currentSession?.isEnded = true
        
        if state == .running {
            pause(.user) /*
                          state = .paused
                          stopCounter
                          update time points
                          ♦️ recalibrate clock
                          */
        }
        else { sessionEndedByUser = nil }
        
        state = .brandNew //next time user taps start, a new session will be created
        delayExecution(.now() + 0.1) { /*
                                        reset currentClock with slight delay since ♦️ recalibrateClock starts on a background thread and without delay this would be set first and then recalibrateClock would write the wrong value instead
                                        */
            [weak self] in
            guard let self = self else { return }
            
            self.currentClock = self.referenceClock
            let message = ["needle":Int(self.currentClock)]
            
            self.sendToCTTVC(Post.needleUpdated, message)
            CoreDataStack.shared.saveContext()
        }
    }
    
    //current session deleted
    func reconfigure(for sessionDeletion: SessionDeletion) {
        /* user uses the contextual menu in DetailVC to delete a session, if the user deletes the first session, you need to make sure it will not..... finish text here... */
        if case sessionDeletion = SessionDeletion.currentSession {
            state = .brandNew //0︎⃣
            currentClock = referenceClock //1︎⃣
            let message = ["needle":Int(self.currentClock)]
            sendToCTTVC(Post.needleUpdated, message) //2︎⃣
        }
    }
    
    enum SessionDeletion {
        case currentSession
        case otherSession
    }
    
    func declareZeroTimer() {
        state = .zeroTimer
        updatePairs()
        stopCounter()
        /* 2 */currentClock = 0.0
        CoreDataStack.shared.saveContext()
    }
    
    let backgroundQueue = DispatchQueue(label: "queue")
    
    /*
     recalibrate called in one of 4 situations
     1.timer reaches zero
     2.user pauses
     3.user ends a bubble
     4.app back online
     */
    ///currentClock updated when timer reaches zero, user pauses bubble
    private func recalibrateClock() {
        backgroundQueue.async {
            //make sure Bubble has at least one pair (at least one start)
            guard
                let pairs = self.currentSession?._pairs,
                !pairs.isEmpty else { return }
            
            let isLastPairClosed = self.currentSession!.isLastPairClosed
            
            switch isLastPairClosed {
            case true: //user has just paused
                let lastPairDuration = Float(TimeInterval(pairs.last!.duration))
                
                /* ⚠️ time dot paused by the user, so clock updates with the real value */
                DispatchQueue.main.async {
                    switch self.kind {
                    case .stopwatch: self.currentClock  += lastPairDuration
                    case .timer(limit: _): self.currentClock  -= lastPairDuration
                    }
                    
                    let message = ["needle":Int(self.currentClock.rounded(.toNearestOrEven))]
                    self.sendToCTTVC(Post.needleUpdated, message)
                    CoreDataStack.shared.saveContext()
                }
                
            case false: //🟩 app is back foreground. bubble still running or .zeroTimer
                let lastStart = pairs.last!.start!
                                
                DispatchQueue.main.async {
                    //duration since last start until now
                    let elapsed_Since_LastStart = Float(Date().timeIntervalSince(lastStart)).rounded(.toNearestOrEven)
                    
                    var totalActiveDurationUntilNow:Float = 0.0
                    
                    switch self.kind {
                    case .stopwatch:
                        totalActiveDurationUntilNow = self.currentClock + elapsed_Since_LastStart
                        self.startCounter(from:totalActiveDurationUntilNow)
                        
//                        if self.stickyNote == "Outdoor" {
//                            ("\(Date().timeOnly) cclock " + String(self.currentClock) + " elapsed " + String(elapsed_Since_LastStart) + "\n").appendToFile(Date())
//                        }
                        
                    case .timer(limit: _):
                        totalActiveDurationUntilNow = self.currentClock - elapsed_Since_LastStart
                        
                        if totalActiveDurationUntilNow > 0 {
                            self.startCounter(from: totalActiveDurationUntilNow)
                        } else {
                            //declare zeroTimer?
                            self.stopCounter()
                            self.currentClock = 0.0
                            self.state = .zeroTimer
                            
                            let message = ["needle":Int(self.currentClock)]
                            self.sendToCTTVC(Post.needleUpdated, message)
                        }
                    }
                    CoreDataStack.shared.saveContext()
                }
            }
        }
    }
    
    // MARK: -
    var userNeedle:Int { Int(currentClock.rounded(.toNearestOrEven)) }
    
    // MARK: -
    var kind:Kind {
        get { (referenceClock == 0) ? .stopwatch : .timer(limit: Int(referenceClock)) }
        set {
            switch newValue {
            case .stopwatch: referenceClock = 0
            case .timer(limit: let limit): referenceClock = Float(limit)
            }
        }
    }
    
    var kindDescription:String {
        switch kind {
        case .stopwatch:
            return (!stickyNote.isEmpty) ? "\(stickyNote)" : "\(color!)"
            
        case .timer(limit: _):
            return (!stickyNote.isEmpty) ? "\(stickyNote)" : (color ?? "")
        }
    }
    
    var state:State {
        get { State(rawValue: stateCD ?? "brandNew") ?? State.brandNew }
        set {
            stateCD = newValue.rawValue
            //            print("new state \(state)")
        }
    }
    
    // MARK: -
    var counter:DST?
    private let context = CoreDataStack.shared.viewContext
    
    // MARK: - Methods
    
    func assignUniqueRank() -> Int32 {
        let key = UDKey.ctsCount
        
        if var ctsCount = UserDefaults.standard.value(forKey: key) as? Int32 {
            
            ctsCount += 1
            UserDefaults.standard.setValue(ctsCount, forKey: key)
            return ctsCount
        } else {
            //make and store first value
            UserDefaults.standard.setValue(Int32(0), forKey: key)
            return 0
        }
    }
    
    func populate(color:String, kind:Kind) {
        
        //assign rank since order matters
        self.rank = assignUniqueRank()
        
        self.kind = kind
        self.color = color
        self.created = Date()
        self.id = UUID()
        
        switch kind {
        case .stopwatch:
            self.referenceClock = 0
            
        case .timer(limit: let limit):
            self.referenceClock = Float(limit)
        }
        
        currentClock = referenceClock //mutableClock starts from reference clock
    }
    
    // MARK: -
    var sessionEndedByUser:Bool?
    
    private func updatePairs() {
        guard let currentSession = currentSession else { return }
        var date = Date()
        
        //automatically closing pair of zeroTimer
        if state == .zeroTimer && !currentSession.isLastPairClosed {
            date = adjustedDateOfEndedTimer()
        }
        
        if let sebtu = sessionEndedByUser, sebtu {
            date = date.addingTimeInterval(-0.5)
            sessionEndedByUser = nil
        }
        currentSession.updatePairs(date)
    }
    
    // MARK: - structs and enums
    enum Kind {
        case timer(limit:Int)
        case stopwatch
    }
    
    enum State:String {
        case brandNew
        case running
        case paused
        case zeroTimer
    }
    
    enum RunMode {
        case user/* triggered */
        case system/* triggered */
    }
    
    var _isCalendarEnabled:Bool {
        get { isCalendarEnabled }
        set {
            isCalendarEnabled = newValue
            _calendarStickerState = isCalendarEnabled ? .fullyDisplayed : .hidden
        }
    }
    
    var _calendarStickerState:CalendarStickerState {
        get {
            switch calendarStickerState {
            case 0: return .hidden
            case 2: return .fullyDisplayed
            case 1: return .minimized
            case 3: return .behindStickyNote
            default: return .hidden
            }
        }
        set {
            switch newValue {
            case .hidden: calendarStickerState = Int16(0)
            case .minimized: calendarStickerState = Int16(1)
            case .fullyDisplayed: calendarStickerState = Int16(2)
            case .behindStickyNote: calendarStickerState = Int16(3)
            }
        }
    }
    
    enum CalendarStickerState {
        case hidden //timeBubble NOT calendar enabled
        case minimized
        case fullyDisplayed
        case behindStickyNote
    }
    
    func changeCurrentState(to newState:State) {state = newState}
}

// MARK: - used by marble
extension CT {
    
    func currentAngularFractionComplete(isEstimated:Bool) -> (remainingDuration:TimeInterval, reachedAngle:CGFloat) {
        
        if isTimer && state == .brandNew { return (remainingDuration:TimeInterval(referenceClock), reachedAngle:0) }
        guard
            isTimer,
            let currentSession = currentSession
        else {fatalError()}
        
        let now = Date()
        
        if !currentSession.isLastPairClosed {
            
            let timeElapsedSince_Last_UserTapStart = now.timeIntervalSince(currentSession._pairs.last!.start!)
            let totalLeftDuration = (referenceClock - currentClock)
            
            let fractionComplete = (totalLeftDuration + Float(timeElapsedSince_Last_UserTapStart)) / referenceClock
            
            let angleFractionComplet = 2*CGFloat.pi * CGFloat(fractionComplete)
            let duration = TimeInterval((1 - fractionComplete) * referenceClock)
            
            return (duration, angleFractionComplet)
            
        } else {
            
            let fractionComplete = CGFloat(1.0 - (currentClock/referenceClock)) /* ⚠️ */
            let duration = TimeInterval((1 - Float(fractionComplete)) * referenceClock)
            let angleFractionComplete = 2*CGFloat.pi*fractionComplete
            
            return (duration, angleFractionComplete)
        }
        
    }
}

// MARK: - little helpers
extension CT {
    
    var isTimer:Bool {
        if case Kind.stopwatch = kind { return false }
        return true
    }
    
    private func sendToCTTVC(_ post: NSNotification.Name, _ info:[String:Int]?) {
        NotificationCenter.default.post(name: post, object: self, userInfo: info)
    }
    
    private func adjustedDateOfEndedTimer() -> Date {
        guard
            isTimer, state == .zeroTimer,
            let lastStart = currentSession?._pairs.last?.start,
            let currentSessionTotalDuration = currentSession?.totalDuration()
        else { return Date() }
        
        let amountToAdjust = TimeInterval(referenceClock) - currentSessionTotalDuration
        
        return lastStart.addingTimeInterval(amountToAdjust)
    }
}

// MARK: - creating and deleting sessions
extension CT {
    
    ///method called each time state resets back to brandNew
    private func createNewSession() {
        
        let session = Session(context: managedObjectContext!)
        session.created = Date()
        addToSessions(session)
        CoreDataStack.shared.saveContext()
        
        deleteSessionIfTooMany()
    }
    
    //call this right after new session created!
    private func deleteSessionIfTooMany() {
        guard bubbleSessions.count > sessionsCountLimit else { return }
        CoreDataStack.shared.viewContext.delete(bubbleSessions.first!)
    }
}

// MARK: - Timer Durations
extension CT {
    //only timers have this property set!
    var timerDurationsArray:[TimerDuration] {
        guard isTimer else { fatalError("must be a timer!") }
        
        let descriptor = NSSortDescriptor(key: "date", ascending: false)
        return timerDurations?.sortedArray(using: [descriptor]) as? [TimerDuration] ?? []
    }
    
    func getDurationsHistory() -> [Float] {
        guard isTimer else { fatalError("must be a timer!") }
        
        var bucket = [Float]()
        timerDurationsArray.forEach {
            bucket.append($0.duration)
        }
        
        return bucket
    }
    
    func durationIsUnique(_ proposedDuration:Float) -> Bool {
        guard isTimer else { fatalError("must be a timer!") }
        
        let result = timerDurationsArray.filter({ $0.duration == proposedDuration })
        return result.isEmpty ? true : false
    }
}
