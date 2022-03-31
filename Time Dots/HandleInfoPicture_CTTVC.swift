import UIKit
import CoreData

// MARK: - manage InfoPictures
extension CTTVC: InfoPictureProtocol {
    var superview: UIView {
        view
    }
    func toggleInfoPicture(situation: InfoPictureSituation) {
        
        switch situation {
        case .cttvc: /* user shook the phone */
            if infoPicFoundInSuperview(for: situation) {
                searchInSuperviewInfoPic(for: situation)?.removeFromSuperview()
            } else {
                
                let pic = makeInfoPic(for: situation)
                pic.isUserInteractionEnabled = true
                pic.restorationIdentifier = infoPicName(for: .cttvc)
                pic.addShadow(color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
                
                superview.addSubviewInTheCenter(pic)
            }
            
        case .firstWelcome:/* app launches for the very first time ever! */
            break
            
        case .welcome: /* tableview is empty show info, else hide info */
            guard let isTableViewEmpty = isTableViewEmpty else { return }
            
            if isTableViewEmpty {
                if !self.infoPicFoundInSuperview(for: situation) {
                    let infoPic = self.makeInfoPic(for: situation)
                    infoPic.addShadow(color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                    self.superview.addSubviewInTheCenter(infoPic)
                }
            }
            else { self.searchInSuperviewInfoPic(for: situation)?.removeFromSuperview() }
            
        default:break
        }
    }
}

protocol InfoPictureProtocol {
     var superview:UIView {get}
    func infoPicName(for situation:InfoPictureSituation) -> String
    func makeInfoPic(for situation:InfoPictureSituation) -> UIImageView
    func searchInSuperviewInfoPic(for situation:InfoPictureSituation) -> UIView?
    func infoPicFoundInSuperview(for situation:InfoPictureSituation) -> Bool
    
    func toggleInfoPicture(situation:InfoPictureSituation)
}

extension InfoPictureProtocol {
    func infoPicName(for situation:InfoPictureSituation) -> String {
        situation.rawValue + "_" + "\(Int(UIScreen.main.bounds.height))"
    }
    
    func makeInfoPic(for situation:InfoPictureSituation) -> UIImageView {

        guard let image = UIImage(named: infoPicName(for: situation)) else {fatalError()}
        
        let infoPicture = InfoPicture(image: image)
        infoPicture.restorationIdentifier = infoPicName(for: situation)
        
        /* only welcome pic will not disappear on touch */
        if situation.rawValue != InfoPictureSituation.welcome.rawValue {
            infoPicture.isUserInteractionEnabled = true
        }
        
        infoPicture.contentMode = .scaleAspectFit
        return infoPicture
    }
    
    func searchInSuperviewInfoPic(for situation:InfoPictureSituation) -> UIView? {
        superview.subviews.filter { $0.restorationIdentifier == infoPicName(for: situation)}.first
    }
    
    func infoPicFoundInSuperview(for situation:InfoPictureSituation) -> Bool {
        let result = superview.subviews.filter { $0.restorationIdentifier == infoPicName(for: situation)}
        return result.isEmpty ? false : true
    }
    
    func toggleInfoPicture(situation:InfoPictureSituation) {
            if infoPicFoundInSuperview(for: situation) {
                searchInSuperviewInfoPic(for: situation)?.removeFromSuperview()
            } else {
                let infoPic = makeInfoPic(for: situation)
                infoPic.frame = superview.bounds
                infoPic.addShadow(color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
                superview.addSubviewInTheCenter(infoPic)
            }
    }
}

///for now.. this subclass was needed to remove the info picture when user touches it
class InfoPicture: UIImageView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeFromSuperview()
    }
}
