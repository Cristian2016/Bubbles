import UIKit
import CoreHaptics

@available(iOS 10.0, *)
public struct UserFeedback {
    public enum Kind {
        case haptic
        case sound
        case visual
    }
    
    @available(iOS 10.0, *)
    public static func triggerSingleHaptic(_ style:UIImpactFeedbackGenerator.FeedbackStyle) {
        let haptic = UIImpactFeedbackGenerator(style: style)
        haptic.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            haptic.impactOccurred()
        }
    }
    
    @available(iOS 10.0, *)
    public static func triggerDoubleHaptic(_ style:UIImpactFeedbackGenerator.FeedbackStyle) {
        UserFeedback.triggerSingleHaptic(style)
        
        let second = UIImpactFeedbackGenerator(style: .heavy)
        second.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            second.impactOccurred()
        }
    }
}

public extension String {
    
    func dottedDurationToComponents(labeled:Bool) -> (hr:String?, min:String?, sec:String?) {
        
        guard !isEmpty, count == 8 else {
            return (nil, nil, nil)
        }
        
            
        let substrings = split(separator: ":")
        
        var strings = [String]()
        
        substrings.forEach { substring in
            strings.append(String(substring))
        }
        
        let labels = ["Hr", "Min", "Sec"]
        
        let timeComponents = strings.map { string -> String? in
            
            if string == "00" {return nil}
            
            else {
                guard let index = strings.firstIndex(of: string) else {
                    fatalError()
                }
                
                if string.first == "0" {
                    var stringCopy = string
                    stringCopy.removeFirst()
                    
                    return labeled ? stringCopy + labels[index] : stringCopy
                }
                return labeled ? string + labels[index] : string
            }
        }
        
        return (hr:timeComponents.first!, min:timeComponents[1], sec:timeComponents.last!)
    }
}
