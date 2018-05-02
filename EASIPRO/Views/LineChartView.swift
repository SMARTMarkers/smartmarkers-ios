//
//  LineChartView.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 5/2/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit

@IBDesignable public class LineChartView: UIView {
    
    @IBInspectable var lineColor : UIColor = .white
    @IBInspectable var startColor: UIColor = .black
    @IBInspectable var endColor: UIColor = .green
    
    private struct Const {
        static let margin : CGFloat = 2.0
        static let colorAlpha: CGFloat = 0.5
        static let maxSegmentWidth = 20.0
        static let xBuffer : CGFloat = 40.0
        static let rightMargin : CGFloat = 40.0
        static let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black,
                                 NSAttributedStringKey.font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.thin)]
        
    }
    
    public var showScore : Bool = true
    public var points : [Double]?
    var colors : [UIColor]?
    
    class func Gradient(for color: UIColor, colorSpace: CGColorSpace) -> CGGradient {
        let topColor = color.withAlphaComponent(0.4).cgColor
        let bottomColor = color.withAlphaComponent(0.1).cgColor
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: [topColor, bottomColor] as CFArray,
                                  locations: [0.0, 1.0])!
        return gradient
    }
    
    
    override public func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()!
        self.superview?.superview?.backgroundColor?.setFill()
        context.fill(rect)
        
        //points = [33.0, 44.0, 34.0, 64.3]
        colors = [UIColor.orange, UIColor.red, UIColor.red, UIColor.red, UIColor.red, UIColor.red, UIColor.red, UIColor.red]
        
        guard let points = self.points, points.count > 0 else {
            return
        }
        
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        
        
        
        
        
        let height = rect.height
        let width  = rect.width - Const.rightMargin
        let margin = Const.margin
        // X-Axis
        let spacing_x = (width - ((margin * 2))) / CGFloat(points.count)
        let xpointColumn = { (pointIndex: Int) -> CGFloat in
            return CGFloat(pointIndex) * spacing_x + (margin) + spacing_x
        }
        // Y-Axis
        let maxValue = points.max()!
        let ypointForColumn = { (point: Double) -> CGFloat in
            let y = CGFloat(point / maxValue) * (height - margin)
            return height - y
        }
        
        var graphPoints = [CGPoint]()
        
        lineColor.setFill()
        lineColor.setStroke()
        let linePath = UIBezierPath()
        linePath.lineWidth = 2.0
        var firstPoint = CGPoint(x: xpointColumn(0), y: ypointForColumn(points[0]))
        firstPoint.x -= spacing_x
        graphPoints.append(firstPoint)
        //        linePath.move(to: firstPoint)
        let dottedLine = UIBezierPath()
        dottedLine.lineWidth = 0.5
        dottedLine.move(to: firstPoint)
        
        
        for i in 0..<points.count {
            
            let point = CGPoint(x: xpointColumn(i), y: ypointForColumn(points[i]))
            graphPoints.append(point)
            if i == 0 {
                linePath.move(to: point)
                dottedLine.addLine(to: point)
            }
            else {
                linePath.addLine(to: point)
            }
        }
        
        
        
        
        context.saveGState()
        
        let clippingPath = linePath.copy() as! UIBezierPath
        clippingPath.addLine(to: CGPoint(x: xpointColumn(points.count-1), y: height))
        clippingPath.addLine(to: CGPoint(x: xpointColumn(0), y: height))
        clippingPath.close()
        
        clippingPath.addClip()
        
        
        let highestYPoint = ypointForColumn(maxValue)
        let startPoint = CGPoint(x:margin, y: highestYPoint)
        let endPoint = CGPoint(x:margin, y: bounds.height)
        
        
        context.restoreGState()
        
        
        //draw
        linePath.stroke()
        dottedLine.stroke()
        
        
        for p in graphPoints {
            if p == graphPoints.first! {
                continue
            }
            var point = p
            point.x -= 5.0/2
            point.y -= 5.0/2
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: point, size: CGSize(width: 5.0, height: 5.0)))
            circlePath.fill()
        }
        
        if showScore {
            let nstitle = String(points.last!) as NSString
            let lastPoint = graphPoints.last!
            nstitle.draw(at: CGPoint.init(x: lastPoint.x + 10, y: lastPoint.y) , withAttributes: Const.attributes)
        }
        
        
        
        context.resetClip()
        
        
        
        for i in 0..<graphPoints.count {
            
            if i == graphPoints.count-1 {
                break
            }
            
            
            
            
            context.resetClip()
            
            let p = graphPoints[i]
            let nextP = graphPoints[i+1]
            let baseP = CGPoint(x: nextP.x, y : height)
            let baseP2 = CGPoint(x: p.x, y: height)
            
            
            let barPath = UIBezierPath()
            barPath.move(to: p)
            barPath.addLine(to: nextP)
            barPath.addLine(to: baseP)
            barPath.addLine(to: baseP2)
            barPath.close()
            barPath.addClip()
            //            context.saveGState()
            var highestYP = (nextP.y < p.y) ? nextP : p
            highestYP.x = p.x
            print(nextP)
            print(p)
            
            let gd = LineChartView.Gradient(for: colors![i], colorSpace: colorSpace)
            context.drawLinearGradient(gd, start: highestYP, end: baseP2, options:CGGradientDrawingOptions(rawValue: 0))
        }
        
        
    }
    
    
}
