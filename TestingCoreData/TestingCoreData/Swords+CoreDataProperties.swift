//
//  Swords+CoreDataProperties.swift
//  TestingCoreData
//
//  Created by William Mizawa on 7/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//
//

import Foundation
import CoreData


extension Swords {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Swords> {
        return NSFetchRequest<Swords>(entityName: "Swords")
    }

    @NSManaged public var edge: String?
    @NSManaged public var length: Double
    @NSManaged public var recordId:String?
}
