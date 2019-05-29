//
//  StopwatchStateHolder.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Foundation

protocol StopwatchStateHolder {

    func obtain() -> State
    func store(_ state: State)
}

final class StopwatchStateHolderImpl: StopwatchStateHolder {

    func obtain() -> State {
        guard let data = UserDefaults.standard.data(forKey: key),
            let state = try? JSONDecoder().decode(State.self, from: data) else {
                return .initial
        }
        return state
    }

    func store(_ state: State) {
        let data = try? JSONEncoder().encode(state)
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Private
    let key = "stopwatch-state"

}
