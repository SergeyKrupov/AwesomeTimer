//
//  Lap.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Foundation

struct Lap {
    let duration: TimeInterval
}

extension Lap {

    func adding(duration additionalDuration: TimeInterval) -> Lap {
        return Lap(duration: duration + additionalDuration)
    }
}
