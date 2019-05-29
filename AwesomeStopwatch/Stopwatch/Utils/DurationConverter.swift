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
        let minutes = Int(duration / 60)
        let seconds = Int(duration - Double(minutes) * 60)
        let fraction = Int(duration * 100) % 100

        return String(format: "%02d:%02d,%02d", minutes, seconds, fraction)
    }
}
