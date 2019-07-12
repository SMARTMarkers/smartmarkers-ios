//
//  ACModel.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 7/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

public typealias JSONDict = [String: Any]

public protocol ACBase {
    var identifier: String? { get set }
    var loinc: String? { get set }
    var order: UInt? { get set }
    func populate(from json: JSONDict)
    static func create(from json: JSONDict) -> Self
}
public class ACBaseItem: ACBase {
    
    required public init() {
        
    }
    public var identifier: String?
    public var loinc: String?
    public var order: UInt?
    
    public  func populate(from json: JSONDict)  {
        identifier  = json["OID"] as? String
        loinc       = json["LOINC_NUM"] as? String
        order       = json["Position"]  as? UInt
    }
    
}
public extension ACBaseItem  {
    static func create(from json: JSONDict) -> Self {
        let t = self.init()
        t.populate(from: json)
        return t
    }
}
public class ACResponseItem2: ACBaseItem {
    
    public var text: String?
    public var value: String?
    
    override public func populate(from json: JSONDict) {
        text = json["Description"] as? String
        value = json["Value"] as? String
        super.populate(from: json)
    }
}
public class ACQuestionItem2: ACBaseItem {
    public var question: String?
    
    override public func populate(from json: JSONDict) {
        question = json["Description"] as? String
        super.populate(from: json)
        if let orderString = json["ElementOrder"] as? String {
            order = UInt(orderString)
        }
    }
}
public class ACForm2: ACBaseItem {
    
    public var title: String?
    public var questions: [ACQuestionItem2]?
    
    override public func populate(from json: JSONDict) {
        super.populate(from: json)
        title = json["Name"] as? String
    }
    
    public required init() {
        //pMg-W9u-SHa-vWP
    }
}



