//
//  ShowSwordVC.swift
//  TestingCoreData
//
//  Created by William Mizawa on 7/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit



class ShowSwordsVC: UITableViewController {
    var recordNametoDelete:String!
    let saveDatabaseToken = "savedLastToken"
    let savedZoneToken = "savedZoneToken"
    let tokenKey = "private"
    var arsenal:[Swords]!
    let cloudData = CKContainer.default().privateCloudDatabase
    let zoneID = CKRecordZone.ID(zoneName: "cachingZone", ownerName: CKCurrentUserDefaultName)
    let managedContext = CoreDataHelper.context
    let fetchRequest:NSFetchRequest<Swords> = Swords.fetchRequest()
     var items:[CKRecord] = []
    

    var myStaticTable:UITableView!

    @IBAction func downLoadCloud(_ sender: Any) {
        UserDefaults.standard.set(nil, forKey:saveDatabaseToken)
        UserDefaults.standard.set(nil, forKey:savedZoneToken)
        arsenal.removeAll()
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Swords")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch  let error {
            print(error)
        }
        
        let query = CKQuery(recordType: "LegendarySwords", predicate: NSPredicate(value: true))
        cloudData.perform(query, inZoneWith: zoneID) { (records, error) in
            guard let records = records else {return}
            self.items = records
//            print(records)
            CloudKitHelper.helper.fetchChanges(in: CKDatabase.Scope.private, completion: {
//                DispatchQueue.main.async {
//
//                    let insertAtt = NSEntityDescription.insertNewObject(forEntityName: "Swords", into: self.managedContext) as? Swords
//                    for record in records{
//                        insertAtt?.edge = record.value(forKey: "name") as? String
//                        insertAtt?.length = record.value(forKey: "attributes") as! Double
//                        insertAtt?.recordId = record.recordID.recordName
//                        self.arsenal.append(insertAtt!)
//                        do{
//                            try self.managedContext.save()
//                        }catch let error{
//                            print(error)
//                        }
//
//
//                    }
//                    print(self.arsenal.count)
//                    self.tableView.reloadData()
//                }
                print("show swords complete")
            })
            print("token saved")
            
           
        }
        
        
        
    }

    @IBAction func refreshTable(_ sender: Any) {
        if arsenal.count == 0 {
            
            DispatchQueue.main.async {
                do {
                    self.arsenal = try self.managedContext.fetch(self.fetchRequest)
                } catch let error {
                    print(error)
                }
                self.tableView.reloadData()
            }
        }
       
    }
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNoti(notification:)), name: Notification.Name("RefreshTableViewNoti"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNoti(notification:)), name: Notification.Name("channelposttableviewrefresh"), object: nil)

        do {
            arsenal = try managedContext.fetch(fetchRequest)
        } catch let error {
            print(error)
        }

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "arsenalCell", for: indexPath)
        cell.textLabel?.text = arsenal[indexPath.row].edge
        
        
        return cell
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
     
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        
        
        return arsenal.count
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            recordNametoDelete = arsenal[indexPath.row].recordId!
          
            queryAndDeleteCouldRecord()
            CoreDataHelper.helper.deleteManagedObject(index: indexPath.row)
            arsenal.remove(at: indexPath.row)
            tableView.reloadData()
            
            
        }
    }
    
    func queryAndDeleteCouldRecord(){
        let query = CKQuery(recordType: "LegendarySwords", predicate: NSPredicate(value: true))
        
        cloudData.perform(query, inZoneWith: zoneID) { (records, error) in
//            guard let records = records else {return}
            do {
                self.arsenal = try self.managedContext.fetch(self.fetchRequest)
                
                for item in self.arsenal{
                    
                    if item.recordId == self.recordNametoDelete{
                        self.managedContext.delete(item)
                    }
                }
                
               
            } catch let error {
                print(error)
            }
           print(self.recordNametoDelete)
            if let recName = self.recordNametoDelete{
                print("Search on Cloud", recName)
                if let records = records {
                    var recordIds:[CKRecord.ID] = []
                    for record in records{
                        if record.recordID.recordName == recName {
                            recordIds.append(record.recordID)
                            print("Search on Cloud id", record.recordID)
//                            self.cloudData.delete(withRecordID: record.recordID, completionHandler: { (recordId, error) in
//                                print(error!)
//                            })
                            }
                    }

                    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIds)
                    operation.savePolicy = .ifServerRecordUnchanged

                    
                    self.cloudData.add(operation)
                }
            }
           
            
            
        }
    }
    

    @objc func handleNoti(notification:Notification) {
    
        do {
            arsenal = try managedContext.fetch(fetchRequest)
        } catch let error {
            print(error)
        }
            self.tableView.reloadData()
        

    }
  
    
}


extension ShowSwordsVC:RefreshTableViewDelegate{

    func timeToRefresh() {
        
        do {
            arsenal = try managedContext.fetch(fetchRequest)
        } catch let error {
            print(error)
        }
        
        self.tableView.reloadData()
        
        
    }
    
    
}

