//
//  ViewController.swift
//  OneLineToShine
//
//  Created by Štěpán Martinek on 07/11/2017.
//  Copyright © 2017 Štěpán Martinek. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var startButt: UIButton!
    
    var patterns: [DrawPattern] = []
    var gameState: NSManagedObject? = nil
    var savedPoints: [NSManagedObject] = []
    var savedVisitedPoints: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create default paterns TODO move to database / load from server
        // Pentagram
        var points = [NeibPoint(0.5,0.0),NeibPoint(4.0/5.0,1.0),NeibPoint(0.0,2.0/5.0),NeibPoint(1.0,2.0/5.0),NeibPoint(1.0/5.0,1.0)]
        for i in 1...points.count-1
        {
            points[i-1].neibours.append(points[i])
            points[i].neibours.append(points[i-1])
        }
        points[points.count-1].neibours.append(points[0])
        points[0].neibours.append(points[points.count-1])
        
        let pentagram = DrawPattern("pentagram",points) 
        patterns.append(pentagram)
        
        //House
        let a = NeibPoint(0.1,1.0)
        let b = NeibPoint(0.9,1.0)
        let c = NeibPoint(0.1,0.1)
        let d = NeibPoint(0.9,0.1)
        let e = NeibPoint(0.5,0.0)
        
        
        a.neibours.append(b)
        a.neibours.append(c)
        a.neibours.append(d)
        
        b.neibours.append(a)
        b.neibours.append(c)
        b.neibours.append(d)
        
        c.neibours.append(a)
        c.neibours.append(b)
        c.neibours.append(d)
        c.neibours.append(e)
        
        d.neibours.append(a)
        d.neibours.append(b)
        d.neibours.append(c)
        d.neibours.append(e)
        
        e.neibours.append(c)
        e.neibours.append(d)
        
        
        let house = DrawPattern("house",[a,b,c,d,e])
        
        patterns.append(house)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is MapViewController
        {
            let vc = segue.destination as! MapViewController
            vc.patterns = patterns
            vc.gameState = gameState
            vc.savedPoints = savedPoints
            vc.savedVisitedPoints = savedVisitedPoints
        }
        if segue.destination is LevelSelectorViewController
        {
            let vc = segue.destination as! LevelSelectorViewController
            vc.patterns = patterns
            vc.gameState = gameState
            vc.savedPoints = savedPoints
            vc.savedVisitedPoints = savedVisitedPoints
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        var fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MyGameState")
        var count = 0
        var states: [NSManagedObject] = []
        // Fetch saved gameState
        do {
            states = try managedContext.fetch(fetchRequest)
            count = states.count
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        // Create new gameState if non is in storage
        if (count < 1)
        {
            createGameState()
        }
        // Use first one we found
        else
        {
            gameState = states.first
        }
        
        // Determine start button text based on gameState
        if (gameState?.value(forKey: "isPlaying") as! Bool)
        {
            startButt.setTitle("Continue", for: .normal)
        }
        else
        {
            startButt.setTitle("Play", for: .normal)
        }
        
        // Fetch saved points
        fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PatternLocations")
        let sectionSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            savedPoints = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        // Fetch already visited points
        fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VisitedPoints")
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            savedVisitedPoints = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    // Create new gameState and save it into storage
    func createGameState() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "MyGameState",
                                                in: managedContext)!
        
        let gs = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        do {
            try managedContext.save()
            gameState = gs
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

}

