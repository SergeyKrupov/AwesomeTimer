//
//  State.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

enum State {
    case initial
    case running(RunningState)
    case paused(PausedState)
}

extension State: Equatable {

    static func == (lhs: State, rhs: State) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case let (.running(lhsValue), .running(rhsValue)):
            return lhsValue == rhsValue
        case let (.paused(lhsValue), .paused(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

extension State: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let type = try container.decode(StateType.self, forKey: .type)

        switch type {
        case .initial:
            self = .initial
        case .running:
            self = .running(try container.decode(RunningState.self, forKey: .value))
        case .paused:
            self = .paused(try container.decode(PausedState.self, forKey: .value))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .initial:
            try container.encode(StateType.initial, forKey: .type)
        case let .running(value):
            try container.encode(StateType.running, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .paused(value):
            try container.encode(StateType.paused, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    private enum Key: CodingKey {
        case type
        case value
    }

    private enum StateType: String, Codable {
        case initial
        case running
        case paused
    }

}
