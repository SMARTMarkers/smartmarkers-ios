//
//  FHIRViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/4/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

open class FHIRViewController: UIViewController {
    
    public final var resource: Resource!
    
    var textView: UITextView!
    
    
    convenience init(_ resource: Resource) {
        
        self.init()
        self.resource = resource
        self.title = "FHIR \(resource.sm_resourceType())"

        
    }
    
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let frame = view.frame
        textView = UITextView(frame: frame)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        let views = ["textView": textView as Any]
        view.sm_addVisualConstraint("H:|-[textView]-|", views)
        view.sm_addVisualConstraint("V:|-[textView]-|", views)
        if let json = try? resource?.sm_jsonString() {
            textView.text = json
        }
        textView.scrollsToTop = true
    }
    
}



