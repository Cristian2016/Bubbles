//
//  Segues.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 29.12.2021.
//

import UIKit

// MARK: - transition to DetailVC
extension CTTVC {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" {
            guard
                let detailVC = segue.destination as? DetailVC,
                let cell = sender as? CTCell,
                let cellIndexPath = tableView.indexPath(for: cell)
            else {fatalError()}
            
            //pass timeBubble to DetailVC
            let bubble = frc.object(at: cellIndexPath)
            detailVC.bubbleID = bubble.id
        }
        
        if segue.identifier == "toEditDurationVC" {
            guard
                let editDurationVC = segue.destination as? EditDurationVC,
                let cell = sender as? CTCell,
                let indexPath = tableView.indexPath(for: cell)
            else {fatalError()}
            
            //hide digits on the cell before showing the wheels
            cell.coverTimeComponents(true)
            
            //hide duration
            cell.durationSecondsLabel.textColor = .clear
            cell.durationMinutesLabel.textColor = .clear
            cell.durationHoursLabel.textColor = .clear
            
            //payload passed to destination VC
            /*
             centers for all time components so that wheels can position themselves exactly in that spot
             */

            //centers and frame to position whhels and okButton
            let secondsCenter = cell.secondsButton.absoluteCenter()
            let minutesCenter = cell.minutesLabel.absoluteCenter()
            let hoursCenter = cell.hoursLabel.absoluteCenter()
            
            let centers =
            TimeComponentsCenters(seconds: secondsCenter,
                                  minutes: minutesCenter,
                                  hours: hoursCenter)
            
            editDurationVC.cellFrame = cell.absoluteFrame()
            
            //pass data here!
            editDurationVC.centers = centers
            editDurationVC.cellIndexPath = indexPath
            
            let timer = frc.object(at: indexPath)
            let referenceClock = timer.referenceClock
            let time = Int(referenceClock).time()
            
            //send duration for cell components
            editDurationVC.initialSeconds = String(time.sec)
            editDurationVC.initialMinutes = String(time.min)
            editDurationVC.initialHours = String(time.hr)
            
            //send currentClock and timerID
            editDurationVC.referenceClock = referenceClock
            editDurationVC.timerID = timer.id?.uuidString
            
            //set color
            editDurationVC.okButtonColor = cell.secondsButton.color
            editDurationVC.hoursLabelColor = cell.hoursLabel.color
            editDurationVC.okButtonStringColor = timer.color
            
            editDurationIndexPath = indexPath
        }
    }
    
    struct TimeComponentsCenters {
        let seconds:CGPoint
        let minutes:CGPoint
        let hours:CGPoint
    }
    
    func prepareCellToExitEditMode() {
        let cell = tableView.cellForRow(at: editDurationIndexPath!) as! CTCell
        cell.durationHoursLabel.textColor = .white
        cell.durationMinutesLabel.textColor = .white
        cell.durationSecondsLabel.textColor = .white
        
        cell.coverTimeComponents(false)
        
        editDurationIndexPath = nil
    }
}

class HoursLabelCover: UIView {
    var color = UIColor.clear {didSet{ setNeedsDisplay() }}
    
    override func draw(_ rect: CGRect) {
        let circle = UIBezierPath(ovalIn: rect)
        color.setFill()
        circle.fill()
    }
}
