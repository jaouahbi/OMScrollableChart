import UIKit

class OMLayerPathRide: CALayer {
    
    // MARK: - Interface
    
    dynamic var rideProgress: Double = 0
    
    var rideLayer: CALayer? {
        get {
            return self.layerRide
        }
        set(newValue) {
            if let haveRideLayer = self.layerRide {
                if haveRideLayer.superlayer === self {
                    haveRideLayer.removeFromSuperlayer()
                }
            }
            self.layerRide = newValue
            if let haveRideLayer = newValue {
                self.updateRideLayerPosition(layer: haveRideLayer, progress: self.rideProgress, path: self.pathRide)
                self.addSublayer(haveRideLayer)
            }
        }
    }

    func setPathFrom(cgPath: CGPath?) {
        if let cgPathPresent = cgPath {
            self.pathRide = Path(cgPath: cgPathPresent)
        } else {
            self.pathRide = nil
        }
        if let haveRideLayer = self.layerRide {
            self.updateRideLayerPosition(layer: haveRideLayer,
                                         progress: self.rideProgress,
                                         path: self.pathRide)
        }
    }
    
    // MARK: - Inherited

    override init() {
        super.init()
        self.setNeedsDisplay()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        let rideLayer = (layer as! OMLayerPathRide)
        
        let animationsWereDisabled = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
            self.pathRide = rideLayer.pathRide
            self.rideProgress = rideLayer.rideProgress
        self.rideLayer = self.rideLayer?.presentation()
        CATransaction.setDisableActions(animationsWereDisabled)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "rideProgress" {
            return true
        } else {
            return super.needsDisplay(forKey: key)
        }
    }
    
    override func display() {
        if let haveRideLayer = self.layerRide {
            if let progressAvailable = self.presentation()?.rideProgress {
                self.updateRideLayerPosition(layer: haveRideLayer, progress: progressAvailable, path: self.pathRide)
            }
        }
        super.display()
    }

    // MARK: - Internal

   internal  var layerRide: CALayer? = nil
internal var pathRide: Path? = nil

    private func updateRideLayerPosition(layer: CALayer, progress: Double, path: Path?) {
        // TODO: add rotation
        
        let ridePosition: CGPoint
        if let havePath = path {
            let clippedProgress = min(1.0, max(0.0, progress))
            // TODO: optimize into iteration
            if let calculatedPoint = havePath.pointForPercentage(t: clippedProgress) {
                ridePosition = calculatedPoint
            } else {
                ridePosition = .zero
            }
        } else {
            ridePosition = .zero
        }

        let animationsWereDisabled = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
            layer.position = ridePosition
        CATransaction.setDisableActions(animationsWereDisabled)
    }
}
