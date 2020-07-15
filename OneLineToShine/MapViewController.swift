//
//  MapViewController.swift
//  OneLineToShine
//
//  Created by Štěpán Martinek on 14/11/2017.
//  Copyright © 2017 Štěpán Martinek. All rights reserved.
//

import UIKit
import MapKit
import CoreData

// Helper class cointing point coordinates and list of neighbor points
class NeibPoint
{
    var x: Double
    var y: Double
    
    var neibours: [NeibPoint] = []
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

// Helper class represing points in real world location position
class LocPoint: CLLocation
{
    var neibours: [LocPoint] = []
    var visited: Int = 0
    
    convenience init(point: NeibPoint, mapView: MKMapView)
    {
        let mRect = mapView.bounds;
        let temp = Double(min(mRect.size.width, mRect.size.height))
        let padding : Double = temp * 0.05
        let side : Double = temp * 0.9
        let startX = (Double(mRect.size.width) - side) / 2.0
        let x : Double = Double(mRect.origin.x) + startX + side * point.x
        let y : Double = Double(mRect.origin.y) + padding + side * point.y
        let loc = mapView.convert(CGPoint(x: x, y: y), toCoordinateFrom: mapView)
        
        self.init(latitude: loc.latitude, longitude: loc.longitude)
    }
    
    convenience init(_ lat: Double,_ long: Double,_ vis: Int)
    {
        self.init(latitude: lat, longitude: long)
        visited = vis
    }
}

class MapViewController: UIViewController, MKMapViewDelegate, MapOverlayViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var overlayView: MapOverlayView!
    
    var locationManager = CLLocationManager()
    
    var gameState: NSManagedObject? = nil
    var savedPoints: [NSManagedObject] = []
    var savedVisitedPoints: [NSManagedObject] = []
    
    var points: [NeibPoint] = []
    var patterns: [DrawPattern] = []
    var pointsLoc: [LocPoint] = []
    var visitedPoints: [LocPoint] = []
    var polyLinesNotVisited: [MKPolyline] = []
    var polyLinesVisited: [MKPolyline] = []
    var polyLineToPlayer: MKPolyline? = nil
    
    var currentPattern: Int
    {
        get {
            return gameState!.value(forKey: "currentPattern") as! Int
        }
        set(newValue) {
            return gameState!.setValue(newValue, forKey: "currentPattern")
        }
    }
    var isPlaying: Bool {
        get {
            return gameState!.value(forKey: "isPlaying") as! Bool
        }
        set(newValue) {
            return gameState!.setValue(newValue, forKey: "isPlaying")
        }
    }
    
    // Maximum distance from point we want to lock
    let POINT_LOCK_MAX_DISTANCE = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        		
        // LocationMgr
        //Check for Location Services
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // MapView init
        mapView.delegate = self
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = true
        
        // Overlay init
        overlayView.delegate = self
        overlayView.controller = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
               
        // If we dont have gameState, return back to patern selection
        if (gameState == nil)
        {
            performReturnBack()
            return
        }
        
        points = patterns[currentPattern].points
        pointsLoc = []
        visitedPoints = []
        polyLinesNotVisited = []
        polyLinesVisited = []
        polyLineToPlayer = nil
        
        // If state is playing start game
        if (isPlaying)
        {
            startGame(mapView, true)
        }
        // Otherwise cleanup in preparation for new pattern
        else
        {
            clearPoints()
        }
        
        
        // LocationMgr
        checkLocationAuthorizationStatus()
        locationManager.startUpdatingLocation()
        
        //Zoom to user location
        if (locationManager.location != nil)
        {
            let viewRegion = MKCoordinateRegionMakeWithDistance((locationManager.location?.coordinate)!, 200, 200)
            mapView.setRegion(viewRegion, animated: false)
        }
        
        // Overlay init
        overlayView.updateDistance(calculateDrawingLenght())
        overlayView.updatePlayState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Retrieve attribute (valueName) of saved point (index)
    private func getSavedPoint<T>(_ index: Int, _ valueName: String) -> T
    {
        return savedPoints[index].value(forKey: valueName) as! T
    }
    
    // MapView delegate functions
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        if (!isPlaying)
        {
            overlayView.updateDistance(calculateDrawingLenght())
        }
    }
    
    func controllButtPressed(_ overlayView: MapOverlayView) {
        // If we are not playing start a game
        if (!isPlaying)
        {
            isPlaying = !isPlaying
            overlayView.updatePlayState()
            // Redraw everything
            overlayView.setNeedsDisplay()
            
            startGame(mapView, false)
        }
        // Otherwise try to lock a point
        else
        {
            lockPoint(mapView)
        }
    }
    
    private func startGame(_ mapView: MKMapView, _ load: Bool)
    {
        pointsLoc = []
        
        // Drop a pin on points locations and fill pointsLoc list with real world points
        for (index,point) in points.enumerated() {
            let myAnnotation: MKPointAnnotation = MKPointAnnotation()
            if (load)
            {
                pointsLoc.append(LocPoint(getSavedPoint(index, "lat"), getSavedPoint(index, "long"), getSavedPoint(index, "visited")))
            }
            else
            {
                pointsLoc.append(LocPoint(point: point,mapView: mapView))
            }
            myAnnotation.coordinate = pointsLoc.last!.coordinate
            myAnnotation.title = "Point \(index+1)"
            mapView.addAnnotation(myAnnotation)
        }
        
        // Fill neighbors array of points
        for (index,point) in points.enumerated() {
            for neib in point.neibours
            {
                if let i = points.index(where: { $0 === neib })
                {
                    pointsLoc[index].neibours.append(pointsLoc[i])
                }
            }
        }
        
        // If we have loaded the game load visited points
        if (load)
        {
            for visited in savedVisitedPoints
            {
                let index = visited.value(forKey: "visitedIndex") as! Int
                visitedPoints.append(pointsLoc[index])
            }
        }
        // Save points for new game
        else
        {
            savePoints()
        }
        
        // Update polylines between points
        updatePolyLines(mapView, pointsLoc.first!)
        
        // Check distance from nearest point and update text displaying it
        if (locationManager.location != nil)
        {
            let (_, nearestDist) = findNearestPoint(mapView, locationManager.location!)
            overlayView.updateDistance(nearestDist)
        }
    }
    
    private func findNearestPoint(_ mapView: MKMapView, _ location: CLLocation) -> (LocPoint?, Int)
    {
        var nearestLoc: LocPoint?
        var nearestDist = 0.0
        for loc in pointsLoc
        {
            let dist = loc.distance(from: location)
            if (nearestLoc == nil || dist < nearestDist)
            {
                nearestLoc = loc
                nearestDist = dist
            }
        }
        
        return (nearestLoc, nearestLoc != nil ? Int(nearestDist) : -1)
    }
    
    private func lockPoint(_ mapView: MKMapView)
    {
        if (locationManager.location == nil)
        {
            checkLocationAuthorizationStatus()
            return
        }
        
        // Find nearest point
        let (nearestLoc, nearestDist) = findNearestPoint(mapView, locationManager.location!)
        
        // Check conditions if we can lock a point
        if (nearestLoc == nil || nearestDist > POINT_LOCK_MAX_DISTANCE)
        {
            alert("You need to be max \(POINT_LOCK_MAX_DISTANCE) meters from point to lock it")
            return
        }
        
        let loc = nearestLoc!
        let originalVisited = loc.visited
        
        // If we have not visited any points yet set visited times to 1 (for future, where multiple visits might be necessary)
        if (visitedPoints.isEmpty)
        {
            loc.visited += 1;
        }
        // If last point we visited was this one, we are unlocking it
        else if (visitedPoints.last! == loc)
        {
            loc.visited -= 1;
        }
        // If this point is neighbor of last visited point we are alowing it to lock
        else if (loc.neibours.contains(visitedPoints.last!))
        {
            loc.visited += 1;
        }
        else
        {
            alert("Follow the pattern. You can only lock neiborough points (or unlock last locked point)")
            return
        }
        
        if (loc.visited > originalVisited)
        {
            addVisitedPoint(loc)
        }
        else
        {
            removeVisitedPoint(loc)
        }
        
        savePoints()
        updatePolyLines(mapView, loc)
        
        checkWinCondition()
    }

    private func updatePolyLines(_ mapView: MKMapView,_ firstVisit: LocPoint)
    {
        // Remove all lines
        for line in polyLinesVisited + polyLinesNotVisited
        {
            mapView.remove(line)
        }
        // Remove line to player if exists
        if (polyLineToPlayer != nil)
        {
            mapView.remove(polyLineToPlayer!)
        }
        polyLinesVisited = []
        polyLinesNotVisited = []
        polyLineToPlayer = nil
        
        // Create lines between visited points
        var visitedPairs: [(LocPoint,LocPoint)] = []
        if (visitedPoints.count > 1)
        {
            for i in 1...visitedPoints.count-1
            {
                polyLinesVisited.append(MKPolyline(coordinates: [visitedPoints[i-1].coordinate, visitedPoints[i].coordinate], count: 2))
                visitedPairs.append((visitedPoints[i-1], visitedPoints[i]))
            }
        }
        // Create polylines for not visited lines between points
        var processed: [LocPoint] = []
        var toVisit = [firstVisit]
        while (!toVisit.isEmpty)
        {
            let point = toVisit.first!
            toVisit.remove(at: 0)
            processed.append(point)
            
            for neib in point.neibours
            {
                if (!processed.contains(neib))
                {
                    toVisit.append(neib)
                    if (!visitedPairs.contains(where: { ($0.0 === point && $0.1 === neib) || ($0.0 === neib && $0.1 === point)}))
                    {
                        polyLinesNotVisited.append(MKPolyline(coordinates: [point.coordinate, neib.coordinate], count: 2))
                    }
                }
            }
            
        }
        
        // Add all lines to map
        for polyLine in polyLinesNotVisited + polyLinesVisited
        {
            mapView.add(polyLine)
        }
        
        // Create and att player line if he has locket at least one point already
        if (!visitedPoints.isEmpty)
        {
            polyLineToPlayer = MKPolyline(coordinates: [visitedPoints.last!.coordinate,locationManager.location!.coordinate], count: 2)
            mapView.add(polyLineToPlayer!)
        }
    }
    
    private func checkWinCondition()
    {
        var ok = true
        // Check if any point is missing visit
        for point in pointsLoc
        {
            if (point.visited < point.neibours.count / 2)
            {
                ok = false
                break
            }
        }
        
        if (ok)
        {
            // Remove line to player
            if (polyLineToPlayer != nil)
            {
                mapView.remove(polyLineToPlayer!)
            }
            
            // Create win alert dismiss action
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                self.performReturnBack()
            }
            
            clearPoints()
            gameState?.setValue(max(currentPattern+1, patterns.count - 1), forKey: "nextPattern")
            alert("Congratulation! You have won The Game", action)
        }
    }
    
    // Differentiate Polylines color based on type
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline
        {
            let lineView = MKPolylineRenderer(overlay: overlay)
            let polyLine = overlay as! MKPolyline
            if (polyLinesNotVisited.contains(polyLine))
            {
                lineView.strokeColor = UIColor.darkGray
            }
            else if (polyLinesVisited.contains(polyLine))
            {
                lineView.strokeColor = UIColor.blue
            }
            else
            {
                lineView.strokeColor = UIColor.red
            }
            
            return lineView
        }
        
        return MKOverlayRenderer()
    }
    
    // Helper function to calculate distance in meters between all points (used when setting up a patern)
    private func calculateDrawingLenght() -> Int
    {
        
        var distanceInMeters = 0.0
        
        var pLoc : [LocPoint] = []
        if (pointsLoc.isEmpty)
        {
            for point in points
            {
                pLoc.append(LocPoint(point: point, mapView: mapView))
            }
        }
        else
        {
            pLoc.append(contentsOf: pointsLoc)
        }
        
        for i in 1...pLoc.count-1
        {
            distanceInMeters += pLoc[i-1].distance(from: pLoc[i])
        }
        distanceInMeters += pLoc[0].distance(from: pLoc[pLoc.count-1])
        
        return Int(distanceInMeters)
    }
    
    // Helper functions

    private func alert(_ msg: String, _ action: UIAlertAction? = nil)
    {
        let alert = UIAlertController(title: "Alert", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        
        if (action != nil)
        {
            alert.addAction(action!)
        }
        else
        {
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func performReturnBack()
    {
        
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func addVisitedPoint(_ loc: LocPoint)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let index = pointsLoc.index(where: { $0 === loc }) else
        {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "VisitedPoints",
                                                in: managedContext)!
        
        let newPoint = NSManagedObject(entity: entity,
                                       insertInto: managedContext)
        
        newPoint.setValue(visitedPoints.count, forKeyPath: "index")
        newPoint.setValue(index, forKeyPath: "visitedIndex")
        
        do {
            try managedContext.save()
            savedPoints.append(newPoint)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        visitedPoints.append(loc)
        
    }
    
    private func removeVisitedPoint(_ loc: LocPoint)
    {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        if (!savedVisitedPoints.isEmpty)
        {
            managedContext.delete(savedVisitedPoints.last!)
            savedVisitedPoints.removeLast()
        }
        if (!visitedPoints.isEmpty)
        {
            visitedPoints.removeLast()
        }
    }
    

    func clearPoints()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        for object in savedPoints + savedVisitedPoints{
            managedContext.delete(object)
        }
        
        savedPoints.removeAll()
        savedVisitedPoints.removeAll()
        isPlaying = false
        
    }
    
    func savePoints()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "PatternLocations",
                                                in: managedContext)!
        if (!savedPoints.isEmpty)
        {
            for (i, point) in pointsLoc.enumerated()
            {
                savedPoints[i].setValue(point.coordinate.latitude, forKeyPath: "lat")
                savedPoints[i].setValue(point.coordinate.longitude, forKeyPath: "long")
                savedPoints[i].setValue(point.visited, forKeyPath: "visited")
                savedPoints[i].setValue(i, forKeyPath: "index")
            }
            
        }
        else
        {
            for (i,point) in pointsLoc.enumerated()
            {
                let newPoint = NSManagedObject(entity: entity,
                                             insertInto: managedContext)
                
                newPoint.setValue(point.coordinate.latitude, forKeyPath: "lat")
                newPoint.setValue(point.coordinate.longitude, forKeyPath: "long")
                newPoint.setValue(point.visited, forKeyPath: "visited")
                newPoint.setValue(i, forKeyPath: "index")
                
                do {
                    try managedContext.save()
                    savedPoints.append(newPoint)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    // Location manager
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if (isPlaying)
        {
            let (_, nearestDist) = findNearestPoint(mapView, locations.last!)
            overlayView.updateDistance(nearestDist)
        }
        
        if (polyLineToPlayer != nil)
        {
            mapView.remove(polyLineToPlayer!)
        }
        
        if (!visitedPoints.isEmpty)
        {
            polyLineToPlayer = MKPolyline(coordinates: [visitedPoints.last!.coordinate,locations.last!.coordinate], count: 2)
            mapView.add(polyLineToPlayer!)
        }
    }


}

protocol MapOverlayViewDelegate {
    func controllButtPressed(_ overlayView :MapOverlayView)
}
