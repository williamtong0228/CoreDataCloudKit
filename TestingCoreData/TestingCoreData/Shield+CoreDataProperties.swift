//
//  Shield+CoreDataProperties.swift
//  TestingCoreData
//
//  Created by William Mizawa on 7/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//
//

import Foundation
import CoreData


extension Shield {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shield> {
        return NSFetchRequest<Shield>(entityName: "Shield")
    }

    @NSManaged public var defense: Double
    @NSManaged public var materials: String?
    @NSManaged public var recordId:String?

}
