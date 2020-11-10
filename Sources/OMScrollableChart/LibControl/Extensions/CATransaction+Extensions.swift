//
//  CATransaction+Extensions.swift

//  Created by Jorge Ouahbi on 10/11/2020.
//

import UIKit


extension CATransaction {
    class func withDisabledActions<T>(_ body: () throws -> T) rethrows -> T {
        let actionsWereDisabled = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        defer {
            CATransaction.setDisableActions(actionsWereDisabled)
        }
        return try body()
    }
}


