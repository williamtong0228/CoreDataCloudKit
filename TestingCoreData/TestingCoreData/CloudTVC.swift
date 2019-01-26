//
//  CloudTVC.swift
//  TestingCoreData
//
//  Created by William Mizawa on 15/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class CloudTVC: UITableViewController {




    let managedConext = CoreDataHelper.context
    let savedTokenKey = "savedZoneToken"
    let cloudDatabase = CKContainer.default().privateCloudDatabase
    var subscriptionIsCached = false
    var createdCustomZone = false
    let zoneID = CKRecordZone.ID(zoneName: "cachingZone", ownerName: CKCurrentUserDefaultName)
    var cloudObserver:NSObjectProtocol?
    
    var items:[CKRecord] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        queryCloudDatabase(zoneId: zoneID)
        
        
        
    }
    
    func queryCloudDatabase(zoneId: CKRecordZone.ID){
        let query = CKQuery(recordType: "LegendarySwords", predicate: NSPredicate(value: true))
        
        cloudDatabase.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else {return }
            self.items = records
          
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
        }
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "clouditemcell", for: indexPath)
        cell.textLabel?.text = (items[indexPath.row].value(forKey: "name") as! String)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
    }
}
