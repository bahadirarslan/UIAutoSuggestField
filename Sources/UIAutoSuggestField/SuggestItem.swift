//
//  File 2.swift
//  
//
//  Created by Bahadır ARSLAN on 19.03.2021.
//

import Foundation
import UIKit

open class SuggestItem {
   
    // Private vars
    fileprivate var attributedTitle: NSMutableAttributedString?
    fileprivate var attributedSubtitle: NSMutableAttributedString?
    
    // Public interface
    public var title: String
    public var subtitle: String?
    public var image: UIImage?
    public var id: Int?
    
    public init(title: String, subtitle: String?, image: UIImage?) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
    
    public init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }
    
    public init(title: String) {
        self.title = title
    }
    
    public init(title: String, subtitle: String?, id: Int?) {
        self.title = title
        self.subtitle = subtitle
        self.id = id
    }
    
}
