//
//  LxGridViewCell.swift
//  LxGridViewDemo
//

import UIKit

let LxGridView_DELETE_RADIUS: CGFloat = 15
let ICON_CORNER_RADIUS: CGFloat = 15

let kVibrateAnimation = "kVibrateAnimation"
let VIBRATE_DURATION: CGFloat = 0.1
let VIBRATE_RADIAN = CGFloat(M_PI/96)

protocol LxGridViewCellDelegate {

    func deleteButtonClickedInGridViewCell(gridViewCell: LxGridViewCell)
}

class LxGridViewCell: UICollectionViewCell {
    
    var delegate: LxGridViewCellDelegate?
    var iconImageView: UIImageView?
    
    private var _deleteButton: UIButton?
    private var _titleLabel: UILabel?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        setup()
        setupEvents()
    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        setup()
        setupEvents()
    }
    
    func setup() {
        iconImageView = UIImageView()
        iconImageView?.contentMode = .ScaleAspectFit
        iconImageView?.layer.cornerRadius = ICON_CORNER_RADIUS
        iconImageView?.layer.masksToBounds = true
        contentView.addSubview(iconImageView!)

        _deleteButton = UIButton.buttonWithType(.Custom) as? UIButton
        _deleteButton?.setImage(UIImage(named: "delete_collect_btn"), forState: .Normal)
        contentView.addSubview(_deleteButton!)
        _deleteButton?.hidden = true
        
        _titleLabel = UILabel()
        _titleLabel?.text = "title"
        _titleLabel?.font = UIFont.systemFontOfSize(14)
        _titleLabel?.textColor = UIColor.blackColor()
        _titleLabel?.textAlignment = .Center
        contentView.addSubview(_titleLabel!)
        
        iconImageView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        _deleteButton?.setTranslatesAutoresizingMaskIntoConstraints(false)
        _titleLabel?.setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let iconImageViewLeftConstraint = NSLayoutConstraint(item: iconImageView!, attribute: .Left, relatedBy: .Equal, toItem: contentView, attribute: .Left, multiplier: 1, constant: 0)
        let iconImageViewRightConstraint = NSLayoutConstraint(item: iconImageView!, attribute: .Right, relatedBy: .Equal, toItem: contentView, attribute: .Right, multiplier: 1, constant: 0)
        let iconImageViewTopConstraint = NSLayoutConstraint(item: iconImageView!, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 0)
        let iconImageViewHeightConstraint = NSLayoutConstraint(item: iconImageView!, attribute: .Width, relatedBy: .Equal, toItem: iconImageView, attribute: .Height, multiplier: 1, constant: 0)
        contentView.addConstraints([iconImageViewLeftConstraint, iconImageViewRightConstraint, iconImageViewTopConstraint, iconImageViewHeightConstraint])
        
        let deleteButtonTopConstraint = NSLayoutConstraint(item: _deleteButton!, attribute: .Top, relatedBy: .Equal, toItem: iconImageView, attribute: .Top, multiplier: 1, constant: -_deleteButton!.currentImage!.size.height/2)
        let deleteButtonLeftConstraint = NSLayoutConstraint(item: _deleteButton!, attribute: .Left, relatedBy: .Equal, toItem: iconImageView, attribute: .Left, multiplier: 1, constant: -_deleteButton!.currentImage!.size.width/2)
        let deleteButtonWidthConstraint = NSLayoutConstraint(item: _deleteButton!, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: _deleteButton!.currentImage!.size.width)
        let deleteButtonHeightConstraint = NSLayoutConstraint(item: _deleteButton!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: _deleteButton!.currentImage!.size.height)
        contentView.addConstraints([deleteButtonTopConstraint, deleteButtonLeftConstraint, deleteButtonWidthConstraint, deleteButtonHeightConstraint])
        
        let centerXConstraint = NSLayoutConstraint(item: _titleLabel!, attribute: .CenterX, relatedBy: .Equal, toItem: iconImageView, attribute: .CenterX, multiplier: 1, constant: 0)
        let titleLabelTopConstraint = NSLayoutConstraint(item: _titleLabel!, attribute: .Top, relatedBy: .Equal, toItem: iconImageView, attribute: .Bottom, multiplier: 1, constant: 5)
        let titleLabelWidthConstraint = NSLayoutConstraint(item: _titleLabel!, attribute: .Width, relatedBy: .Equal, toItem: iconImageView, attribute: .Width, multiplier: 1, constant: 0)
        let titleLabelHeightConstraint = NSLayoutConstraint(item: _titleLabel!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 15)
        contentView.addConstraints([centerXConstraint, titleLabelTopConstraint, titleLabelWidthConstraint, titleLabelHeightConstraint])
    }
    
    func setupEvents() {
    
        _deleteButton?.addTarget(self, action: Selector("deleteButtonClicked:"), forControlEvents: .TouchUpInside)
        iconImageView?.userInteractionEnabled = true
    }
    
    func deleteButtonClicked(btn: UIButton) {
    
        self.delegate?.deleteButtonClickedInGridViewCell(self)
    }
    
    private var vibrating: Bool {
    
        get {
            if let animationKeys = iconImageView?.layer.animationKeys() {
            
                return contains(animationKeys as! [String], kVibrateAnimation)
            }
            else {
                return false
            }
        }
        set {
            
            var _vibrating = false
        
            if let animationKeys = layer.animationKeys() {
                
                _vibrating = contains(animationKeys as! [String], kVibrateAnimation)
            }
            else {
                _vibrating = false
            }
            
            if _vibrating && !newValue {
            
                layer.removeAnimationForKey(kVibrateAnimation)
            }
            else if !_vibrating && newValue {
            
                let vibrateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
                vibrateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                vibrateAnimation.fromValue = -VIBRATE_RADIAN
                vibrateAnimation.toValue = VIBRATE_RADIAN
                vibrateAnimation.autoreverses = true
                vibrateAnimation.duration = CFTimeInterval(VIBRATE_DURATION)
                vibrateAnimation.repeatCount = Float(CGFloat.max)
                layer.addAnimation(vibrateAnimation, forKey: kVibrateAnimation)
            }
        }
    }
    
    var editing: Bool {
        
        get {
            return vibrating
        }
        set {
            vibrating = newValue
            _deleteButton?.hidden = !newValue
        }
    }
    
    var title: String? {
    
        get {
            return _titleLabel?.text
        }
        set {
            _titleLabel?.text = newValue
        }
    }
    
    func snapshotView() -> UIView {
        
        let snapshotView = UIView()
        
        let cellSnapshotView = snapshotViewAfterScreenUpdates(false)
        let deleteButtonSnapshotView = _deleteButton?.snapshotViewAfterScreenUpdates(false)
        
        snapshotView.frame = CGRect(x: -deleteButtonSnapshotView!.frame.size.width / 2,
            y: -deleteButtonSnapshotView!.frame.size.height / 2,
            width: deleteButtonSnapshotView!.frame.size.width / 2 + cellSnapshotView.frame.size.width,
            height: deleteButtonSnapshotView!.frame.size.height / 2 + cellSnapshotView.frame.size.height)
        cellSnapshotView.frame = CGRect(x: deleteButtonSnapshotView!.frame.size.width / 2,
            y: deleteButtonSnapshotView!.frame.size.height / 2,
            width: cellSnapshotView.frame.size.width,
            height: cellSnapshotView.frame.size.height)
        deleteButtonSnapshotView?.frame = CGRect(x: 0, y: 0,
            width: deleteButtonSnapshotView!.frame.size.width,
            height: deleteButtonSnapshotView!.frame.size.height)
        
        snapshotView.addSubview(cellSnapshotView)
        snapshotView.addSubview(deleteButtonSnapshotView!)
        
        return snapshotView
    }
}
