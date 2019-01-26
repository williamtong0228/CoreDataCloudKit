//
//  CustomZoneTVC.swift
//  TestingCoreData
//
//  Created by William Mizawa on 20/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class CustomZoneTVC:UITableViewController{
    let container = CKContainer.default().privateCloudDatabase
    let zoneID = CKRecordZone.ID(zoneName: "cachingZone", ownerName: CKCurrentUserDefaultName)
    var items:[CKRecord] = []
    let managedConext = CoreDataHelper.context
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queryCustomBase()
    }
    
    func queryCustomBase(){
        let query = CKQuery(recordType: "LegendarySwords", predicate: NSPredicate(value: true))
        container.perform(query, inZoneWith: zoneID) { (records, error) in
            guard let records = records else {return}
            self.items = records
            for record in records{
                if let insert = NSEntityDescription.insertNewObject(forEntityName: "Swords", into: self.managedConext) as? Swords{
                    insert.edge = record.value(forKey: "name") as? String
                    insert.length = record.value(forKey: "attributes") as! Double
                    insert.recordId = record.recordID.recordName
                    do{
                        try self.managedConext.save()
                    }catch let error{
                        print(error)
                    }
                    
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customprivatecell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].value(forKey: "name") as? String
        
        return cell
    }
}
