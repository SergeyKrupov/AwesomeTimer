//
//  LapItem.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Foundation

struct LapItem: Equatable {
    let name: String
    let duration: TimeInterval
    let starteAt: CFAbsoluteTime?
}
