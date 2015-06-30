# LxGridView-swift
Imitate Apple iOS system Desktop icons arrangement and interaction by inheriting UICollectionView!

*	![demo](demo.gif)
---
###	Installation
	You only need drag directory LxGridView to your project.
###	Support	
	Minimum support iOS version: iOS 6.0
###	Usage

`You can use LxGridView as convenient as UICollectionView.`

	let _gridViewFlowLayout = LxGridViewFlowLayout()
	//	... config _gridViewFlowLayout
	
	_gridView = LxGridView(frame: GRIDVIEW_FRAME, collectionViewLayout: _gridViewFlowLayout)
	//	...	congif _gridView
	
	_gridView.registerClass(LxGridViewCell.classForCoder(), forCellWithReuseIdentifier: GRIDVIEW_CELL_REUSE_IDENTIFIER)

	//	implement delegate method
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        return dataArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(LxGridViewCellReuseIdentifier, forIndexPath: indexPath) as! LxGridViewCell
        
        cell.delegate = self
        cell.editing = _gridView.editing
        
        //	...	config cell
        
        return cell
    }

    func collectionView(collectionView: LxGridView, itemAtIndexPath sourceIndexPath: NSIndexPath, willMoveToIndexPath destinationIndexPath: NSIndexPath) {
        
        let dataDict = dataArray[sourceIndexPath.item]
        dataArray.removeAtIndex(sourceIndexPath.item)
        dataArray.insert(dataDict, atIndex: destinationIndexPath.item)
    }
    
    func deleteButtonClickedInGridViewCell(gridViewCell: LxGridViewCell) {

        if let gridViewCellIndexPath = _gridView!.indexPathForCell(gridViewCell) {
        
            dataArray.removeAtIndex(gridViewCellIndexPath.item)
            _gridView.performBatchUpdates({ [unowned self] () -> Void in
                self._gridView.deleteItemsAtIndexPaths([gridViewCellIndexPath])
            }, completion: nil)
        }
    }

---
###	License
LxGridView is available under the Apache License 2.0. See the LICENSE file for more info.