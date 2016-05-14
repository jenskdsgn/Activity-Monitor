//
//  ChartContainerUIView.swift
//  Monitoring Application
//
//  Created by Jens Klein on 24.02.16.
//  Copyright © 2016 Jens Klein. All rights reserved.
//

import UIKit
import SwiftChart

/// Custom UIView that holds one chart for a `ATSensor`
@IBDesignable class ChartContainerUIView: UIView {
    
    /// The `UIView` object that is used to hold the loaded View From the Nib
    var view: UIView!

    /// Appears at the top of the container, above the chart itself
    @IBOutlet weak var descriptionLabel: UILabel!
    
    /// Label for the y axis. Appears left of the chart rotated -90 degrees
    @IBOutlet weak var yLabel: UILabel!
    
    /// Label for the x axis. Appears below the chart
    @IBOutlet weak var xLabel: UILabel!
    
    /// The chart view that renders the sensor values into an diagram
    @IBOutlet weak var chartView: Chart!
    
    /// Reference to link a `ChartContainerView` object with a `ATSensor`
    var sensorCode : UInt8?        
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        viewSetup()        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
        viewSetup()
    }
    
    /// Sets up addtional programmatically action required to display the view correctly
    func viewSetup(){
        yLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
    }
    
    /// Manages the loading from the xib file
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    /**
    Loads the view from the nib
    - Returns: The `UIView` for this object
    */
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "ChartContainerUIView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }

}



extension Chart {   
    
    func setDataTuples( tuples: [(x: Double, y: Double)] ) {
        
        self.removeSeries()
        
        // map values from seconds to minutes
        let series = ChartSeries(data: tuples.map({ t in (t.x/60.0, t.y)}))
        series.area = true

        self.addSeries(series)
        
        setNeedsDisplay()
    }
    
    func setXLabel(xMaxSeconds: Double){
        let xMaxMinutes = xMaxSeconds / 60.0
        let xLabelMax = ceil(xMaxMinutes/10.0)*10.0
        
        var xLabelsArray = [Float]()
        for i in (0...10){
            xLabelsArray.append(Float(i) * Float(xLabelMax/10.0))
        }
        self.xLabels = xLabelsArray
    }
    

}






















