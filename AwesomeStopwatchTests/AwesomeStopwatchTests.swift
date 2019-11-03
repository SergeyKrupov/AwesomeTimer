//
//  AwesomeStopwatchTests.swift
//  AwesomeStopwatchTests
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxCocoa
import RxSwift
import RxTest
import XCTest

@testable import AwesomeStopwatch

class AwesomeStopwatchTests: XCTestCase {

    var stateHolder: MockStateHolder!
    var scheduler: TestScheduler!
    var viewModel: StopwatchViewModel!

    let durationConverter = DurationConverter()

    override func setUp() {
        stateHolder = MockStateHolder()
        scheduler = TestScheduler(initialClock: 0, simulateProcessingDelay: false)
        viewModel = StopwatchViewModel(durationConverter: durationConverter, stateHolder: stateHolder, scheduler: scheduler)
    }

    // Проверка того, что состояние секундомера восстанавливается после запуска
    func testStateIsLoaded() {
        let input = StopwatchViewModel.Input(actions: .never())

        let runningState = RunningState(startAt: 100, currentLap: Lap(duration: 200), finishedLaps: [Lap(duration: 300)])
        stateHolder.state = .running(runningState)

        let disposeBag = DisposeBag()
        let observer = scheduler.start(created: 0, subscribed: 100, disposed: 1000) { [viewModel = viewModel!] () -> Observable<[LapItem]> in
            viewModel.setup(with: input)?.disposed(by: disposeBag)
            return viewModel.allLaps.asObservable()
        }

        let expectedLaps = [
            LapItem(name: "Lap 2", duration: 200, starteAt: 100),
            LapItem(name: "Lap 1", duration: 300, starteAt: nil)
        ]

        XCTAssertEqual(observer.events, [Recorded(time: 100, value: .next(expectedLaps))])
    }

    // Проверка того, что после изменения состояния, оно сохраняется
    func testStateIsSaved() {
        let actions: TestableObservable<Action> = scheduler.createColdObservable([
            Recorded(time: 200, value: .next(.start))
        ])

        let input = StopwatchViewModel.Input(actions: actions.asSignal(onErrorRecover: { _ in .never() }))

        let disposeBag = DisposeBag()
        viewModel.setup(with: input)?.disposed(by: disposeBag)
        scheduler.start()

        guard case let .running(state) = stateHolder.state else {
            XCTFail("Expected running state")
            return
        }

        XCTAssert(fabs(state.startAt - CFAbsoluteTimeGetCurrent()) < 0.1)
        XCTAssertEqual(state.currentLap.duration, 0)
        XCTAssertEqual(state.finishedLaps, [])
    }

    func testStartRunning() {
        let actions: TestableObservable<Action> = scheduler.createColdObservable([
            Recorded(time: 200, value: .next(.start))
        ])

        let input = StopwatchViewModel.Input(actions: actions.asSignal(onErrorRecover: { _ in .never() }))

        let disposeBag = DisposeBag()
        viewModel.setup(with: input)?.disposed(by: disposeBag)

        let timerStateObserver = scheduler.createObserver(StopwatchViewModel.TimerState.self)
        viewModel.timerState.asObservable()
            .subscribe(timerStateObserver)
            .disposed(by: disposeBag)


        let leftButtonObserver = scheduler.createObserver(Action.self)
        viewModel.leftButtonAction.asObservable()
            .subscribe(leftButtonObserver)
            .disposed(by: disposeBag)

        let rightButtonObserver = scheduler.createObserver(Action.self)
        viewModel.rightButtonAction.asObservable()
            .subscribe(rightButtonObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(timerStateObserver.events.count, 2)
        guard timerStateObserver.events.first?.time == 0, case let .next(value1) = timerStateObserver.events.first?.value, case .stopped = value1 else {
            XCTFail()
            return
        }

        guard timerStateObserver.events.last?.time == 200, case let .next(value2) = timerStateObserver.events.last?.value, case .running = value2 else {
            XCTFail()
            return
        }

        XCTAssertEqual(leftButtonObserver.events, [
            Recorded(time: 0, value: .next(.reset)),
            Recorded(time: 200, value: .next(.lap))
        ])

        XCTAssertEqual(rightButtonObserver.events, [
            Recorded(time: 0, value: .next(.start)),
            Recorded(time: 200, value: .next(.stop))
        ])
    }

}

final class MockStateHolder: StopwatchStateHolder {

    var state: State = .initial

    func obtain() -> State {
        return state
    }

    func store(_ state: State) {
        self.state = state
    }
}
