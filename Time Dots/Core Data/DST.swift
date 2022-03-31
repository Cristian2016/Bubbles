import Foundation
/* credit https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9 */

class DST {
    deinit { killTimer() }
    
    let queue:DispatchQueue
    init(_ queue:DispatchQueue) {
        self.queue = queue
    }
    
    public lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: 1)
        t.setEventHandler(handler: eventHandler)
        return t
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .suspended
    
    //1
    func resume() {
        if state == .resumed {return}
        state = .resumed
        timer.resume()
    }
    
    //2
    func suspend() {
        if state == .suspended {return}
        state = .suspended
        timer.suspend()
    }
    
    //3
    func killTimer() {
        timer.setEventHandler {}
        timer.cancel()
        resume()
        eventHandler = nil
    }
}
