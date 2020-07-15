//
//  LevelSelectorViewController.swift
//  OneLineToShine
//
//  Created by Stepan Martinek on 22/11/2017.
//  Copyright © 2017 Štěpán Martinek. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class LevelSelectorViewController: UICollectionViewController {

    var patterns: [DrawPattern] = []
    var gameState: NSManagedObject? = nil
    var savedPoints: [NSManagedObject] = []
    var savedVisitedPoints: [NSManagedObject] = []
    
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return patterns.count
    }
/*
    private func stroke(_ line: Line, lineWidth: CGFloat = 2) -> UIBezierPath
    {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.move(to: line.begin)
        path.addLine(to: line.end)
        
        return path
    }
    
    private func drawShape(_ contentView:UIView) -> UIBezierPath
    {
        
        var combinedPath = UIBezierPath();
        let temp = Double(min(contentView.frame.width, contentView.frame.height))
        let padding = temp * 0.05
        let side = temp * 0.9
        let startX = (Double(contentView.frame.width) - side) / 2.0
        let minX = Double(contentView.frame.minX)
        let minY = Double(contentView.frame.minY)
        
        UIColor.black.setStroke()
        
        var processed: [NeibPoint] = []
        
        for point in points {
            processed.append(point)
            for neib in point.neibours
            {
                if (!processed.contains(where: { $0 === neib }))
                {
                    combinedPath.append(stroke(Line(begin: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y),
                                                                  end: CGPoint(x: minX + startX + side * neib.x,y: minY + padding + side * neib.y))));
                    
                }
            }
        }
        
        UIColor.blue.setStroke()
        
        for point in points {
            combinedPath.append(stroke(Line(begin: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y),
                        end: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y)), lineWidth:10))
        }
        
        return combinedPath
    }
    */
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
       
        // Configure the cell
        // Use the outlet in our custom class to get a reference to the UILabel in the cell

        cell.myLabel.text = patterns[indexPath.item].name
        cell.myLabel.textAlignment = NSTextAlignment.center;
        cell.backgroundColor = UIColor.cyan // make cell more visible in our example project
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        
//https://stackoverflow.com/questions/33309000/draw-a-semi-circle-button-ios
        //https://stackoverflow.com/questions/42091599/how-to-create-a-multiple-path-from-several-bezierpath
        return cell
    }
    
    // change background color when user touches cell
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.red
    }
    
    // change background color back when user releases touch
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.cyan
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        gameState?.setValue(indexPath.item, forKey: "currentPattern")
        gameState?.setValue(indexPath.item, forKey: "nextPattern")
        gameState?.setValue(false, forKey: "isPlaying")
        let mapViewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        mapViewController.patterns = patterns
        mapViewController.gameState = gameState
        mapViewController.savedVisitedPoints = savedVisitedPoints
        mapViewController.savedPoints = savedPoints
        self.navigationController?.pushViewController(mapViewController, animated: true)
    }
}
