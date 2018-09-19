//
//  DrawingView.swift
//  Artemis-plus-sample-app
//
//  Created by Carmelo Uria on 9/14/18.
//  Copyright © 2018 Yochay Tzur. All rights reserved.
//

import UIKit
import QuartzCore
import ARKit

protocol DrawingViewDelegate
{
    func willBeginDrawFreeformAtPoint(view: DrawingView, point: CGPoint)
    func didEndDrawFreeformAtPoint(view: DrawingView, point: CGPoint)
}

class UIColorBezierPath: UIBezierPath
{
    var lineColor: UIColor = UIColor.clear
    var lineAlpha: CGFloat = 0.0
    
}

class DrawingView: ARSCNView
{
    var lineColor: UIColor = UIColor.red
    var lineAlpha: CGFloat = 1.0
    var lineWidth: CGFloat = 1.0

    @IBOutlet open weak var drawingDelegate: AnyObject?
    
    fileprivate var previousPoint = CGPoint.zero
    fileprivate var currentPoint = CGPoint.zero
    
    fileprivate var path: UIColorBezierPath?
    
    fileprivate var paths: [UIColorBezierPath] = []
    fileprivate var buffer: [UIColorBezierPath] = []
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect)
    {
        // Drawing code
        for path  in paths
        {
            path.lineColor.setStroke()
            path.stroke(with: .normal, alpha: path.lineAlpha)
        }
    }

    // MARK: - Actions
    func clear()
    {
        buffer.removeAll()
        paths.removeAll()
        setNeedsDisplay()
    }
    
    func image() -> UIImage
    {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Undo / Redo
    
    func undoSteps() -> Int
    {
        return buffer.count
    }
    
    func canUndo() -> Bool
    {
        return paths.count > 0
    }
    
    func undoLastestStep()
    {
        if (canUndo() == true)
        {
            if let path: UIColorBezierPath = paths.last
            {
                buffer.append(path)
                paths.removeLast()
                setNeedsDisplay()
            }
        }
    }
    
    func canRedo() -> Bool
    {
        return buffer.count > 0
    }
    
    func redoLatestStep()
    {
        if (canRedo() == true)
        {
            if let path: UIColorBezierPath = paths.last
            {
                paths.append(path)
                buffer.removeLast()
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Touche movements
    func midPoint(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint
    {
            return (CGPoint(x: (point1.x + point2.x) * 0.5,y:(point1.y + point2.y) * 0.5))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let path: UIColorBezierPath = UIColorBezierPath()
        path.lineCapStyle = .round
        self.path = path
        
        path.lineWidth = lineWidth
        path.lineColor = lineColor
        
        path.lineAlpha = lineAlpha
        
        paths.append(path)
                    
        if let touch: UITouch = touches.first
        {
            currentPoint = touch.location(in: self)
            previousPoint = currentPoint
            self.path?.move(to: currentPoint)
                        
            if let delegate: DrawingViewDelegate = self.drawingDelegate as? DrawingViewDelegate
            {
                delegate.willBeginDrawFreeformAtPoint(view: self, point: currentPoint)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        /*
        if let touch: UITouch = touches.first
        {
            previousPoint = currentPoint
            currentPoint = touch.location(in: self)
            
            self.path?.addQuadCurve(to: midPoint(currentPoint, previousPoint), controlPoint: previousPoint)
            setNeedsDisplay()
        }
        */
        
        //1. Get The Current Touch Location
        guard let currentTouchPoint = touches.first?.location(in: self),
            //2. Perform An ARHitTest For Detected Feature Points
            let featurePointHitTest = self.hitTest(currentTouchPoint, types: .featurePoint).first else { return }
        
        //3. Get The World Coordinates
        let worldCoordinates = featurePointHitTest.worldTransform
        
        //4. Create An SCNNode With An SCNSphere Geeomtery
        let sphereNode = SCNNode()
        let sphereNodeGeometry = SCNSphere(radius: 0.002)
        
        //5. Generate A Random Colour For The Node's Geometry
        //let randomColour = colours[Int(arc4random_uniform(UInt32(colours.count)))]
        sphereNodeGeometry.firstMaterial?.diffuse.contents = UIColor.red
        sphereNode.geometry = sphereNodeGeometry
        
        //6. Position & Add It To The Scene Hierachy
        sphereNode.position = SCNVector3(worldCoordinates.columns.3.x,  worldCoordinates.columns.3.y,  worldCoordinates.columns.3.z)
        self.scene.rootNode.addChildNode(sphereNode)

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        buffer.removeAll()
        
        if let delegate: DrawingViewDelegate = self.drawingDelegate as? DrawingViewDelegate
        {
            delegate.didEndDrawFreeformAtPoint(view: self, point: currentPoint)
        }
    }
}
