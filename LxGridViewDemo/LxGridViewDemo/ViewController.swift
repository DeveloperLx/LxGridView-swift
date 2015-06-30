//
//  ViewController.swift
//  LxGridViewDemo
//

import UIKit

let LxGridViewCellReuseIdentifier = "LxGridViewCellReuseIdentifier"
let HOME_BUTTON_RADIUS: CGFloat = 21
let HOME_BUTTON_BOTTOM_MARGIN: CGFloat = 9

class ViewController: UIViewController, LxGridViewDataSource, LxGridViewDelegateFlowLayout, LxGridViewCellDelegate {

    var dataArray = [[String:AnyObject?]]()

    var _gridView: LxGridView?
    let _gridViewFlowLayout = LxGridViewFlowLayout()
    let _homeButton = UIButton.buttonWithType(.Custom) as! UIButton
    
    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None
        
        for i in 0..<15 {
        
            var dataDict = [String:AnyObject?]()
            dataDict["index"] = "App \(i)"
            dataDict["icon_image"] = UIImage(named: "\(i)")
            dataArray.append(dataDict)
        }
     
        _gridViewFlowLayout.sectionInset = UIEdgeInsets(top: 18, left: 30, bottom: 18, right: 30)
        _gridViewFlowLayout.minimumLineSpacing = 9
        _gridViewFlowLayout.itemSize = CGSize(width: 66, height: 88)
        
        _gridView = LxGridView(frame: CGRectZero, collectionViewLayout: _gridViewFlowLayout)
        _gridView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        _gridView?.delegate = self
        _gridView?.dataSource = self
        _gridView?.scrollEnabled = false
        _gridView?.backgroundColor = UIColor.whiteColor()
        view.addSubview(_gridView!)
        
        _gridView?.registerClass(LxGridViewCell.classForCoder(), forCellWithReuseIdentifier: LxGridViewCellReuseIdentifier)
        
        _homeButton.showsTouchWhenHighlighted = true
        _homeButton.layer.cornerRadius = HOME_BUTTON_RADIUS
        _homeButton.layer.masksToBounds = true
        _homeButton.layer.borderWidth = 1
        _homeButton.layer.borderColor = UIColor.blackColor().CGColor
        _homeButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        _homeButton.setTitle("☐", forState: .Normal)
        _homeButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        _homeButton.addTarget(self, action: Selector("homeButtonClicked:"), forControlEvents: .TouchUpInside)
        view.addSubview(_homeButton)
        
        _gridView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let gridViewTopMargin = NSLayoutConstraint(item: _gridView!, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0)
        let gridViewRightMargin = NSLayoutConstraint(item: _gridView!, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1, constant: 0)
        let gridViewBottomMargin = NSLayoutConstraint(item: _gridView!, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        let gridViewLeftMargin = NSLayoutConstraint(item: _gridView!, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 0)
        view.addConstraints([gridViewTopMargin, gridViewRightMargin, gridViewBottomMargin, gridViewLeftMargin])
        
        _homeButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let centerXConstraint = NSLayoutConstraint(item: _homeButton, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
        let homeButtonBottomMargin = NSLayoutConstraint(item: _homeButton, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: -HOME_BUTTON_BOTTOM_MARGIN)
        let homeButtonWidthMargin = NSLayoutConstraint(item: _homeButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: HOME_BUTTON_RADIUS * 2)
        let homeButtonHeightMargin = NSLayoutConstraint(item: _homeButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: HOME_BUTTON_RADIUS * 2)
        view.addConstraints([centerXConstraint, homeButtonBottomMargin, homeButtonWidthMargin, homeButtonHeightMargin])
    }
    
    func homeButtonClicked(btn: UIButton) {
    
        _gridView?.editing = false
    }
    
// MARK:- delegate
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        return dataArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(LxGridViewCellReuseIdentifier, forIndexPath: indexPath) as! LxGridViewCell
        
        cell.delegate = self
        cell.editing = _gridView!.editing
        
        let dataDict = dataArray[indexPath.item] as [String:AnyObject?]
        cell.title = dataDict["index"] as? String
        cell.iconImageView?.image = dataDict["icon_image"] as? UIImage
        
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
            _gridView?.performBatchUpdates({ [unowned self] () -> Void in
                self._gridView?.deleteItemsAtIndexPaths([gridViewCellIndexPath])
            }, completion: nil)
        }
    }
}

