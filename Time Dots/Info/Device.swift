import UIKit

///it's an enum helping me determine which screen size the app shows on. I use it to dtermine if I shopuld remove one row of circles in the PaletteVC. if the screen is not tall enough, I need to remove one row
public enum Device {
    /*undetermined*/
     case unknown
    
    /*too small for 5 rows*/
    case iPhoneSE
    
    case iPhone6 /*375 667 2*/
    case iPhone6s
    case iPhone7
    case iPhone8
    case iPhoneSE2
    
    case iPhone6Plus /*375 667 3*/
    case iPhone6sPlus
    
    /*big enough for 5 rows*/
    case iPhone7Plus /*414 736 3*/
    case iPhone8Plus
    
    case iPhoneX /*375 812 3*/
    case iPhone11

    public static var current:[Device] {
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        
        if screenSize == CGSize(width: 320, height: 568), scale == 2 {
            return [.iPhoneSE]
        }
        if screenSize == CGSize(width: 375, height: 667), scale == 2 {
            return [.iPhone8, iPhone7, .iPhone6, .iPhone6s, .iPhoneSE2]
        }
        if screenSize == CGSize(width: 375, height: 667), scale == 3 {
            return [.iPhone6Plus, .iPhone6sPlus]
        }
        
        if screenSize == CGSize(width: 414, height: 736), scale == 3 {
            return [.iPhone7Plus, .iPhone8Plus]
        }
        if screenSize == CGSize(width: 375, height: 812), scale == 3 {
            return [.iPhoneX]
        }
        
        return [.unknown]
    }
    ///eg iPhone 8 not tall enough to display all 5 rows in PaletteVC, so using this variable is helpful in determining when I should display 4 rows instead of 5
    public static var currentPhoneNotTallEnough:Bool { UIScreen.main.bounds.height <= 736 }
    private static let phonesNotTallEnough:[Device] = [.iPhoneSE, .iPhone6, .iPhone6s, .iPhone7, .iPhone8, .iPhoneSE2, .iPhone6Plus, .iPhone6sPlus]
}

struct CellsPerPageCalculator {
    // MARK: - private
    private let /* screen */ width = UIScreen.main.bounds.width
    private let height = UIScreen.main.bounds.height
    private let /* screen */ scale = UIScreen.main.scale
    
    // MARK: - public
    var cellsCount:Int {
        let count:Int
        
        //set count here
        switch width {
        case 375/* 8, 12 mini */:
            count = (scale == 2) ? 4 : 5
        case 414/* 8 Plus, iPhone 11 */:
            count = (scale == 2) ? 5 : 4
            if scale == 2 && height == 896 { return 5 }
            if scale == 3 && height == 896 { return 5 }
        case 428 /* 12 Pro Max */: count = 5
        case 390 /* 12 Pro */: count = 5
        default: count = 4
        }
        
        return count
    }
}
