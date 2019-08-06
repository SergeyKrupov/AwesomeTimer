//
//  StopwatchViewModel.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxCocoa
import RxFeedback
import RxSwift

final class StopwatchViewModel {

    enum TimerState {
        case running(startAt: CFAbsoluteTime, duration: TimeInterval)
        case stopped(duration: TimeInterval)
    }

    struct Input {
        let actions: Signal<Action>
    }

    init(durationConverter: DurationConverter, stateHolder: StopwatchStateHolder) {
        self.durationConverter = durationConverter
        self.stateHolder = stateHolder
    }

    func setup(with input: Input) -> Disposable? {

        let bindUI: (ObservableSchedulerContext<State>) -> Observable<Action> = bind(self) { _, _ in
            return Bindings(subscriptions: [], events: [input.actions])
        }

        let state = Observable.system(
            initialState: stateHolder.obtain(),
            reduce: reduce,
            scheduler: SerialDispatchQueueScheduler(qos: .default),
            feedback: [bindUI]
        )
        .share(replay: 1)

        leftButtonAction = makeLeftButtonAction(state)
        rightButtonAction = makeRightButtonAction(state)
        timerState = makeTimerState(state)
        allLaps = makeLaps(state)

        return state.distinctUntilChanged()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [holder = stateHolder] state in
                holder.store(state)
            })
    }

    // MARK: - Public
    private(set) var leftButtonAction: Driver<Action>!
    private(set) var rightButtonAction: Driver<Action>!
    private(set) var timerState: Driver<TimerState>!
    private(set) var allLaps: Driver<[LapItem]>!

    // MARK: - Private
    private let durationConverter: DurationConverter
    private let stateHolder: StopwatchStateHolder

    private func makeLeftButtonAction(_ state: Observable<State>) -> Driver<Action> {
        return state
            .map { state -> Action in
                switch state {
                case .initial, .paused:
                    return .reset
                case .running:
                    return .lap
                }
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .reset)
    }

    private func makeRightButtonAction(_ state: Observable<State>) -> Driver<Action> {
        return state
            .map { state -> Action in
                switch state {
                case .initial, .paused:
                    return .start
                case .running:
                    return .stop
                }
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .start)
    }

    private func makeTimerState(_ state: Observable<State>) -> Driver<TimerState> {
        return state
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
    }

    private func makeLaps(_ state: Observable<State>) -> Driver<[LapItem]> {
        let lapNameFormat = "Lap %d"
        return state
            .map { state -> (finishedLaps: [Lap], currentLap: Lap?, startAt: CFAbsoluteTime?) in
                switch state {
                case .initial:
                    return ([], nil, nil)
                case let .running(runningState):
                    return (runningState.finishedLaps, runningState.currentLap, runningState.startAt)
                case let .paused(pausedState):
                    return (pausedState.finishedLaps, pausedState.currentLap, nil)
                }
            }
            .map { tuple -> [LapItem] in
                let count = tuple.finishedLaps.count + (tuple.currentLap == nil ? 0 : 1)

                let finishedItems = tuple.finishedLaps.enumerated().map {
                    LapItem(
                        name: String(format: lapNameFormat, count - $0.offset - (tuple.currentLap == nil ? 0 : 1)),
                        duration: $0.element.duration,
                        starteAt: nil
                    )
                }

                guard let currentLap = tuple.currentLap else {
                    return finishedItems
                }

                let currentItem = LapItem(
                    name: String(format: lapNameFormat, count),
                    duration: currentLap.duration,
                    starteAt: tuple.startAt
                )

                return [currentItem] + finishedItems
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
    }

    private func reduce(state: State, action: Action) -> State {

        let now = CFAbsoluteTimeGetCurrent()

        switch (state, action) {
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
