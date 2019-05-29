//
//  RunningState.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Foundation

struct RunningState: Codable, Equatable {
    let startAt: CFAbsoluteTime
    let currentLap: Lap
    let finishedLaps: [Lap]
}
