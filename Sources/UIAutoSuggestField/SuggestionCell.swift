//
//  File.swift
//  
//
//  Created by Bahadır ARSLAN on 19.03.2021.
//

import Foundation
import UIKit

class SuggestionCell : UITableViewCell {
    var ID : Int = 0
    
    var searchItem : SuggestItem? {
        didSet {
            Subtitle.text = searchItem?.subtitle
            Name.text = searchItem?.title
            ID = (searchItem?.id)!
        }
    }
    
    
    private let Subtitle : UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.black
        lbl.font = UIFont(name: "HelveticaNeue-Thin", size: 14)
        lbl.textAlignment = .left
        return lbl
    }()
    
    private let Name : UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.black
        lbl.font = UIFont(name: "HelveticaNeue-Thin", size: 20)
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        lbl.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return lbl
    }()

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.lightGray
         let width : CGFloat = frame.size.width - 50
        
        addSubview(Subtitle)
        addSubview(Name)
       
        Name.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 10, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: width, height: 0, enableInsets: false)
       
        Subtitle.anchor(top: Name.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 5, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: Subtitle.frame.width, height: 0, enableInsets: false)
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
