import Foundation

protocol SlotsManagerDelegate:AnyObject {
    var slots:[Int] { get set }
}

class SlotsManager {
    enum SingleSlotState {
        case empty
        case half
        case complete
        
        case unknown //just to return something
    }
    
    enum SlotKind {
        case hours
        case minutes
        case seconds
    }
    
    enum State {
        case sixDigits //complete
        case zeroDigits //empty
        case grows //user touches digits
        case shrinks //user touches delete
        case spins(_ slotKind:SlotKind) //user spins wheel
    }
    
    enum SlotsOperation {
        case edit(_ referenceClock:Float?)
        case create
    }
    
    let operation:SlotsOperation
    
    init(_ operation:SlotsOperation) {
        self.operation = operation
        
        if case SlotsOperation.edit(referenceClock: let referenceClock) = operation {
            state = .sixDigits
            setSlots(from:referenceClock)
        } else {
            state = .zeroDigits
        }
    }
    
    var state:State
    
    // MARK: - Properties
    var isCombinationForbidden:Bool { slots == [0,0,0,0,0,0]}
    
    weak var delegate:SlotsManagerDelegate?
    
    ///minimum is empy array, maximum 6 integers (3 pairs)
    var slots = [Int]() {didSet { delegate?.slots = slots }}
    
    var slotsToReferenceClock:Float {
        get {
            guard allSlotsComplete else { fatalError() }
            
            let dict = [0:3600*10, 1:3600*1, 2:60*10, 3:60*1, 4:10, 5:1]
            
            var bucket = 0
            for (index, integer) in slots.enumerated() {
                bucket += dict[index]! * integer
            }
            
            return Float(bucket)
        }
    }
    
    var slotStates:(h:SingleSlotState, m:SingleSlotState, s:SingleSlotState) {
        switch slots.count {
        case 0:
            return (h: .empty, m: .empty, s:.empty)
        case 1:
            return (h: .half, m: .empty, s:.empty)
        case 2:
            if slots == [4,8] {
                return (h: .complete, m: .complete, s:.complete)
            } else {
                return (h: .complete, m: .empty, s:.empty)
            }
        case 3:
            return (h: .complete, m: .half, s:.empty)
        case 4:
            return (h: .complete, m: .complete, s:.empty)
        case 5:
            return (h: .complete, m: .complete, s:.half)
        case 6:
            return (h: .complete, m: .complete, s:.complete)
        default:
            return (h: .unknown, m: .unknown, s:.unknown)
        }
    }
    
    //maybe 48:00:00 and user starts deleting digits and then wants to add other digits back. well he's not allowed to do that!
    var slotsContainMaxDuration:Bool {
        slots.count > 1 && slots[0...1] == [4,8]
    }
    
    //turns 0 -> 00, 1 -> 01 etc
    let numberFormatter:NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    //used for OK button to show up
    var allSlotsComplete:Bool {
        slotStates == (h: .complete, m: .complete, s:.complete)
    }
    
    // MARK: - Methods
    func appendToSlots(_ digits:String?) {
        guard let digits = digits else { fatalError() }
        
        state = .grows
        
        //it can be either one or two digits
        switch digits {
        case "00":
            slots.append(contentsOf: [0,0])
        default:
            //make sure digit is an integer
            guard let integer = Int(digits) else { fatalError() }
            
            slots.append(integer)
            if slots.count > 1, slots[0...1] == [4,8] {
                slots = [4,8,0,0,0,0]
            }
        }
    }
    
    func replace(_ slotKind:SlotKind, with integer:Int) {
        
        let isIntegerOneDigitLong = integer/10 == 0
        
        //slot must be complete!
        switch slotKind {
        case .hours:
            guard slotStates.h == .complete else { return }
            slots[0...1] = isIntegerOneDigitLong ? [0,integer] : [integer/10, integer%10]
            
        case .minutes:
            guard self.slotStates.m == .complete else { return }
            self.slots[2...3] = isIntegerOneDigitLong ? [0,integer] : [integer/10, integer%10]
            
        case .seconds:
            guard self.slotStates.s == .complete else { return }
            self.slots[4...5] = isIntegerOneDigitLong ? [0,integer] : [integer/10, integer%10]
        }
    }
    
    func emptyLastSlot() {
        guard (1...6).contains(slots.count) else { fatalError() }
        
        state = .shrinks
        slots.removeLast()
    }
    
    func emptyAllSlots() {
        state = .zeroDigits
        slots = []
    }
    
    private func setSlots(from clock:Float?) {
        guard let clock = clock else { fatalError() }
        
        let components = Int(clock).time()
        let hr = components.hr
        let min = components.min
        let sec = components.sec
        
        slots = [hr/10, hr%10, min/10, min%10, sec/10, sec%10]
        delayExecution(.now() + 0.1) {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.slots = self.slots //let the delegate know
        }
    }
    
    // MARK: - Deinit
    deinit {
//        print("SlotsManager deinit")
    }
}
