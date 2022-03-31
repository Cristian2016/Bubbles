import UIKit

// MARK: - speechBubble
extension DurationPickerVC {
    fileprivate func animateSpeechBubble() {
        let wobbleAnimation = CAKeyframeAnimation.pendulumSwingAroundCenter(duration: 1)
        
        delayExecution(.now() + 0.2) {
            [weak self] in
            self?.speechBubble.layer.add(wobbleAnimation, forKey: "speechbubble")
        }
    }
    
    // FIXME: implement
    fileprivate func toggleSpeechBubble(show:Bool) {
        if show {
            speechBubbleContainer.addSubview(speechBubble)
            speechBubbleContainer.alpha = 1.0
            
            let yConstant = ViewHelper.statusBarHeight()/2
            speechBubble.centerXAnchor.constraint(equalTo: speechBubbleContainer.centerXAnchor, constant: 0).isActive = true
            speechBubble.centerYAnchor.constraint(equalTo: speechBubbleContainer.centerYAnchor, constant: yConstant).isActive = true
        } else {
            ViewHelper.getSubview(with: speechBubble.restorationIdentifier, in: speechBubbleContainer)?.removeFromSuperview()
            speechBubbleContainer.alpha = 0
        }
    }
    
    // MARK: - Public
    // FIXME: implement
    func updateSpeechBubble(withAnimation:Bool) {
        if slotsAsString.isEmpty {/* show speechBubble */
            toggleSpeechBubble(show: true)
            if withAnimation { animateSpeechBubble() }
            
        } else if slotsAsString.count >= 1 {/* hide */
            toggleSpeechBubble(show: false)
        }
    }
}

