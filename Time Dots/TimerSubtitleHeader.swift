//
//  TimerSubtitleHeader.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 27.12.2021.
//

import UIKit

class TimerSubtitleHeader: UICollectionReusableView {
    
    static let reuseID = "timerSubtitleHeader"
    
    //reference clock
    @IBOutlet weak var timerDurationLabel: UILabel!
    
    @IBOutlet weak var elapsedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print(#function, "TimerSubtitleHeader")
    }
}
