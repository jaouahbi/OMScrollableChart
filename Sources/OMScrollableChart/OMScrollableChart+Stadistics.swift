// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

// Stadistics
public extension OMScrollableChart {
    func chunk( data: [Float],
                      size: CGSize,
                      groping: Int,
                      operation: ([Float]) -> Float) -> DataRender? {
        guard groping > 1 else { return nil }
        let chunked = data.chunked(into: groping)
        let output: [Float] = chunked.map { operation($0) }
        let points: [CGPoint] = DiscreteScaledPointsGenerator().makePoints(data: output, size: size)
        return DataRender( data: output, points: points)
    }
    func mean( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.mean()}
    }
    func meamg( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.meamg()}
    }
    func measq( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.measq()}
    }
    func rmsq( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.rmsq()}
    }
    func rmsqv( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.rmsqv()}
    }
    func sum( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.sum()}
    }
    func asum( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.asum()}
    }
    func svesq( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.svesq()}
    }
    func max( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.maxv()}
    }
    func min( data: [Float], size: CGSize, groping: Int) -> DataRender? {
        return chunk(data: data, size: size, groping: groping) {$0.minv()}
    }
    typealias StadisticProc = ([Float]) -> Float
    // split the data into groups of ´grouping´ and ´stdtstic´ erach group
    // create the points and return the points + meaned data
    func make( data: [Float],
               size: CGSize,
               grouping: CGFloat,
               function: StadisticProc) -> DataRender {
        assert(size != .zero)
        assert(!data.isEmpty)
        let chunked = data.chunked(into: Swift.max(1,Int(grouping))) // clap(min: 1, max: ...)
        guard !chunked.isEmpty else { return DataRender( data: data)}
        let meanData: [Float] = chunked.map{function($0)}
        let pts = DiscreteScaledPointsGenerator().makePoints(data: meanData, size: size)
        guard !pts.isEmpty else { return DataRender(data: meanData)}
        return DataRender( data: meanData,  points: pts)
    }
    
    // https://stackoverflow.com/questions/61879898/how-to-get-a-centerpoint-from-an-array-of-cgpoints
    func makeMeanPoints( data: [Float], size: CGSize, grouping: CGFloat) -> [CGPoint] {
        assert(size != .zero)
        assert(!data.isEmpty)
        assert(grouping > 0)
        var meanPoints: [CGPoint] = []
        let points = DiscreteScaledPointsGenerator().makePoints(data: data, size: size)
        guard grouping > 0 else {
            return points
        }
        let chunked = points.chunked(into: Swift.max(1,Int(grouping)))
        for item in chunked {
            meanPoints.append( item.mean() ?? .zero)
        }
        return meanPoints
    }
    func makeMeanCentroidPoints( data: [Float], size: CGSize, grouping: CGFloat) -> [CGPoint] {
        assert(size != .zero)
        assert(!data.isEmpty)
        let points = DiscreteScaledPointsGenerator().makePoints(data: data, size: size)
        guard grouping > 0 else {
            return points
        }
        let chunked = points.chunked(into: Swift.max(1,Int(grouping)))
        return chunked.map{($0.centroid() ?? .zero)}
    }
}
