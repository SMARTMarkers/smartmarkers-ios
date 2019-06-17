//
//  FHIRPath.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation


/*
 
 1. Nodes
 2. Trees
 
 - Navigation By Trees
 - Every Result is a List [Array]
 - No logic of single Instances
 - 
 
 
 */


public enum FHIRPathType {
    case math, keypath
}
public enum FHIRCommand: String {
    
    case where_fhir = "where"
    public static let all = [where_fhir]
}

public struct FHIRKeyValue {
    public let command: FHIRCommand
    public let key: String
    public let value: String
    public var _value: String {
        return String(value.dropFirst().dropLast())
    }
}

public struct FHIRNode {
    
    
    
    public let keyPath : String
    public let cmd: [FHIRKeyValue]?
    public let type : String?
    public let vars : [String]?
    
    public init(_ str: String, cmds:[String]?) {
        self.keyPath = str
        if str.first == "%" { type = "root" } else { type = nil }
        self.vars = FHIRNode.getVariables(str)
        var commands = [FHIRKeyValue]()
        if let cmds = cmds {
            for i in 0..<cmds.count {
                let cmd = cmds[i]
                if cmd.contains(FHIRCommand.where_fhir.rawValue) {
                    // "where"
                    let stripped = cmd.slice(from: "(", to: ")")!.split(separator: "=")
                    let keyVal = FHIRKeyValue(command: FHIRCommand.where_fhir, key: String(stripped[0]), value: String(stripped[1]))
                    commands.append(keyVal)
                }
            }
        }
        self.cmd = commands.isEmpty ? nil : commands
    }
    
    
    static func getVariables(_ str: String) -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: "%[a-z0-9]+", options: .caseInsensitive)
            let matches = regex.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
            let vars = matches.map({ (match) -> String in
                let start = str.index(str.startIndex, offsetBy: match.range.location)
                let end   = str.index(start, offsetBy: match.range.length)
                return String(str[start..<end])
            })
            
            return vars.isEmpty ? nil : vars
        }
        catch {
            print(error)
            return nil
        }
    }
    
    
}

public class FHIRPathParser {
    
    public let nodes: [FHIRNode]
    
    public let type: FHIRPathType
    
    public func calculate(_ variables: [String: String]? = nil) {
        
        if let expr = nodes.first?.keyPath {
            
            let expr2 = replace(variables, in: expr)
            print(expr)
            let ns = NSExpression(format: "3*3/(1+2)", [])
            
            print(ns.expressionValue(with: nil, context: nil))
            
        }
        
        
        for n in nodes {
            print(n.keyPath)
            print(n.vars)
            n.cmd?.forEach({ (k) in
                print("\(k.command): \(k.key)=\(k._value)")
            })
            print("----\n------")
        }
        
    }
    
    func replace(_ keywords: [String: String]?, in expression: String) -> String {
        
        guard let keywords = keywords else {
            return expression
        }
        var exp = expression
        for (key, value) in keywords {
            exp = exp.replacingOccurrences(of: key, with: value)
        }
        
        return exp
    }
    
    
    public init(_ expression: String, _ type: FHIRPathType) {
        
        self.type = type
        
        if type == .math {
            self.nodes = [FHIRNode(expression, cmds: nil)]
            return
        }
        
        let strings = expression.split(separator: ".").map { String($0) }
        var actualNodes = [FHIRNode]()
        var currentNodeString = ""
        var commands = [String]()
        for (i,key) in strings.enumerated() {
            
            if key.contains(FHIRCommand.where_fhir.rawValue) { continue }
            currentNodeString = key
            if i+1 < strings.count {
                let next = strings[i+1]
                if next.contains(FHIRCommand.where_fhir.rawValue) {
                    commands.append(next)
                }
            }
            let node = FHIRNode(currentNodeString, cmds: commands)
            actualNodes.append(node)
            currentNodeString = ""
        }
        nodes = actualNodes
        
    }
}


