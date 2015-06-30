//
//  LxGridView.swift
//  LxGridViewDemo
//

import UIKit

class LxGridView: UICollectionView {
   
    private var _editing = false
    
    var editing: Bool {
    
        get {
            return _editing
        }
        set {
            _editing = newValue
            for cell in visibleCells() {
                
                if cell is LxGridViewCell {
                
                    let gridViewCell = cell as! LxGridViewCell
                    gridViewCell.editing = newValue
                }
                else {
                    assert(false, "LxGridView: Must use LxGridViewCell as your collectionViewCell class!")
                }
            }
        }
    }
}
