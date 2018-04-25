//
//  LineGraphView.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 24/04/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//


import UIKit

@IBDesignable class LineGraphView: UIView {
	
	private struct Constants {
		static let cornerRadiusSize = CGSize(width: 10.0, height: 10.0)
		static let margin: 			CGFloat = 30.0
		static let topBorder: 		CGFloat = 60.0
		static let bottomBorder: 	CGFloat = 10
		static let colorAlpha: 		CGFloat = 0.3
		static let circleDiameter: 	CGFloat = 7.0
		static let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white,
								 NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 10)]
	}
	@IBInspectable var startColor: 	UIColor = UIColor(red: 1, green:  0.493272, blue: 0.473998, alpha: 1)
	@IBInspectable var endColor: 	UIColor = UIColor(red: 1, green:  0.57810, blue: 0, alpha: 1)
	@IBInspectable var strokeColor: UIColor = .white
	
	var thresholds : [Double] = []
	var title : String?
	var graphPoints: [Double] = [] {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clear

	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	
	
	override func draw(_ rect: CGRect) {
		

		thresholds = [90, 50, 10]
		
		let width = rect.width
		let height = rect.height
		
		UIColor.white.set()
		let path = UIBezierPath(roundedRect: rect,
								byRoundingCorners: UIRectCorner.allCorners,
								cornerRadii: Constants.cornerRadiusSize)
		path.addClip()

		
		let context = UIGraphicsGetCurrentContext()!
		let colors = [startColor.cgColor, endColor.cgColor]
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let colorLocations: [CGFloat] = [0.0, 1.0]
		let gradient = CGGradient(colorsSpace: colorSpace,
								  colors: colors as CFArray,
								  locations: colorLocations)!
		var startPoint = CGPoint.zero
		var endPoint = CGPoint(x: 0, y: self.bounds.height)
		context.drawLinearGradient(gradient,
								   start: startPoint,
								   end: endPoint,
								   options: CGGradientDrawingOptions(rawValue: 0))
		
		let margin = Constants.margin
		let columnXPoint = { (column:Int) -> CGFloat in
			let spacer = (width - margin * 2 - 4) / CGFloat((self.graphPoints.count))
			var x: CGFloat = CGFloat(column) * spacer
			x += margin + 2
			return x
		}
		
		let topBorder: CGFloat = Constants.topBorder
		let bottomBorder: CGFloat = Constants.bottomBorder
		let graphHeight = height - topBorder - bottomBorder
		let maxValue = thresholds.max()!
		let columnYPoint = { (graphPoint:Double) -> CGFloat in
			var y:CGFloat = CGFloat(graphPoint) / CGFloat(maxValue) * graphHeight
			y = graphHeight + topBorder - y
			return y
		}
		
		
		if graphPoints.count > 0 {
			strokeColor.setStroke()
			let graphPath = UIBezierPath()
			var _points = [CGPoint]()
			
			let firstPoint = CGPoint(x:columnXPoint(0), y:columnYPoint(graphPoints.first!))
			_points.append(firstPoint)
			graphPath.move(to:firstPoint)
			for i in 1..<graphPoints.count {
				let nextPoint = CGPoint(x:columnXPoint(i), y:columnYPoint(graphPoints[i]))
				_points.append(nextPoint)
				graphPath.addLine(to: nextPoint)
			}
			context.saveGState()
			let clippingPath = graphPath.copy() as! UIBezierPath
			clippingPath.addLine(to: CGPoint(x: columnXPoint(graphPoints.count - 1), y:height))
			clippingPath.addLine(to: CGPoint(x:columnXPoint(0), y:height))
			clippingPath.close()
			clippingPath.addClip()
			let highestYPoint = columnYPoint(maxValue)
			startPoint = CGPoint(x:margin, y: highestYPoint)
			endPoint = CGPoint(x:margin, y: bounds.height)
			context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
			context.restoreGState()
			graphPath.lineWidth = 2.0
			graphPath.stroke()
			
			strokeColor.setFill()
			for p in _points {
				var p = p
				p.x -= Constants.circleDiameter / 2
				p.y -= Constants.circleDiameter / 2
				let circle = UIBezierPath(ovalIn: CGRect(origin: p, size: CGSize(width: Constants.circleDiameter, height: Constants.circleDiameter)))
				circle.fill()
			}
		}
		
		
		
		
		
		
		let linePath = UIBezierPath()
		for yPoint in thresholds {
			let y = columnYPoint(yPoint)
			linePath.move(to: CGPoint(x: margin, y: y))
			linePath.addLine(to: CGPoint(x: width - margin, y: y))
			let str = String(Int(yPoint)) as NSString
			str.draw(at: CGPoint(x: width - margin + 4, y: y - 6), withAttributes: Constants.attributes)
		}
		let color = UIColor(white: 1.0, alpha: 0.5)
		color.setStroke()
		
		linePath.lineWidth = 1.0
		linePath.stroke()
		
		if let title = title  {
			(title as NSString).draw(at: CGPoint.init(x: Constants.margin, y: 10) , withAttributes: [NSAttributedStringKey.foregroundColor: UIColor.white,
																					 NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)])
		}
		

		
	}
}

