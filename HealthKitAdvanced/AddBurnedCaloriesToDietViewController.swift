//
//  AddBurnedCaloriesToDietViewController.swift
//  HealthKitAdvanced
//
//  Created by Nam (Nick) N. HUYNH on 3/18/16.
//  Copyright (c) 2016 Enclave. All rights reserved.
//

import UIKit

@objc(AddBurnedCaloriesToDietViewControllerDelegate)
protocol AddBurnedCaloriesToDietViewControllerDelegate {
    
    optional func addBurnedCaloriesToDietViewController(sender: AddBurnedCaloriesToDietViewController, addedCalorieBurnerWithName: String, calories: Double, startDate: NSDate, endDate: NSDate)
    
}

extension NSDate {
    
    func dateByAddingMinutes(minutes: Double) -> NSDate {
        
        return self.dateByAddingTimeInterval(minutes * 60)
        
    }
    
}

struct CalorieBurner {
    
    var name: String
    var calories: Double
    var startDate = NSDate()
    var endDate = NSDate()
    
    init(name: String, calories: Double, startDate: NSDate, endDate: NSDate) {
        
        self.name = name
        self.calories = calories
        self.startDate = startDate
        self.endDate = endDate
        
    }
    
    init(name: String, calories: Double, minutes: Double) {
        
        self.name = name
        self.calories = calories
        self.startDate = NSDate()
        self.endDate = self.startDate.dateByAddingMinutes(minutes)
        
    }
    
}

class AddBurnedCaloriesToDietViewController: UITableViewController {
    
    struct TableViewValues {
    
        static let identifier = "Cell"
        
    }
    
    lazy var formatter: NSEnergyFormatter = {
        
        let theFormatter = NSEnergyFormatter()
        theFormatter.forFoodEnergyUse = true
        return theFormatter
        
    }()
    
    var delegate: AddBurnedCaloriesToDietViewControllerDelegate!
    
    lazy var allCalorieBurners: [CalorieBurner] = {
        
       let cycling = CalorieBurner(name: "1 hour on the bike", calories: 450, minutes: 60)
        let running = CalorieBurner(name: "30 minutes running", calories: 300, minutes: 30)
        let swimming = CalorieBurner(name: "20 minutes swimming", calories: 400, minutes: 20)
        
        return [cycling, running, swimming]
        
    }()
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
        
    }
    
    // MARK: TableView Datasource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allCalorieBurners.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewValues.identifier, forIndexPath: indexPath) as UITableViewCell
        let burner = allCalorieBurners[indexPath.row]
        let caloriesAsString = formatter.stringFromValue(burner.calories, unit: NSEnergyFormatterUnit.Kilocalorie)
        cell.textLabel.text = burner.name
        cell.detailTextLabel?.text = caloriesAsString
        
        return cell
        
    }
    
    @IBAction func addToDiet(sender: AnyObject) {
    
        let burner = allCalorieBurners[tableView.indexPathForSelectedRow()!.row]
        if let theDelegate = delegate {
            
            theDelegate.addBurnedCaloriesToDietViewController!(self, addedCalorieBurnerWithName: burner.name, calories: burner.calories, startDate: burner.startDate, endDate: burner.endDate)
            
        }
        
        navigationController?.popViewControllerAnimated(true)
        
    }
    
}
