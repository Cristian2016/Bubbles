import Foundation

typealias Characters = CharacterSet

class TimerDurationInputManager {
    public enum UserAction {
        case appendNewDigits(String)
        case deleteLastDigit
        case clearExistingDigits
    }
    
    /*the button down left has "00" string and it will be interpreted as character "*"*/
    private let doubleZero = Characters(charactersIn: "*")
    
    public func update(oldValue oldDisplayedDuration: String, with userAction:UserAction) -> String {
        
        var result = oldDisplayedDuration
        
        switch userAction {
        case .appendNewDigits(let newDigits):
            if (oldDisplayedDuration.count == 0) { result = newDigits }
            else {
                result = oldDisplayedDuration + newDigits
            }
            
            if // append ":" eg. 23 -> 23:
                [1,4].contains(oldDisplayedDuration.count) && result != "48" ||
                    [0, 3].contains(oldDisplayedDuration.count) && newDigits == "00" {
                result += ":"
            }
            
        case .deleteLastDigit:
            let lastCharacter = oldDisplayedDuration.last!
            if lastCharacter == ":" { result.removeLast() }
            result.removeLast()
            
        case .clearExistingDigits: result = String.empty
        }
        
        return result
    }
    
    /// used by DurationPicker viewController to disable specified characters
    public func charactersToDisable(for string:String?) -> Characters {
        guard let string = string else {return Characters()}
        
        if (string == "48") {return Characters(charactersIn: "0123456789").union(doubleZero)}
        if (string == "00000") {return Characters(charactersIn: "0").union(doubleZero)}
        if (string == "0000") {return doubleZero.union(Characters(charactersIn: "6789"))}
        
        switch string.count {
        case 0: return Characters(charactersIn: "56789✕")
        case 1, 3, 5:
            return (string == "4") ? Characters(charactersIn: "9").union(doubleZero) : Characters().union(doubleZero)
        case 2: return Characters(charactersIn: "6789")
        case 4: return Characters(charactersIn: "6789")
        case 6: return Characters(charactersIn: "0123456789").union(doubleZero)
        default: return Characters(charactersIn: "✕")
        }
    }
}
