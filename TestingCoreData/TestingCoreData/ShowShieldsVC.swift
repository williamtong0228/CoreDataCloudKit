//
//  ShowShieldsVC.swift
//  TestingCoreData
//
//  Created by William Mizawa on 7/12/2018.
//  Copyright © 2018 William Mizawa. All rights reserved.
//

import Foundation
import UIKit
import CoreData
class ShowShieldsVC: UITableViewController {
    var armor:[Shield]!
    override func viewDidLoad() {
        super.viewDidLoad()
        let managedContext = AegisDataHelper.context
        let fetchRequest:NSFetchRequest<Shield> = Shield.fetchRequest()
        
        
        do {
            armor = try managedContext.fetch(fetchRequest)
        } catch let error {
            print(error)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return armor.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "armorCell", for: indexPath)
        cell.textLabel?.text = armor[indexPath.row].materials
        
        return cell
    }
}
