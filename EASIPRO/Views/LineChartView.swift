//
//  LineChartView.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 5/2/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit

@IBDesignable public class LineChartView: UIView {
    
    private struct Const {
        static let margin : CGFloat = 2.0
        static let colorAlpha: CGFloat = 0.5
        static let maxSegmentWidth = 20.0
        static let xBuffer : CGFloat = 40.0
        static let rightMargin : CGFloat = 40.0
        static let attributes = [NSAttributedStringKey.foregroundColor: UIColor.black,
                                 NSAttributedStringKey.font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.thin)]
    }
    
    
    @IBInspectable var lineColor : UIColor = .white
    @IBInspectable var startColor: UIColor = .black
    @IBInspectable var endColor: UIColor = .green
	@IBInspectable var severeSegmentColor: UIColor = UIColor(red:0.96, green:0.98, blue:0.85, alpha:1.0)
	@IBInspectable var mildSegmentColor: UIColor = UIColor(red:0.95, green:0.76, blue:0.59, alpha:1.0)
	@IBInspectable var moderateSegmentColor: UIColor = UIColor(red:0.98, green:0.92, blue:0.86, alpha:1.0)
	@IBInspectable var normalSegmentColor: UIColor = UIColor(red:0.85, green:0.89, blue:0.75, alpha:1.0)
	
    public var showScore : Bool = true
	
	public var grayScale : Bool = false
    
    public var highIsNormal : Bool = false
    
	public var points : [Double]? {
		didSet {
			setNeedsDisplay()
		}
	}
    public var thresholds : [Double]? //= [55,60,70]
    // 55,60,70
	public var thresholdIndicators : [UIColor]?
	
    class func Gradient(for color: UIColor, colorSpace: CGColorSpace) -> CGGradient {
		return CGGradient(colorsSpace: colorSpace,
						  colors: [color.withAlphaComponent(0.6).cgColor, //0.5
								   color.withAlphaComponent(0.2).cgColor, //0.2
								   color.withAlphaComponent(0.0).cgColor] as CFArray, //0.02
						  locations: [0.0, 0.4, 1.0])!
    }
    
    public func setThresholds(_ _thresholds: [Double]? = nil, highNormal : Bool = false, _grayScale : Bool = false) {
        highIsNormal = highNormal
        thresholds = _thresholds
        grayScale  = _grayScale
    }
    
	
	func segmentColor(_ reading: Double) -> UIColor {
        
        if highIsNormal {
            for (i, v) in thresholds!.enumerated() {
                if reading >= v {
                    return thresholdIndicators![i]
                }
            }
            return thresholdIndicators!.last!
        }
        else {
            for (i, v) in thresholds!.enumerated() {
                if reading <= v {
                    return thresholdIndicators![i]
                }
            }
            return thresholdIndicators!.last!
        }
	}
    
    
    override public func draw(_ rect: CGRect) {
		
		if grayScale || thresholds == nil {
		thresholdIndicators = [UIColor.white,
							   UIColor.gray,
							   UIColor.darkGray,
							   UIColor.black]
		}
		else {
		
				thresholdIndicators =
					[normalSegmentColor,
				mildSegmentColor,
				moderateSegmentColor,
				severeSegmentColor]
		}
        
        let context = UIGraphicsGetCurrentContext()!
		backgroundColor?.setFill()
        context.fill(rect)
		
		// todo: set colors
		
        guard let points = self.points, points.count > 0 else {
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let height = rect.height
        let width  = (showScore) ? rect.width - Const.rightMargin : rect.width
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
		
		if thresholds == nil { return }
        
		
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
      
            
			
			let segmentColor = self.segmentColor(points[i])
            let gd = LineChartView.Gradient(for:segmentColor, colorSpace: colorSpace)
            context.drawLinearGradient(gd, start: highestYP, end: baseP2, options:CGGradientDrawingOptions(rawValue: 0))
        }

        
        
    }
    
    
}
