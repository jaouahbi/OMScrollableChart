//
//  UIScrollView+Extensions.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 11/02/2021.
//
    
import UIKit
    
extension UIScrollView {

    public func zoom(toPoint zoomPoint: CGPoint,
                     scale: CGFloat,
                     animated: Bool,
                     duration: TimeInterval = 1.1,
                     resetZoom: Bool = false)
    {
        var scale = CGFloat.minimum(scale, maximumZoomScale)
        scale = CGFloat.maximum(scale, self.minimumZoomScale)
            
        var translatedZoomPoint: CGPoint = .zero
        translatedZoomPoint.x = zoomPoint.x + contentOffset.x
        translatedZoomPoint.y = zoomPoint.y + contentOffset.y
            
        let zoomFactor = 1.0 / zoomScale
            
        translatedZoomPoint.x *= zoomFactor
        translatedZoomPoint.y *= zoomFactor
            
        var destinationRect: CGRect = .zero
        destinationRect.size.width = frame.width / scale
        destinationRect.size.height = frame.height / scale
        destinationRect.origin.x = translatedZoomPoint.x - destinationRect.size.width * 0.5
        destinationRect.origin.y = translatedZoomPoint.y - destinationRect.size.height * 0.5
            
        if animated {
            if let delegate = self.delegate,
               delegate.responds(to: #selector(UIScrollViewDelegate.scrollViewWillBeginZooming(_:with:))),
               let view = delegate.viewForZooming?(in: self)
            {
                delegate.scrollViewWillBeginZooming!(self, with: view)
            }
        }
            
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.6,
                       options: [.allowUserInteraction], animations: {
                           self.zoom(to: destinationRect, animated: false)
                       }, completion: { completed in
                           if let delegate = self.delegate,
                              delegate.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndZooming(_:with:atScale:))),
                              let view = delegate.viewForZooming?(in: self)
                           {
                               delegate.scrollViewDidEndZooming!(self, with: view, atScale: scale)
                               if completed, resetZoom {
                                if let delegate = self.delegate,
                                   delegate.responds(to: #selector(UIScrollViewDelegate.scrollViewDidEndZooming(_:with:atScale:))),
                                   let view = delegate.viewForZooming?(in: self)
                                {
                                    delegate.scrollViewDidEndZooming!(self, with: view, atScale: scale)
                                    if completed && resetZoom {
                                        UIView.animate(withDuration: duration * 0.5,
                                                       delay: 0.0,
                                                       usingSpringWithDamping: 7.2,
                                                       initialSpringVelocity: 0.6,
                                                       options: [.allowUserInteraction], animations: {
                                                           self.setZoomScale(1.0, animated: false)
                                                            
                                                       })
                                    }
                                }
                               }
                           }
                       })
    }
}
        
