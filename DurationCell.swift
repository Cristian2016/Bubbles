//
//  DurationCell.swift
//  Time Dots
//
//  Created by Cristian Lapusan on 10.01.2022.
//

import UIKit

class DurationCell: UITableViewCell {
    
    /*
     func prepareForReuse()
     
     If a cell has reuse identifier, table calls prepareForReuse just before returning the cell from dequeueReusableCell(withIdentifier:). only reset attributes of the cell that are not related to content, for example, alpha, editing, and selection state.
     ⚠️ tableView(_:cellForRowAt:) should always reset all content when reusing a cell.
     The table view doesn’t call this method if the cell object doesn’t have an associated reuse identifier, or if you use reconfigureRows(at:) to update the contents of an existing cell.
     If you override this method, you must be sure to invoke the superclass implementation.
   */
    
    // MARK: - Outlets
    @IBOutlet weak var hrLabel: Label!
    @IBOutlet weak var minLabel: Label!
    @IBOutlet weak var secLabel: Label!
    
    // MARK: - methods
    func configureLabels(duration:Float) {
        //reset first all content
        hrLabel.text = nil
        minLabel.text = nil
        secLabel.text = nil
        
        //populate content
        let components = Int(duration).time()
        
        hrLabel.text = String(components.hr)
        minLabel.text = String(components.min)
        secLabel.text = String(components.sec)
    }
}
