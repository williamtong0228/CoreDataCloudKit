//
//  ViewController.swift
//  TestingCoreData
//
//  Created by William Mizawa on 7/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import CloudKit


protocol RefreshTableViewDelegate {
    func timeToRefresh()
}

class ViewController: UIViewController,UITextFieldDelegate{
   

    
    let saveDatabaseToken = "savedLastToken"
    let savedZoneToken = "savedZoneToken"
   let createZoneGroup = DispatchGroup()
    var subscriptionIsCached = false
    var createdCustomZone = false
    var refreshNow = false
    let zoneID = CKRecordZone.ID(zoneName: "cachingZone", ownerName: CKCurrentUserDefaultName)
   let context = CoreDataHelper.context
     var items:[CKRecord] = []
    let cloudDatabase = CKContainer.default().privateCloudDatabase
    var myDelegate:RefreshTableViewDelegate!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgeName.delegate = self
        self.lengthNum.delegate = self
        myDelegate = ShowSwordsVC.self()
       
        // Do any additional setup after loading the view, typically from a nib.
//        let context = CoreDataHelper.context
////
////        let mySword = NSEntityDescription.insertNewObject(forEntityName: "Swords", into: context) as! Swords
////        mySword.edge = "Double Edge"
////        mySword.length = 3.0
////        CoreDataHelper.saveContext()
////
//        let fetchRequest:NSFetchRequest<Swords> = Swords.fetchRequest()
//        fetchRequest.returnsObjectsAsFaults = false
//
//        do {
//            let managedArr:[Swords] = try context.fetch(fetchRequest)
//            for item in managedArr{
//                print(item)
//            }
//
//        } catch let err {
//            print(err)
//
//        }
  
        
        createCustomZone()

        subscribe()
        
        
                       
                            
        
    }

    func fetchChanges(in databaseScope:CKDatabase.Scope, completion: @escaping() -> Void){
        guard databaseScope == .private else {
            return
        }
        
        fetchDatabaseChanges(database: self.cloudDatabase, tokenKey: "private", completion: completion)
        
    }
    
    func fetchDatabaseChanges(database:CKDatabase, tokenKey:String, completion: @escaping() ->Void) {
        var changedZoneID:[CKRecordZone.ID] = []
        var deletedZoneID:[CKRecordZone.ID] = []
        var fetchToken:[CKServerChangeToken] = []
        var data:Data!
         var changeToken:CKServerChangeToken?
        
        if UserDefaults.standard.object(forKey: saveDatabaseToken) != nil {
            data = UserDefaults.standard.object(forKey: saveDatabaseToken) as? Data
            
            do{
                changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
            }catch let error{
                changeToken = nil
                print(error)
            }
            
        }
        
       
       
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        
        print("Database Change Token ", changeToken ?? "")
        
        operation.recordZoneWithIDChangedBlock = { zoneID in
            changedZoneID.append(zoneID)
            print("Zone Change \(zoneID)")
        }
        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
            deletedZoneID.append(zoneID)
            print("Zone Deletion \(zoneID)")
        }
        operation.changeTokenUpdatedBlock = { token in
            fetchToken.append(token)
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            print(token)
           
           
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: self.saveDatabaseToken)

            }catch let error{
                print("NSKEYEARCHIVER ERROR \(error)")
            }
            
            
        }
        
        
        operation.fetchDatabaseChangesCompletionBlock = { token, moreComing, error in
            if let error = error {
                print("Error during fetch", error)
                completion()
                return
            }
            
            print("download token", token!)
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            
            
        
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: token!, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: self.saveDatabaseToken)
                
            }catch let error{
                print("NSKEYEARCHIVER ERROR \(error)")
            }
        
            
            self.fetchZoneChanges(database: database, databaseTokenKey: tokenKey, zoneIDs: changedZoneID){
                completion()
            }
            
        }
        operation.qualityOfService = .utility
        database.add(operation)
    }
    
    func fetchZoneChanges(database:CKDatabase, databaseTokenKey:String, zoneIDs:[CKRecordZone.ID], completion: @escaping ()->Void){
        var data:Data!
        var changeToken:CKServerChangeToken?
        
        if UserDefaults.standard.object(forKey: savedZoneToken) != nil {
            data = UserDefaults.standard.object(forKey: savedZoneToken) as? Data
            
            do{
                changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
            }catch let error{
                print(error)
            }
        }
        
        
        var optionsByRecordZoneID = [CKRecordZone.ID:CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
        for zoneID in zoneIDs{
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            options.previousServerChangeToken = changeToken
            print("changeTokenZone ", changeToken ?? "WTFWTF")
            optionsByRecordZoneID[zoneID] = options
            
            if changeToken == nil {
                refreshNow = true
              
                
            }
            
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID)
        operation.recordChangedBlock = { record in
            print("Zone Change Record changed:", record.value(forKey: "name") ?? "")
            // Write this record change to memory
//            let fetchRequest:NSFetchRequest<Swords> = Swords.fetchRequest()
            DispatchQueue.main.sync {
                do{
                    let itemToPersist = NSEntityDescription.insertNewObject(forEntityName: "Swords", into: self.context) as? Swords
                    itemToPersist?.edge = record.value(forKey: "name") as? String
                    itemToPersist?.length = record.value(forKey: "attributes") as! Double
                    itemToPersist?.recordId = record.recordID.recordName
                    try self.context.save()
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshTableViewNoti"), object: self)
                     self.myDelegate.timeToRefresh()
                    
                }catch let error{
                    print(error)
                }
            }
           
            
        }
        operation.recordWithIDWasDeletedBlock = { recordId, recordType in
        
            let record = CKRecord(recordType: recordType, recordID: recordId)
            let recName = record.recordID.recordName
//            let recAtt = record.value(forKey: "attributes") as? Double
            print("Record deleted:", record)
            print("Print Deleted Item ", recName as Any)
                    // Write this record deletion to memory
//            let record = recordId.
            let fetchRequest:NSFetchRequest<Swords> = Swords.fetchRequest()
            do{
                var coreWeapons = try self.context.fetch(fetchRequest) as [Swords]
                if coreWeapons.count > 0 {
                    for i in 0 ... coreWeapons.count-1 {
                        
                        if coreWeapons[i].recordId == recName {
                            print("Coredata deleted items: ", coreWeapons[i].recordId ?? "")
                            self.context.delete(coreWeapons[i])
                            do{
                                try self.context.save()
                            }catch let error{
                                print(error)
                            }
                            
                            
                            
                            
                            
                        }
                    }
                }
               
                
               
                
            }catch let error{
                print(error)
            }
           
            
//            do {
//               var updated = try self.context.fetch(fetchRequest)
//                for item in updated{
//                    print("update Coredata", item.edge)
//                }
//            } catch let error {
//                print(error)
//            }
        
                }
        operation.recordZoneChangeTokensUpdatedBlock = { zoneId, token, data in
            
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            print(token ?? "")
            print(zoneId.zoneName)
            print(token?.description as Any)
            
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneId,changeToken,_,_,error in
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                
                return
            }
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            
            
            do{
                let data = try NSKeyedArchiver.archivedData(withRootObject: changeToken!, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: self.savedZoneToken)
            }catch let error{
                print("recordZoneFetchCompletionBlock error: ", error)
            }
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
//            completion()
            if self.refreshNow == true{
                self.refreshNow = false
                DispatchQueue.main.sync {
                    print("call delegate custom")
                    if self.self == ViewController.self(){
                       
                    }
                    
                }
                
                
                
                
            }
        }
        
        database.add(operation)
        
        
        
        
    }
    func createCustomZone(){
        
        if let checkZone = UserDefaults.standard.object(forKey: "CustomZone"){
            self.createdCustomZone = (checkZone  as? Bool)!
        }
        
        if !self.createdCustomZone {
            createZoneGroup.enter()
            let customeZone = CKRecordZone(zoneID: zoneID)
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customeZone], recordZoneIDsToDelete: [])
            createZoneOperation.modifyRecordZonesCompletionBlock = {saved, deleted, error in
                if error == nil {
                    self.createdCustomZone = true
                    UserDefaults.standard.set(self.createdCustomZone, forKey: "CustomZone")
                }
                //else error handling
                self.createZoneGroup.leave()
            }
            
            createZoneOperation.qualityOfService = .utility
            self.cloudDatabase.add(createZoneOperation)
        }
    }
    
    func subscribe() {
        subscriptionIsCached = UserDefaults().bool(forKey: "Subscribed")
        guard subscriptionIsCached == false else {
            return
        }
        
//        let subscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId:"arsenal")
        
        let subscription = CKDatabaseSubscription(subscriptionID: "arsenal")
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        
        operation.modifySubscriptionsCompletionBlock = { subscritions, deletedIds, error in
            guard error == nil else {return}
            self.subscriptionIsCached = true
            
            UserDefaults.standard.set(self.subscriptionIsCached, forKey: "Subscribed")
            
        }
        operation.qualityOfService = .utility
        cloudDatabase.add(operation)
        
        createZoneGroup.notify(queue: DispatchQueue.global()){
            if self.createdCustomZone{
                self.fetchChanges(in: .private){
                }
            }
        }
        
        
    }
    

    

    @IBAction func addSwords(_ sender: Any) {
        edgeName.resignFirstResponder()
        self.view.endEditing(true)
        
        let edge = edgeName.text
        guard edge != nil else {return}
        
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .decimal
        
        
        let length = numFormatter.number(from: lengthNum.text!)?.doubleValue
        guard length != nil else {return}
        
        
        let context = CoreDataHelper.context
        let insertItem = NSEntityDescription.insertNewObject(forEntityName: "Swords", into: context) as? Swords
    
        
        insertItem!.edge = edge
        insertItem!.length = length!
        
        do {
            try context.save()
//            swordName.text = ""
            edgeName.text = ""
            lengthNum.text = ""
            
            let fetch:NSFetchRequest<Swords> = Swords.fetchRequest()
            saveToCloud(category: edge!, length: Double(length!))
            do {
                let managedArr:[Swords] = try context.fetch(fetch)
                for item in managedArr{
                    print(item)
                }
                
            } catch let err {
                print(err)
                
            }
        } catch let error {
            print(error)
        }
        
    }
    @IBAction func addShields(_ sender: Any){
        
        let materials = materialsName.text
        guard materials != nil else {return}
        
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .decimal
        
        let defense = numFormatter.number(from: defenseNum.text!)?.doubleValue
        guard defense != nil else {return}
        
        let context = AegisDataHelper.context
        let insertItem = NSEntityDescription.insertNewObject(forEntityName: "Shield", into: context) as? Shield
        insertItem!.materials = materials
        insertItem!.defense = defense!
        do {
            try context.save()
//            shieldName.text = ""
            defenseNum.text = ""
            materialsName.text = ""
        } catch let error {
            print(error)
        }
        
    }
    
    func saveToCloud(category:String, length:Double){
        let record = CKRecord(recordType: "LegendarySwords")
        

        let customRecordID = CKRecord.ID(recordName: record.recordID.recordName, zoneID: zoneID)
        let customRecord = CKRecord(recordType: "LegendarySwords", recordID: customRecordID)
        customRecord.setValue(category, forKey: "name")
        
        customRecord.setValue(length, forKey: "attributes")
        
        
        cloudDatabase.save(customRecord) { (customRecord, error) in
            print("\(String(describing: error))")
            guard customRecord != nil else {return}
            print("Saved to cloud")
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    @IBOutlet weak var swordName: UITextField!
    @IBOutlet weak var edgeName: UITextField!
    @IBOutlet weak var lengthNum: UITextField!
    
    @IBOutlet weak var shieldName:UITextField!
    @IBOutlet weak var defenseNum:UITextField!
    @IBOutlet weak var materialsName:UITextField!
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "SwordSegue"{
//            let swordView = segue.destination as? ShowSwordsVC
//            swordView!.delegate = myDelegate
//
//        }
//    }
}



