//
//  ListCaloriesBurnedTableViewController.swift
//  HealthKitAdvanced
//
//  Created by Nam (Nick) N. HUYNH on 3/18/16.
//  Copyright (c) 2016 Enclave. All rights reserved.
//

import UIKit
import HealthKit

let HKMetadataKeyExerciseName = "ExerciseName"

extension NSDate {
    
    func beginningOfDay() -> NSDate {
        
        return NSCalendar.currentCalendar().dateBySettingHour(0, minute: 0, second: 0, ofDate: self, options: NSCalendarOptions.WrapComponents)!
        
    }
    
}

class ListCaloriesBurnedTableViewController: UITableViewController {
    
    var allCaloriesBurned = [CalorieBurner]()
    lazy var formatter: NSEnergyFormatter = {
        
       let theFormatter = NSEnergyFormatter()
        theFormatter.forFoodEnergyUse = true
        return theFormatter
        
    }()
    
    var isObservingBurnedCalories = false
    lazy var unit = HKUnit.kilocalorieUnit()
    
    struct TableViewValues {
    
        static let identifier = "Cell"
        
    }
    
    let burnedEnergyQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
    
    lazy var types: NSSet = {
        
        return NSSet(objects: self.burnedEnergyQuantityType)
        
    }()
    
    lazy var query: HKObserverQuery = {
        
       return HKObserverQuery(sampleType: self.burnedEnergyQuantityType, predicate: self.predicate, updateHandler: self.burnedCaloriesChangedHandler)
        
    }()
    
    lazy var healthStore = HKHealthStore()
    lazy var predicate: NSPredicate = {
        
        let option: NSCalendarOptions = NSCalendarOptions.WrapComponents
        let now = NSDate()
        let beginningOfToday = now.beginningOfDay()
        
        let tomorrow = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.DayCalendarUnit, value: 1, toDate: now, options: option)
        let beginningOfTomorrow = tomorrow?.beginningOfDay()
        
        return HKQuery.predicateForSamplesWithStartDate(beginningOfToday, endDate: beginningOfTomorrow, options: HKQueryOptions.StrictEndDate)
        
    }()
    
    deinit {
        
        stopObservingBurnedCaloriesChanges()
        
    }
    
    // MARK: Observing changes
    
    func startObservingBurnedCaloriesChanges() {
        
        if isObservingBurnedCalories {
            
            return
            
        }
        
        healthStore.executeQuery(self.query)
        healthStore.enableBackgroundDeliveryForType(burnedEnergyQuantityType, frequency: HKUpdateFrequency.Immediate) { (succeeded, error) -> Void in
            
            if succeeded {
                
                self.isObservingBurnedCalories = true
                println("Enabled successfully!")
                
            } else {
                
                if let theError = error {
                    
                    println("Error: \(theError)")
                    
                }
                
            }
            
        }
        
    }
    
    func stopObservingBurnedCaloriesChanges() {
        
        if isObservingBurnedCalories == false {
            
            return
            
        }
        
        healthStore.stopQuery(self.query)
        healthStore.disableAllBackgroundDeliveryWithCompletion { (succeeded, error) -> Void in
            
            if succeeded {
                
                self.isObservingBurnedCalories = false
                
            } else {
                
                if let theError = error {
                    
                    println("Error: \(theError)")
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: Handler and fetch
    
    func fetchBurnedCaloriesInLastDay() {
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: burnedEnergyQuantityType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, results, error) -> Void in
            
            if results.count > 0 {
                
                self.allCaloriesBurned = [CalorieBurner]()
                for sample in results as [HKQuantitySample] {
                    
                    let burnerName = sample.metadata[HKMetadataKeyExerciseName] as NSString
                    let calories = sample.quantity.doubleValueForUnit(self.unit)
                    let caloriesAsString = self.formatter.stringFromValue(calories, unit: NSEnergyFormatterUnit.Kilocalorie)
                    let burner = CalorieBurner(name: burnerName, calories: calories, startDate: sample.startDate, endDate: sample.endDate)
                    self.allCaloriesBurned.append(burner)
                    
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    self.tableView.reloadData()
                    
                })
                
            } else {
                
                println("No data available")
                
            }
            
        }
        
        healthStore.executeQuery(query)
        
    }
    
    func burnedCaloriesChangedHandler(query: HKObserverQuery!, completionHandler: HKObserverQueryCompletionHandler!, error: NSError!) {
        
        fetchBurnedCaloriesInLastDay()
        completionHandler()
        
    }
    
    // MARK: ViewController life cycle
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        if HKHealthStore.isHealthDataAvailable() {
            
            healthStore.requestAuthorizationToShareTypes(types, readTypes: types, completion: { (succeeded, error) -> Void in
                
                if succeeded && error == nil {
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        
                        self.startObservingBurnedCaloriesChanges()
                        
                    })
                    
                } else {
                    
                    if let theError = error {
                        
                        println("Error: \(theError)")
                        
                    }
                    
                }
                
                if self.allCaloriesBurned.count > 0 {
                    
                    let firstCell = NSIndexPath(forItem: 0, inSection: 0)
                    self.tableView.selectRowAtIndexPath(firstCell, animated: false, scrollPosition: UITableViewScrollPosition.Top)
                    
                }
                
            })
            
        }
        
    }
    
    // MARK: TableView Datasource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allCaloriesBurned.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewValues.identifier, forIndexPath: indexPath) as UITableViewCell
        let burner = allCaloriesBurned[indexPath.row]
        let caloriesAsString = formatter.stringFromValue(burner.calories, unit: NSEnergyFormatterUnit.Kilocalorie)
        cell.textLabel.text = burner.name
        cell.detailTextLabel?.text = caloriesAsString
        
        return cell
        
    }
    
    // MARK: Segue preparing
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "BurnCalories" {
            
            let controller = segue.destinationViewController as AddBurnedCaloriesToDietViewController
            controller.delegate = self
            
        }
        
    }
    
}

extension ListCaloriesBurnedTableViewController: AddBurnedCaloriesToDietViewControllerDelegate {
    
    func addBurnedCaloriesToDietViewController(sender: AddBurnedCaloriesToDietViewController, addedCalorieBurnerWithName: String, calories: Double, startDate: NSDate, endDate: NSDate) {
        
        let quantity = HKQuantity(unit: unit, doubleValue: calories)
        let metadata = [HKMetadataKeyExerciseName: addedCalorieBurnerWithName]
        let sample = HKQuantitySample(type: burnedEnergyQuantityType, quantity: quantity, startDate: startDate, endDate: endDate, metadata: metadata)
        healthStore.saveObject(sample, withCompletion: { (succeeded, error) -> Void in
            
            if succeeded {
                
                println("Saved successfully")
                self.tableView.reloadData()
                
            } else {
                
                if let theError = error {
                    
                    println("Error: \(theError)")
                    
                }
                
            }
            
        })
        
    }
    
}