//
//  Extensions.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 15.06.2021.
//

import Foundation

public extension Int {
    func time() -> (hr:Int, min:Int, sec:Int) {
        let minutesAndSeconds = self%3600
        let minutes = minutesAndSeconds/60
        let seconds = minutesAndSeconds%60
        
        return (self/3600, minutes, seconds)
    }
}
public extension TimeInterval {
    //pula mea de conversie
    func time() -> (hr:Int, min:Int, sec:TimeInterval) {
        
        let roundedSeconds = Int(rounded(.down))
        let minutesAndSeconds = roundedSeconds%3600
        var minutes = minutesAndSeconds/60
        let seconds = minutesAndSeconds%60
        
        let secondsFloatRest =  self - TimeInterval(Int(self))
        let result = TimeInterval(Int(secondsFloatRest*100))/100
        
        var hpSeconds = TimeInterval(seconds) + result
        if hpSeconds.rounded(.toNearestOrEven) == 60 {
            hpSeconds = 0
            minutes += 1
        }
        
        return (roundedSeconds/3600, minutes, hpSeconds)
    }
}
