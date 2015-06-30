//
//  LxGridViewFlowLayout.swift
//  LxGridViewDemo
//

import UIKit

let PRESS_TO_MOVE_MIN_DURATION = 0.1
let MIN_PRESS_TO_BEGIN_EDITING_DURATION = 0.6

@objc

protocol LxGridViewDataSource : UICollectionViewDataSource {

    optional func collectionView(collectionView: LxGridView, itemAtIndexPath sourceIndexPath: NSIndexPath, willMoveToIndexPath destinationIndexPath: NSIndexPath)
    optional func collectionView(collectionView: LxGridView, itemAtIndexPath sourceIndexPath: NSIndexPath, didMoveToIndexPath destinationIndexPath: NSIndexPath)
    
    optional func collectionView(collectionView: LxGridView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
    optional func collectionView(collectionView: LxGridView, itemAtIndexPath sourceIndexPath: NSIndexPath, canMoveToIndexPath destinationIndexPath: NSIndexPath) -> Bool
}

@objc

protocol LxGridViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {

    optional func collectionView(collectionView: LxGridView, layout gridViewLayout: LxGridViewFlowLayout, willBeginDraggingItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: LxGridView, layout gridViewLayout: LxGridViewFlowLayout, didBeginDraggingItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: LxGridView, layout gridViewLayout: LxGridViewFlowLayout, willEndDraggingItemAtIndexPath indexPath: NSIndexPath)
    optional func collectionView(collectionView: LxGridView, layout gridViewLayout: LxGridViewFlowLayout, didEndDraggingItemAtIndexPath indexPath: NSIndexPath)
}

class LxGridViewFlowLayout: UICollectionViewFlowLayout, UIGestureRecognizerDelegate {
    
    var panGestureRecognizerEnable: Bool {
        
        get {
            return _panGestureRecognizer.enabled
        }
        set {
            _panGestureRecognizer.enabled = newValue
        }
    }
   
    var _panGestureRecognizer = UIPanGestureRecognizer()
    
    var _longPressGestureRecognizer = UILongPressGestureRecognizer()
    var _movingItemIndexPath: NSIndexPath?
    var _beingMovedPromptView: UIView?
    var _sourceItemCollectionViewCellCenter = CGPointZero
    
    var _displayLink: CADisplayLink?
    var _remainSecondsToBeginEditing = MIN_PRESS_TO_BEGIN_EDITING_DURATION
    
    
//  MARK:- setup
    deinit {
    
        _displayLink?.invalidate()
        
        removeGestureRecognizers()
        removeObserver(self, forKeyPath: "collectionView")
    }
    
    override init () {
        
        super.init()
        setup()
    }

    required init(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
    
        self.addObserver(self, forKeyPath: "collectionView", options: .New, context: nil)
    }
    
    func addGestureRecognizers() {
    
        collectionView?.userInteractionEnabled = true
        
        _longPressGestureRecognizer.addTarget(self, action: Selector("longPressGestureRecognizerTriggerd:"))
        _longPressGestureRecognizer.cancelsTouchesInView = false
        _longPressGestureRecognizer.minimumPressDuration = PRESS_TO_MOVE_MIN_DURATION
        _longPressGestureRecognizer.delegate = self
        
        if let cV = collectionView {
        
            for gestureRecognizer in cV.gestureRecognizers! {
                
                if gestureRecognizer is UILongPressGestureRecognizer {
                    
                    gestureRecognizer.requireGestureRecognizerToFail(_longPressGestureRecognizer)
                }
            }
        }
        
        collectionView?.addGestureRecognizer(_longPressGestureRecognizer)
        
        _panGestureRecognizer.addTarget(self, action: Selector("panGestureRecognizerTriggerd:"))
        _panGestureRecognizer.delegate = self
        collectionView?.addGestureRecognizer(_panGestureRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationWillResignActive:"), name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    func removeGestureRecognizers() {
    
        _longPressGestureRecognizer.view?.removeGestureRecognizer(_longPressGestureRecognizer)
        _longPressGestureRecognizer.delegate = nil
        
        _panGestureRecognizer.view?.removeGestureRecognizer(_panGestureRecognizer)
        _panGestureRecognizer.delegate = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self, forKeyPath: UIApplicationWillResignActiveNotification)
    }
    
//  MARK:- getter and setter implementation
    var dataSource: LxGridViewDataSource? {
        
        return collectionView?.dataSource as? LxGridViewDataSource
    }
    
    var delegate: LxGridViewDelegateFlowLayout? {
    
        return collectionView?.delegate as? LxGridViewDelegateFlowLayout
    }
    
    var editing: Bool {
    
        set {
            assert(collectionView is LxGridView || collectionView == nil, "LxGridViewFlowLayout: Must use LxGridView as your collectionView class!")
            
            if let gridView = collectionView as? LxGridView {
            
                gridView.editing = newValue
            }
        }
        get {
            assert(collectionView is LxGridView || collectionView == nil, "LxGridViewFlowLayout: Must use LxGridView as your collectionView class!")
            
            if let gridView = collectionView as? LxGridView {
                
                return gridView.editing
            }
            else {
                return false
            }
        }
    }
    
//  MARK:- override UICollectionViewLayout methods
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        
        let layoutAttributesForElementsInRect = super.layoutAttributesForElementsInRect(rect)
        
        if let lxfeir = layoutAttributesForElementsInRect {
        
            for layoutAttributes in lxfeir {
                
                if let las = layoutAttributes as? UICollectionViewLayoutAttributes {
                    
                    if las.representedElementCategory == .Cell {
                        
                        las.hidden = las.indexPath == _movingItemIndexPath
                    }
                }
            }
        }
        
        return layoutAttributesForElementsInRect
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        let layoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        
        if layoutAttributes.representedElementCategory == .Cell {
            
            layoutAttributes.hidden = layoutAttributes.indexPath == _movingItemIndexPath
        }
        
        return layoutAttributes
    }

//  MARK:- gesture
    func longPressGestureRecognizerTriggerd(longPress:UILongPressGestureRecognizer) {
    
        switch longPress.state {
        
        case .Began:
            if _displayLink == nil {
                _displayLink = CADisplayLink(target: self, selector: Selector("displayLinkTriggered:"))
                _displayLink?.frameInterval = 6
                _displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            
                _remainSecondsToBeginEditing = MIN_PRESS_TO_BEGIN_EDITING_DURATION
            }
            
            if editing == false {
            
                return
            }
            
            _movingItemIndexPath = collectionView?.indexPathForItemAtPoint(longPress.locationInView(collectionView))
            
            if dataSource?.collectionView?(collectionView as! LxGridView, canMoveItemAtIndexPath: _movingItemIndexPath!) == false {
            
                _movingItemIndexPath = nil
                return
            }
            
            delegate?.collectionView?(collectionView as! LxGridView, layout: self, willBeginDraggingItemAtIndexPath: _movingItemIndexPath!)
            
            if _movingItemIndexPath == nil {
            
                return
            }
            
            let sourceCollectionViewCell = collectionView?.cellForItemAtIndexPath(_movingItemIndexPath!)
            
            assert(sourceCollectionViewCell is LxGridViewCell || sourceCollectionViewCell == nil, "LxGridViewFlowLayout: Must use LxGridViewCell as your collectionViewCell class!")
                
            let sourceGridViewCell = sourceCollectionViewCell as! LxGridViewCell
            
            _beingMovedPromptView = UIView(frame: CGRectOffset(sourceCollectionViewCell!.frame, -LxGridView_DELETE_RADIUS, -LxGridView_DELETE_RADIUS))
            
            sourceGridViewCell.highlighted = true
            let highlightedSnapshotView = sourceGridViewCell.snapshotView()
            highlightedSnapshotView.frame = sourceGridViewCell.bounds
            highlightedSnapshotView.alpha = 1
            
            sourceGridViewCell.highlighted = false
            let snapshotView = sourceGridViewCell.snapshotView()
            snapshotView.frame = sourceGridViewCell.bounds
            snapshotView.alpha = 0
            
            _beingMovedPromptView?.addSubview(snapshotView)
            _beingMovedPromptView?.addSubview(highlightedSnapshotView)
            collectionView?.addSubview(_beingMovedPromptView!)
            
            _sourceItemCollectionViewCellCenter = sourceGridViewCell.center
            
            UIView.animateWithDuration(0, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
                
                highlightedSnapshotView.alpha = 0
                snapshotView.alpha = 1
                
            }, completion: { [unowned self] (finished) -> Void in
                
                highlightedSnapshotView.removeFromSuperview()
                
                self.delegate?.collectionView?(self.collectionView as! LxGridView, layout: self, didBeginDraggingItemAtIndexPath: self._movingItemIndexPath!)
            })
            
            invalidateLayout()
            
        case .Ended:
            fallthrough
        case .Cancelled:
            _displayLink?.invalidate()
            _displayLink = nil
            
            if let movingItemIndexPath = _movingItemIndexPath {
            
                delegate?.collectionView?(collectionView as! LxGridView, layout: self, willEndDraggingItemAtIndexPath: movingItemIndexPath)
                
                _movingItemIndexPath = nil
                _sourceItemCollectionViewCellCenter = CGPointZero
                
                let movingItemCollectionViewLayoutAttributes = layoutAttributesForItemAtIndexPath(movingItemIndexPath)
                
                _longPressGestureRecognizer.enabled = false
                
                UIView.animateWithDuration(0, delay: 0, options: .BeginFromCurrentState, animations: { [unowned self] () -> Void in
                    
                    self._beingMovedPromptView!.center = movingItemCollectionViewLayoutAttributes.center
                }, completion: { [unowned self] (finished) -> Void in
                    
                    self._longPressGestureRecognizer.enabled = true
                    self._beingMovedPromptView?.removeFromSuperview()
                    self._beingMovedPromptView = nil
                    self.invalidateLayout()
                    self.delegate?.collectionView?(self.collectionView as! LxGridView, layout: self, didEndDraggingItemAtIndexPath: movingItemIndexPath)
                })
            }
        default:
            break
        }
    }
    
    func panGestureRecognizerTriggerd(pan: UIPanGestureRecognizer) {
    
        switch pan.state {
        
        case .Began:
            fallthrough
        case .Changed:
            let panTranslation = pan.translationInView(collectionView!)
            _beingMovedPromptView?.center = _sourceItemCollectionViewCellCenter + panTranslation
            
            let sourceIndexPath = _movingItemIndexPath
            
            let destinationIndexPath = collectionView?.indexPathForItemAtPoint((_beingMovedPromptView?.center)!)
            
            if destinationIndexPath == nil || destinationIndexPath == sourceIndexPath {
                return
            }
            
            if dataSource?.collectionView?(collectionView as! LxGridView, itemAtIndexPath: sourceIndexPath!, canMoveToIndexPath: destinationIndexPath!) == false {
                return
            }
            
            dataSource?.collectionView?(collectionView as! LxGridView, itemAtIndexPath: sourceIndexPath!, willMoveToIndexPath: destinationIndexPath!)
            
            _movingItemIndexPath = destinationIndexPath
            collectionView?.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView?.deleteItemsAtIndexPaths([sourceIndexPath!])
                self.collectionView?.insertItemsAtIndexPaths([destinationIndexPath!])
            }, completion: { [unowned self] (finished) -> Void in
                
                self.dataSource?.collectionView?(collectionView as! LxGridView, itemAtIndexPath: sourceIndexPath!, didMoveToIndexPath: destinationIndexPath!)
            })
            
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if _panGestureRecognizer == gestureRecognizer && editing {
            
            return _movingItemIndexPath != nil
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if _longPressGestureRecognizer == gestureRecognizer {
            return _panGestureRecognizer == otherGestureRecognizer
        }
        if _panGestureRecognizer == gestureRecognizer {
            return _longPressGestureRecognizer == otherGestureRecognizer
        }
        return false
    }
    
//  MARK:- displayLink
    
    func displayLinkTriggered(displayLink: CADisplayLink) {
    
        if _remainSecondsToBeginEditing <= 0 {
        
            editing = true
            _displayLink?.invalidate()
            _displayLink = nil
        }
        
        _remainSecondsToBeginEditing = _remainSecondsToBeginEditing - 0.1
    }
    
//  MARK:- KVO and notification
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
    
        if keyPath == "collectionView" {
        
            if collectionView != nil {
            
                addGestureRecognizers()
            }
            else {
            
                removeGestureRecognizers()
            }
        }
    }
    
    func applicationWillResignActive(notificaiton: NSNotification) {
    
        _panGestureRecognizer.enabled = false
        _panGestureRecognizer.enabled = true
    }
}

private func == (left: NSIndexPath, right: NSIndexPath) -> Bool {

    return left.section == right.section && left.item == right.item
}

func + (point: CGPoint, offset: CGPoint) -> CGPoint {
    
    return CGPoint(x: point.x + offset.x, y: point.y + offset.y)
}
