//
//  MapOverlayView.swift
//  OneLineToShine
//
//  Created by Štěpán Martinek on 07/11/2017.
//  Copyright © 2017 Štěpán Martinek. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

struct Line
{
    var begin = CGPoint.zero
    var end = CGPoint.zero
}

class MapOverlayView: UIView {

    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var controllButt: UIButton!
    
    var delegate: MapOverlayViewDelegate?
    weak var controller: MapViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit()
    {
        Bundle.main.loadNibNamed("MapOverlayView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        clearsContextBeforeDrawing = true
        
    }
    
    // Helper function to set button text based on game state
    public func updatePlayState()
    {
        controllButt.setTitle(controller!.isPlaying ? "Lock point" : "Start game", for: .normal)
    }
 
                          
    // Helper function to set distance label text based on real distance
    public func updateDistance(_ distance: Int)
    {
        if (distance < 0)
        {
            distanceLabel.text = "Distance: ???"
        }
        else
        {
            distanceLabel.text = "Distance: ~\(distance)m"
        }
    }
    
    // Invocation of controller delegate when lock button is clicked
    @IBAction func controllButtOnClick(_ sender: Any) {
        self.delegate?.controllButtPressed(self)
    }
    
    // Helper function to draw line on map overlay
    private func stroke(_ line: Line, lineWidth: CGFloat = 2)
    {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
        path.close()
    }
    
    override func draw(_ rect: CGRect)
    {
        // If we are playing or have no points there is no need to draw anything
        // In this view we are setting patter to real map
        if (controller!.isPlaying || controller!.points.isEmpty)
        {
            return
        }
        
        let temp = Double(min(contentView.frame.width, contentView.frame.height))
        let padding = temp * 0.05
        let side = temp * 0.9
        let startX = (Double(contentView.frame.width) - side) / 2.0
        let minX = Double(contentView.frame.minX)
        let minY = Double(contentView.frame.minY)
        
        UIColor.black.setStroke()
        
        var processed: [NeibPoint] = []
        
        // Draw lines between points
        for point in controller!.points {
            processed.append(point)
            for neib in point.neibours
            {
                // Dont draw line from A->B when we already drew it from B->A
                if (!processed.contains(where: { $0 === neib }))
                {
                    stroke(Line(begin: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y),
                                end: CGPoint(x: minX + startX + side * neib.x,y: minY + padding + side * neib.y)))
                }
            }
        }
        
        UIColor.blue.setStroke()
        
        // Draw points
        for point in controller!.points {
            stroke(Line(begin: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y),
                        end: CGPoint(x: minX + startX + side * point.x,y: minY + padding + side * point.y)), lineWidth:10)
        }

    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        let hitView = contentView.hitTest(point, with: event)
        if (hitView == controllButt)
        {
            return true
        }
        
        return false
    }

}
