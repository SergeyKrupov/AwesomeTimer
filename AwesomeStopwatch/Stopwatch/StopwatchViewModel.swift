//
//  StopwatchViewModel.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxSwift
import RxCocoa
import RxFeedback

final class StopwatchViewModel {

    enum TimerState {
        case running(startAt: CFAbsoluteTime, duration: TimeInterval)
        case stopped(duration: TimeInterval)
    }

    struct Input {
        let actions: Signal<Event>
    }

    struct LapItem {
        let name: String
        let duration: TimeInterval
    }

    func setup(with input: Input) -> Disposable? {

        let bindUI: (ObservableSchedulerContext<State>) -> Observable<Event> = bind(self) { this, state in
            return Bindings(subscriptions: [], mutations: [input.actions])
        }

        let state = Observable.system(
            initialState: State.initial,
            reduce: reduce,
            scheduler: MainScheduler.instance,
            scheduledFeedback: [bindUI]
        )
        .share(replay: 1)

        leftButtonAction = state
            .map { state -> Event in
                switch state {
                case .initial, .paused:
                    return .reset
                case .running:
                    return .lap
                }
            }
            .asDriver(onErrorJustReturn: .reset)

        rightButtonAction = state
            .map { state -> Event in
                switch state {
                case .initial, .paused:
                    return .start
                case .running:
                    return .stop
                }
            }
            .asDriver(onErrorJustReturn: .start)

        timerState = state
            .map { state -> TimerState in
                switch state {
                case .initial:
                    return .stopped(duration: 0)
                case let .running(runningState):
                    return .running(startAt: runningState.startAt, duration: runningState.currentLap.duration)
                case let .paused(pausedState):
                    return .stopped(duration: pausedState.currentLap.duration)
                }
            }
            .asDriver(onErrorJustReturn: .stopped(duration: 0))

        let lapNameFormat = "Lap %d"
        currentLap = state
            .map { state -> LapItem? in
                switch state {
                case .initial:
                    return nil
                case let .running(runningState):
                    return LapItem(
                        name: String(format: lapNameFormat, runningState.finishedLaps.count + 1),
                        duration: runningState.currentLap.duration + CFAbsoluteTimeGetCurrent() - runningState.startAt
                    )
                case let .paused(pausedState):
                    return LapItem(
                        name: String(format: lapNameFormat, pausedState.finishedLaps.count + 1),
                        duration: pausedState.currentLap.duration
                    )
                }
            }
            .asDriver(onErrorJustReturn: nil)

        finishedLaps = state
            .map { state -> [LapItem] in
                let laps: [Lap]
                switch state {
                case .initial:
                    return []
                case let .running(runningState):
                    laps = runningState.finishedLaps
                case let .paused(pausedState):
                    laps = pausedState.finishedLaps
                }

                return laps.enumerated().map {
                    LapItem(
                        name: String(format: lapNameFormat, laps.count - $0.offset),
                        duration: $0.element.duration
                    )
                }
            }
            .asDriver(onErrorJustReturn: [])

        return state.subscribe()
    }

    // MARK: - Public
    private(set) var leftButtonAction: Driver<Event>!
    private(set) var rightButtonAction: Driver<Event>!
    private(set) var timerState: Driver<TimerState>!
    private(set) var currentLap: Driver<LapItem?>!
    private(set) var finishedLaps: Driver<[LapItem]>!

    // MARK: - Private
    private func reduce(state: State, event: Event) -> State {

        let now = CFAbsoluteTimeGetCurrent()

        switch (state, event) {
        case (.initial, .start):
            let runningState = RunningState(
                startAt: CFAbsoluteTimeGetCurrent(),
                currentLap: Lap(duration: 0),
                finishedLaps: []
            )
            return .running(runningState)

        case (.initial, .reset):
            return .initial

        case let (.running(runningState), .stop):
            let pausedState = PausedState(
                currentLap: runningState.currentLap.adding(duration: now - runningState.startAt),
                finishedLaps: runningState.finishedLaps
            )
            return .paused(pausedState)

        case let (.running(runningState), .lap):
            let runningState = RunningState(
                startAt: now,
                currentLap: Lap(duration: 0),
                finishedLaps: [runningState.currentLap.adding(duration: now - runningState.startAt)] + runningState.finishedLaps
            )
            return .running(runningState)

        case let (.paused(pausedState), .start):
            let runningState = RunningState(
                startAt: now,
                currentLap: pausedState.currentLap,
                finishedLaps: pausedState.finishedLaps
            )
            return .running(runningState)

        case (.paused, .reset):
            return .initial

        default:
            assertionFailure("Unhandled event")
            return state
        }
    }
}
