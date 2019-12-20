//
//  Inflators.swift
//  Inflator: a list of json inflators, like viewlet creator
//

import JsonInflator

class Inflators {
    
    static let module = JsonInflator(inflatableKey: "module")
    static let viewlet = JsonInflator(inflatableKey: "viewlet", attributeSetKey: "viewletStyle")

}
