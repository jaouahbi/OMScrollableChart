//
//  OMScrollableChart+Regression.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 11/02/2021.
//

import UIKit

// Regression
extension OMScrollableChart {
    
    func makeLinregressPoints(data: DataRender, size: CGSize, numberOfElements: Int, renderIndex: Int) -> DataRender {
        let originalDataIndex: [Float] = data.points.enumerated().map { Float($0.offset) }
        //        let max = originalData.points.max(by: { $0.x < $1.x})!
        //        let distance = mean(originalDataX.enumerated().compactMap{
        //            if $0.offset > 0 {
        //                return originalDataX[$0.offset-1].distance(to: $0.element)
        //            }
        //            return nil
        //        })
        
        
        // let results = originalDataX//.enumerated().map{ return originalDataX.prefix($0.offset+1).reduce(.zero, +)}
        
        linFunction = Array.linregress(originalDataIndex, data.data)
        
        // var index = 0
        let result: [Float] = [Float].init(repeating: 0, count: numberOfElements)
        
        let resulLinregress = result.enumerated().map{ linregressDataForIndex(index: Float($0.offset))}
        //        for item in result  {
        //            result[index] = dataForIndex(index:  Float(index))
        //            index += 1
        //        }
        //
        // add the new points
        let newData = data.data + resulLinregress
        let newPoints = DiscreteScaledPointsGenerator().makePoints(data: newData, size: size)
        return DataRender( data: newData, points: newPoints)
    }
    func linregressDataForIndex(index: Float) -> Float {
        guard let linFunction = linFunction else { return 0 }
        return linFunction.slope * index + linFunction.intercept
    }
}
