//
//  LineGraphView.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 24/04/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//


import UIKit



@IBDesignable public class LineGraphView: UIView {
	
	private struct Constants {
		static let cornerRadiusSize = CGSize(width: 10.0, height: 10.0)
		static let margin: 			CGFloat = 30.0
		static let topBorder: 		CGFloat = 70.0
		static let bottomBorder: 	CGFloat = 10
		static let colorAlpha: 		CGFloat = 0.3
		static let circleDiameter: 	CGFloat = 7.0
        static let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                 NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)]
	}
	@IBInspectable var startColor: 	UIColor = UIColor(red: 1, green:  0.493272, blue: 0.473998, alpha: 1)
	@IBInspectable var endColor: 	UIColor = UIColor(red: 1, green:  0.57810, blue: 0, alpha: 1)
	@IBInspectable var strokeColor: UIColor = .white
	
	public var thresholds : [Double] = []
	public var title : String?
    public var subtitle: String?
    
	public var graphPoints: [Double] = [] {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clear

	}
	
	required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
	
	
	
	override public func draw(_ rect: CGRect) {
		

		thresholds = [90,80,70,60,50,40,30,20,10]
		
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
            strokeColor.setFill()
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
            let gradient2 = CGGradient(colorsSpace: colorSpace,
                                       colors: [strokeColor.withAlphaComponent(0.5).cgColor, startColor.withAlphaComponent(0.3).cgColor, endColor.cgColor] as CFArray,
                                      locations: [0.0, 0.5, 1.0])!
			context.drawLinearGradient(gradient2, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
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
            (title as NSString).draw(at: CGPoint.init(x: Constants.margin, y: 10) , withAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                                                     NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)])
		}
        if let subtitle = subtitle {
            (subtitle as NSString).draw(at: CGPoint(x: Constants.margin, y: 35), withAttributes:
                [NSAttributedString.Key.foregroundColor: UIColor.lightText,
                 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        }
        
		

		
	}
}


@IBDesignable public class PROLineChart : UIView {
    
    @IBInspectable var startColor:     UIColor = UIColor(red: 1, green:  0.493272, blue: 0.473998, alpha: 1)
    @IBInspectable var endColor:     UIColor = UIColor(red: 1, green:  0.57810, blue: 0, alpha: 1)
    @IBInspectable var strokeColor: UIColor = .white
    @IBInspectable var bgLineColor : UIColor = .white
    private struct Constants {
        
        static let segmentRadius: CGFloat = 5.0
        static let interSegmentLength : CGFloat = 40.0
        static let margin:      CGFloat  = 20.0
        static let topBorder:   CGFloat  = 70.0
        static let cornerRadiusSize = CGSize(width: 10.0, height: 10.0)
        static let bottomBorder: CGFloat = 10.0
        static let circleDiameter:     CGFloat = 7.0
        static let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                 NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 7.0)]
        
        
    }
    public var title : String?
    public var subTitle: String?
    
    
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private let scrollView = UIScrollView()
    private let mainLayer  = CALayer()
    
    public var dataEntries: [Report]? = nil {
        didSet {
            addEntries()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        mainLayer.frame = scrollView.bounds
        scrollView.layer.addSublayer(mainLayer)
        self.addSubview(scrollView)
    }
    
    
    public var values : [Double]?  {
        didSet {
            addEntries()
        }
    }
    public var thresholds : [Double]? = [90.0, 80.0, 70.0 ,60.0 ,50.0 ,40.0 ,30.0 ,20.0, 10.0]
    
    public func addEntries() {

        mainLayer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        
        if let dataEntries = dataEntries {
            let count = dataEntries.count
            let contentSize = CGSize(width: (Constants.circleDiameter + Constants.interSegmentLength) * CGFloat(count), height: scrollView.frame.size.height)
            scrollView.contentSize = contentSize
            mainLayer.frame = CGRect(origin: .zero, size: contentSize)
            addEntry()
        }
        
        
        scrollView.scrollToBottom()
    }
    
    
    
    func addEntry() {
        
        let maxValue = thresholds?.max() ?? dataEntries!.filter { $0.rp_observation != nil }.map { Double($0.rp_observation!)! }.max()!
        let margins = Constants.bottomBorder + Constants.topBorder
        var prePos : CGPoint = .zero
        
        for i in 0..<dataEntries!.count {
            let xpoint = (Constants.interSegmentLength * CGFloat(i)) + Constants.interSegmentLength

            if let entry = dataEntries![i].rp_observation {
                let ypoint = CGFloat(Double(entry)!) / (CGFloat(maxValue))
                let newPoint = CGPoint(x: xpoint, y: translateHeightValueToYPosition(value: Float(ypoint)))
                let layer = lineLayers(prePos, newPoint)
                prePos = newPoint
                mainLayer.addSublayer(layer)
            }
            else {
                // Mark
                let layer = markLayer(x: xpoint)
                mainLayer.addSublayer(layer)
                
            }
        }
    }
    
    func markLayer(x: CGFloat) -> CALayer {
        
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: x, y: Constants.topBorder))
        linePath.addLine(to: CGPoint(x: x, y: mainLayer.frame.size.height - Constants.bottomBorder))
        let layer = CAShapeLayer()
        layer.path = linePath.cgPath
        layer.lineWidth = 1.0
        layer.strokeColor = UIColor.yellow.cgColor
        return layer
    }
    
    func lineLayers(_ from: CGPoint, _ to: CGPoint) -> CALayer {
        

        let layer = CAShapeLayer()
        var p = to
        p.x -= Constants.circleDiameter / 2
        p.y -= Constants.circleDiameter / 2
        let circleSize = CGSize(width: Constants.circleDiameter, height: Constants.circleDiameter)
        let dotlayer = CAShapeLayer()
        dotlayer.path = UIBezierPath(ovalIn: CGRect(origin: p, size: circleSize)).cgPath
        dotlayer.fillColor = strokeColor.cgColor
        layer.addSublayer(dotlayer)
        
        if from == .zero {
            return layer
        }
        else {
            let linePath = UIBezierPath()
            linePath.move(to: from)
            linePath.addLine(to: to)
            layer.path = linePath.cgPath
            layer.fillColor = nil
            layer.lineWidth = 2.0
            layer.opacity = 1.0
            layer.strokeColor = strokeColor.cgColor
        }
        
        return layer
        
    }
    
    private func drawVerticalLine() {
        
        
        
    }
    
    private func drawHorizontalLines() {
        self.layer.sublayers?.forEach({
            if $0 is CAShapeLayer {
                $0.removeFromSuperlayer()
            }
        })
        
        var lines = [[String:Any]]()
        if let thresholds = thresholds, let max = thresholds.max() {
            
            lines = thresholds.map { ["value": Float($0 / max),
                                      "mark" : Float($0),
                                      "dashed" : false] }
            
        }
            
        else
        {
            lines = [["value": Float(0.0), "dashed": false],
                     ["value": Float(0.5), "dashed": true],
                     ["value": Float(1.0), "dashed": false]]
        }
        
        let width = frame.size.width - Constants.margin
        let xPos  = Constants.margin
        for lineInfo in lines {
            let yPos = translateHeightValueToYPosition(value: (lineInfo["value"] as! Float))
            let path = UIBezierPath()
            path.move(to: CGPoint(x: xPos, y: yPos))
            path.addLine(to: CGPoint(x: width, y: yPos))
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.lineWidth = 0.2
            if lineInfo["dashed"] as! Bool {
                lineLayer.lineDashPattern = [4, 4]
            }
            lineLayer.strokeColor = strokeColor.cgColor
            if let mark = lineInfo["mark"] as? Float {
                let str = String(Int(mark)) as NSString
                str.draw(at: CGPoint(x: frame.size.width -  Constants.margin + 5, y: yPos - 4), withAttributes: Constants.attributes)
            }
            
            
            self.layer.insertSublayer(lineLayer, at: 0)
        }
    }
    private func translateHeightValueToYPosition(value: Float) -> CGFloat {

        let height: CGFloat =
            CGFloat(value) * (mainLayer.frame.height -  (Constants.bottomBorder + Constants.topBorder))
        return mainLayer.frame.height - (Constants.bottomBorder) - height
    }
    
    
    override public func draw(_ rect: CGRect) {
        


        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: .allCorners,
                                cornerRadii: Constants.cornerRadiusSize)
        
        path.addClip()
        let context = UIGraphicsGetCurrentContext()!
        let colors = [startColor.cgColor, endColor.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: colors as CFArray,
                                  locations: colorLocations)!
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x: 0, y: self.bounds.height)
        context.drawLinearGradient(gradient,
                                   start: startPoint,
                                   end: endPoint,
                                   options: CGGradientDrawingOptions(rawValue: 0))
        if let title = title  {
            (title as NSString).draw(at: CGPoint.init(x: Constants.margin, y: 10) , withAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                                                     NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)])
        }
        if let subtitle = subTitle {
            (subtitle as NSString).draw(at: CGPoint(x: Constants.margin, y: 35), withAttributes:
                [NSAttributedString.Key.foregroundColor: UIColor.lightText,
                 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        }
        scrollView.frame = CGRect(x: Constants.margin, y: 0, width: frame.size.width - (2 * Constants.margin), height: frame.size.height)
        mainLayer.frame = scrollView.bounds
        drawHorizontalLines()
        super.draw(rect)


    }
    
    
    
    
}

public struct LineEntry {
    
    let color: UIColor
    let textValue: String
    let title: String
    let value: Double
}


extension UIScrollView {
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: contentSize.width - bounds.size.width, y: contentSize.height - bounds.size.height)
        setContentOffset(bottomOffset, animated: true)
    }
}

