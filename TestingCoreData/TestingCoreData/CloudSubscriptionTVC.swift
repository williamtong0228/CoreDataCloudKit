//
//  CloudSubscriptionTVC.swift
//  TestingCoreData
//
//  Created by William Mizawa on 19/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import Foundation
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
class CloudSubscriptionTVC: UITableViewController {
let savedTokenKey = "savedZoneToken"
let cloudDatabase = CKContainer.default().privateCloudDatabase
var subscriptionIsCached = false
var createdCustomZone = false
let zoneID = CKRecordZone.ID(zoneName: "cachingZone", ownerName: CKCurrentUserDefaultName)
var cloudObserver:NSObjectProtocol?

var items:[CKRecord] = []
override func viewDidLoad() {
    super.viewDidLoad()
    
    
    cloudObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("pushingcloudnoti"),
                                                           object: nil,
                                                           queue: OperationQueue.main,
                                                           using: { notification in
                                                            print("notification accepted")
                                                            if let query = notification.userInfo?["private-changes"] as? CKQueryNotification{
                                                                switch query.queryNotificationReason {
                                                                case .recordCreated:
                                                                    self.cloudDatabase.fetch(withRecordID: query.recordID!, completionHandler: { record, error in
                                                                        if record != nil {
                                                                            DispatchQueue.main.async {
                                                                                self.items = self.items + [record!]
                                                                            }
                                                                        }
                                                                    })
                                                                    
                                                                default:
                                                                    print("cloudkit query error")
                                                                }
                                                            }
    })
}






override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellsubscribe", for: indexPath)
    cell.textLabel?.text = (items[indexPath.row].value(forKey: "name") as! String)
    return cell
}

override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
}
}
