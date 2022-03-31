//
//  TitleView.swift
//  Time Bubbles
//
//  Created by Cristian Lăpușan on Sat  27.03.2021.
//

import UIKit

class Header: UICollectionReusableView {
    static let reuseID = "header"
    
    //timer only
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    @IBOutlet weak var durationStringStack: UIStackView!
    
    @IBOutlet weak var hoursStack: UIStackView!
    @IBOutlet weak var minutesStack: UIStackView!
    @IBOutlet weak var secondsStack: UIStackView!
    
    //timer and stopwatch
    @IBOutlet weak var titleSymbol: TitleSymbol!
    @IBOutlet weak var containerStack: UIStackView!
    @IBOutlet weak var whiteBackground: ColorBackground1! {didSet {
        whiteBackground.set(cornerRadius: 26, fillColor: .systemBackground)
        whiteBackground.backgroundColor = .clear
    }}
    @IBOutlet weak var colorBackground: ColorBackground1! {didSet {
        colorBackground.set(fillColor: .green)
        colorBackground.backgroundColor = .clear
    }}
}

// MARK: - darkmode lightmode
extension Header {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            guard
                [UIColor.charcoal, .white].contains(colorBackground.fillColor)
            else {return}
                        
            colorBackground.set(cornerRadius: 20, fillColor: isDarkModeOn ? .white : .charcoal)
            titleSymbol.titleLabel.textColor = isDarkModeOn ? .white : .charcoal
            titleSymbol.symbol.tintColor = titleSymbol.titleLabel.textColor
        }
    }
}
