//
//  DurationConverter.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Foundation

final class DurationConverter {

    func string(from duration: TimeInterval) -> String {
        return String(format: "%.2f", duration)
    }
}
