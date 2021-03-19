//
//  UIAutoSuggestField.swift
//  UIAutoSuggestField
//
//  Created by Bahadır ARSLAN on 14.03.2021.
//  Copyright © 2021 Bahadır ARSLAN. All rights reserved.
//
//  The origin of this library was Shyngys Kassymov's article and Objective-C code which is located at : https://github.com/chika-kasymov/UITextField_AutoSuggestion
//  I ported it to Swift and added some more functionality


import Foundation
import UIKit

let DEFAULT_MAX_NUM_OF_ROWS = 5
let DEFAULT_ROW_HEIGHT = 60.0
let INSET = 20.0

private var textFieldRectOnWindowKey = 0
private var keyboardFrameBeginRectKey = 0

@objc protocol UIAutoSuggestionFieldDataSource: NSObjectProtocol {
    func autoSuggestionField(_ field: UIAutoSuggestField?, tableView: UITableView?, cellForRowAtIndexPath indexPath: IndexPath?, forText text: String?) -> UITableViewCell? // 1
    
    func autoSuggestionField(_ field: UIAutoSuggestField?, tableView: UITableView?, numberOfRowsInSection section: Int, forText text: String?) -> Int // 2
    
    @objc optional func autoSuggestionField(_ field: UIAutoSuggestField?, textChanged text: String?) // 3
    
    @objc optional func autoSuggestionField(_ field: UIAutoSuggestField?, tableView: UITableView?, heightForRowAtIndexPath indexPath: IndexPath?, forText text: String?) -> CGFloat // 4
    
    @objc optional func autoSuggestionField(_ field: UIAutoSuggestField?, tableView: UITableView?, didSelectRowAtIndexPath indexPath: IndexPath?, forText text: String?) // 5
    
    @objc optional func newItemButtonTapped(_ field: UIAutoSuggestField)
}

open class UIAutoSuggestField : UITextField, UITableViewDataSource, UITableViewDelegate {
    @IBInspectable open var TableBackgroundColor: UIColor = UIColor.lightGray
    @IBInspectable open var AlphaViewColor: UIColor = UIColor.gray.withAlphaComponent(0.5)
    @IBInspectable open var TableAlphaBackgroundColor : UIColor = UIColor.darkGray.withAlphaComponent(0.8)
    @IBInspectable open var SpinnerColor : UIColor = UIColor.orange
    @IBInspectable var leftPadding: CGFloat = 0
    open var showNewItemText : Bool = false
    open var newItemText : String?
    var showImmediately:Bool = false
    var minCharsToShow:Int = 3
    var maxNumberOfRows:Int = 5
    var autoSuggestionDataSource:UIAutoSuggestionFieldDataSource?
    open var tintedClearImage: UIImage?
    
    var data : [SuggestItem]?
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupTintColor()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupTintColor()
    }
    
    private var tableView:UITableView?
    private var tableContainerView:UIView?
    private var tableAlphaView:UIView?
    private var spinner:UIActivityIndicatorView?
    private var alphaView:UIView?
    private var emptyView:UIView?
    private var textFieldRectOnWindow:CGRect?
    private var keyboardFrameBeginRect:CGRect?
    private var autoSuggestionIsShowing:Bool = false
    
    private var fieldIdentifier:String?
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        self.tintClearImage()
    }
    
    @objc func observeTextFieldChanges() {
        layer.masksToBounds = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.toggleAutoSuggestion(_:)), name: UITextField.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.toggleAutoSuggestion(_:)), name: UITextField.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideAutoSuggestion), name: UITextField.textDidEndEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.getKeyboardHeight(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func getKeyboardHeight(_ notification: Notification?) {
        let keyboardInfo = notification?.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue
        keyboardFrameBeginRect = keyboardFrameBegin?.cgRectValue
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // 2
    func createSuggestionView() {
        let appDelegateWindow: UIWindow? = UIApplication.shared.keyWindow
        textFieldRectOnWindow = convert(bounds, to: nil)

        if !(tableContainerView != nil)  {
            tableContainerView = UIView()
            tableContainerView!.backgroundColor = TableBackgroundColor
        }
        
        if tableView == nil {
            tableView = UITableView(frame: textFieldRectOnWindow!, style: .plain)
            tableView?.tableFooterView = UIView(frame: CGRect.zero)
            tableView?.delegate = self
            tableView?.dataSource = self
        }
        
        if !(alphaView != nil) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            alphaView = UIView(frame: appDelegateWindow?.bounds ?? CGRect.zero)
            alphaView?.isUserInteractionEnabled = true
            alphaView?.backgroundColor = AlphaViewColor
            alphaView?.addGestureRecognizer(tap)
            appDelegateWindow?.addSubview(alphaView!)
        }
        
        tableView?.frame = textFieldRectOnWindow!
        
        tableContainerView?.addSubview(tableView!)
        
        tableContainerView?.frame = textFieldRectOnWindow!
        
        DispatchQueue.main.async {
            appDelegateWindow?.addSubview(self.tableContainerView!)
        }
        
    }
    
    // 3
    func showAutoSuggestion() {
        if !autoSuggestionIsShowing {
            createSuggestionView()
            autoSuggestionIsShowing = true
        }
        if (spinner == nil || (spinner != nil && spinner!.isAnimating)){
            reloadContents()
        }
        
    }
    
    func createNewItemButton() -> UIButton {
        let newItemButton = UIButton(frame: (tableView?.bounds)!)
        newItemButton.frame.size.height = 50
        newItemButton.titleLabel?.textAlignment = .center
        newItemButton.titleLabel?.font = UIFont(name: "Helvetica-Medium", size: 16.0)
        newItemButton.setTitleColor(.black, for: .normal)
        newItemButton.setTitle(newItemText, for: .normal)
        newItemButton.addTarget(self, action: #selector(newItemButtonAction), for: .touchUpInside)
        return newItemButton
    }
    
    @objc func hideAutoSuggestion() {
        if autoSuggestionIsShowing {
            
            alphaView?.removeFromSuperview()
            alphaView = nil
            
            tableView?.removeFromSuperview()
            
            tableContainerView?.removeFromSuperview()
            
            autoSuggestionIsShowing = false
        }
    }
    
    
    // 6
    func reloadContents() {

        self.updateHeight()
        
        updateCornerRadius()
        
        DispatchQueue.main.async {
            self.checkForEmptyState()
        }
        
        DispatchQueue.main.async {
            self.tableView?.reloadData()
        }
        //
        DispatchQueue.main.async { [self] in
            if(self.showNewItemText && tableView(tableView!, numberOfRowsInSection: 0) > 0) {
                let footerView = UIView(frame: CGRect(x: 0, y: 0, width: (tableView?.frame.size.width)!, height: 50))
                
                let btn = createNewItemButton()
                footerView.addSubview(btn)
                
                tableView?.tableFooterView = btn
            }
            else {
                tableView?.tableFooterView = UIView(frame: CGRect.zero)
            }
        }
        
    }
    
    
    func updateHeight() {
        
        
        let numberOfResults: Int = tableView(self.tableView!, numberOfRowsInSection: 0)
        
        let maxRowsToShow: Int = maxNumberOfRows != 0 ? maxNumberOfRows : DEFAULT_MAX_NUM_OF_ROWS
        
        var cellHeight = DEFAULT_ROW_HEIGHT
        
        if (tableView?.numberOfRows(inSection: 0))! > 0 {
            cellHeight = Double(tableView(tableView!, heightForRowAt: IndexPath(row: 0, section: 0)))
        }
        
        var height: CGFloat = CGFloat(Double(min(maxRowsToShow, numberOfResults)) * cellHeight) // check if numberOfResults < maxRowsToShow
        height = max(height, CGFloat(cellHeight)) // if 0 results, set height = `cellHeight`
        if(showNewItemText) {
            
            height += 50
        }
        var frame: CGRect = textFieldRectOnWindow!
        
        if showSuggestionViewBelow() {
            let maxHeight: CGFloat = UIScreen.main.bounds.size.height - (frame.origin.y + frame.size.height) - CGFloat(INSET) - keyboardFrameBeginRect!.size.height // max possible height
            height = min(height, maxHeight) // set height = `maxHeight` if it's smaller than current `height`
            
            frame.origin.y += frame.size.height
        } else {
            let maxHeight: CGFloat = frame.origin.y - CGFloat(INSET) // max possible height
            height = min(height, maxHeight) // set height = `maxHeight` if it's smaller than current `height`
            
            frame.origin.y -= height
        }
        
        frame.size.height = height
        tableView?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        tableContainerView?.frame = frame
    }
    
    
    func updateCornerRadius() {
        // code snippet from SO answer (http://stackoverflow.com/a/13163693/1760199)
        var corners: UIRectCorner = [.bottomLeft, .bottomRight]
        if !showSuggestionViewBelow() {
            corners = [.topLeft, .topRight]
        }
        
        let maskPath = UIBezierPath(roundedRect: (tableContainerView?.bounds)!, byRoundingCorners: corners, cornerRadii: CGSize(width: 6, height: 6))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        
        tableContainerView?.layer.mask = maskLayer
        
    }
    
    // 9
    func checkForEmptyState() {
        if tableView(tableView!, numberOfRowsInSection: 0) == 0 {
            
            if (emptyView == nil) {
                let bgView = UIStackView(frame: tableView!.bounds)
                bgView.axis = .vertical
                bgView.distribution = .fillEqually
                let emptyTableLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (tableView?.bounds.width)!, height: 50))
                emptyTableLabel.textAlignment = .center
                emptyTableLabel.font = UIFont(name: "Helvetica-Medium", size: 16.0)
                emptyTableLabel.textColor = UIColor.systemGray
                emptyTableLabel.text = "No matches"
                bgView.addArrangedSubview(emptyTableLabel)
                if(showNewItemText) {
                    let btn = createNewItemButton()
                    bgView.addArrangedSubview(btn)
                }
                tableView?.backgroundView = bgView
            } else {
                tableView?.backgroundView = emptyView
            }
            
        } else {
            tableView?.backgroundView = nil
        }
        
    }
    
    @objc func newItemButtonAction(sender: UIButton!) {
        if  autoSuggestionDataSource!.responds(to: #selector(autoSuggestionDataSource!.newItemButtonTapped)) {
            hideAutoSuggestion()
            autoSuggestionDataSource?.newItemButtonTapped?(self)
        }
    }
    
    // 10
    func showSuggestionViewBelow() -> Bool {
        let frame: CGRect = textFieldRectOnWindow!
        return frame.origin.y + frame.size.height / 2.0 < (UIScreen.main.bounds.size.height - keyboardFrameBeginRect!.size.height) / 2.0
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // 2
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoSuggestionDataSource!.autoSuggestionField(self, tableView: tableView, numberOfRowsInSection: section, forText: text)
    }
    
    // 3
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let implementsDatasource: Bool =  autoSuggestionDataSource!.responds(to:
                                                                                #selector(autoSuggestionDataSource!.autoSuggestionField(_:tableView:cellForRowAtIndexPath:forText:)))
        
        assert(implementsDatasource, "UITextField must implement data source before using auto suggestion.")
        
        return autoSuggestionDataSource!.autoSuggestionField(self, tableView: tableView, cellForRowAtIndexPath: indexPath, forText: text)!
    }
    
    // 4
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if  autoSuggestionDataSource!.responds(to:
                                                #selector(autoSuggestionDataSource!.autoSuggestionField(_:tableView:heightForRowAtIndexPath:forText:)))
        {
            return autoSuggestionDataSource!.autoSuggestionField!(self, tableView: tableView, heightForRowAtIndexPath: indexPath, forText: text)
        }
        
        return CGFloat(DEFAULT_ROW_HEIGHT)
    }
    
    // 5
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hideAutoSuggestion()
        tableView.deselectRow(at: indexPath, animated: true)
        if  autoSuggestionDataSource!.responds(to: #selector(autoSuggestionDataSource!.autoSuggestionField(_:tableView:didSelectRowAtIndexPath:forText:))) {
            autoSuggestionDataSource!.autoSuggestionField!(self, tableView: tableView, didSelectRowAtIndexPath: indexPath, forText: text)
        }
        
        
    }
    
    // 6
    @objc func toggleAutoSuggestion(_ notification: Notification?) {
        if showImmediately || ((text?.count)! > 0 && (text?.count)! >= minCharsToShow) {
            
            showAutoSuggestion()
            
            if autoSuggestionDataSource!.responds(to: #selector(autoSuggestionDataSource!.autoSuggestionField(_:textChanged:))) {
                autoSuggestionDataSource!.autoSuggestionField!(self, textChanged: text)
            }
            
        } else {
            hideAutoSuggestion()
        }
    }
    func setLoading(_ loading: Bool) {
        if loading {
            if !(tableAlphaView != nil) {
                tableAlphaView = UIView(frame: (tableView?.bounds)!)
                tableAlphaView?.backgroundColor = TableAlphaBackgroundColor
                tableView?.addSubview(tableAlphaView!)
                
                spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                spinner?.center = (tableAlphaView?.center)!
                spinner?.color = self.SpinnerColor
                tableAlphaView?.addSubview(spinner!)
                
                spinner?.startAnimating()
            }
        } else {
            if (tableAlphaView != nil) {
                spinner?.startAnimating()
                
                spinner?.removeFromSuperview()
                spinner = nil
                
                tableAlphaView?.removeFromSuperview()
                tableAlphaView = nil
            }
        }
    }
    
    // Provides left padding for images
    open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftPadding
        return textRect
    }
    
    override public func canPerformAction(_ action: Selector, withSender
                                            sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        hideAutoSuggestion()
    }
    
}
extension UIAutoSuggestField {
    
    func setupTintColor() {
        self.borderStyle = UITextField.BorderStyle.roundedRect
        self.layer.cornerRadius = 8.0
        self.layer.masksToBounds = true
        self.layer.borderColor = self.tintColor.cgColor
        self.layer.borderWidth = 1.5
        self.backgroundColor = .clear
        
    }
    private func tintClearImage() {
        for view in subviews {
            if view is UIButton {
                let button = view as! UIButton
                if let image = button.image(for: .highlighted) {
                    if self.tintedClearImage == nil {
                        tintedClearImage = self.tintImage(image: image, color: self.tintColor)
                    }
                    button.setImage(self.tintedClearImage, for: .normal)
                    button.setImage(self.tintedClearImage, for: .highlighted)
                }
            }
        }
    }
    
    private func tintImage(image: UIImage, color: UIColor) -> UIImage {
        let size = image.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: .zero, blendMode: CGBlendMode.normal, alpha:1.0)
        
        context?.setFillColor(color.cgColor)
        context?.setBlendMode(CGBlendMode.sourceIn)
        context?.setAlpha(1.0)
        
        let rect = CGRect(x: CGPoint.zero.x, y: CGPoint.zero.y, width: image.size.width, height: image.size.height)
        UIGraphicsGetCurrentContext()?.fill(rect)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImage ?? UIImage()
    }
    
}
