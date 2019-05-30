//
//  AwesomeStopwatchTests.swift
//  AwesomeStopwatchTests
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxCocoa
import RxSwift
import XCTest
@testable import AwesomeStopwatch

class AwesomeStopwatchTests: XCTestCase {

    var stateHolder: MockStateHolder!
    var viewModel: StopwatchViewModel!
    var actionsRelay: PublishRelay<Action>!
    var input: StopwatchViewModel.Input!

    let durationConverter = DurationConverter()

    override func setUp() {
        stateHolder = MockStateHolder()
        viewModel = StopwatchViewModel(durationConverter: durationConverter, stateHolder: stateHolder)
        actionsRelay = PublishRelay()
        input = StopwatchViewModel.Input(actions: actionsRelay.asSignal())
    }

    func testStateIsLoaded() {
        let runningState = RunningState(startAt: 100, currentLap: Lap(duration: 200), finishedLaps: [Lap(duration: 300)])
        stateHolder.state = State.running(runningState)

        let resultExpectation = expectation(description: "result")
        let disposeBag = DisposeBag()

        viewModel.setup(with: input)?.disposed(by: disposeBag)

        var obtainedLaps: [LapItem] = []
        viewModel.allLaps.debounce(0.1)
            .asObservable()
            .take(1)
            .subscribe(onNext: { laps in
                obtainedLaps.append(contentsOf: laps)
                resultExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [resultExpectation], timeout: 1)

        let expectedLaps = [
            LapItem(name: "Lap 2", duration: 200, starteAt: 100),
            LapItem(name: "Lap 1", duration: 300, starteAt: nil)
        ]

        XCTAssertEqual(expectedLaps, obtainedLaps)
    }

    func testStateIsSaved() {

        let resultExpectation = expectation(description: "result")
        let disposeBag = DisposeBag()

        viewModel.setup(with: input)?.disposed(by: disposeBag)

        viewModel.allLaps.debounce(0.1)
            .asObservable()
            .filter { !$0.isEmpty}
            .take(1)
            .subscribe(onNext: { laps in
                resultExpectation.fulfill()
            })
            .disposed(by: disposeBag)

        let now = CFAbsoluteTimeGetCurrent()
        actionsRelay.accept(.start)

        wait(for: [resultExpectation], timeout: 1)

        guard case let .running(runningState) = stateHolder.state else {
            XCTFail("Expected running state")
            return
        }

        XCTAssert(fabs(runningState.startAt - now) < 0.1)
        XCTAssertEqual(runningState.currentLap.duration, 0)
        XCTAssertEqual(runningState.finishedLaps, [])
    }

    func testStartRunning() {

        let disposeBag = DisposeBag()

        viewModel.setup(with: input)?.disposed(by: disposeBag)

        let stateExpectation = expectation(description: "Ожидание начала отсчёта")
        viewModel.timerState
            .asObservable()
            .debounce(0.1, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .take(1)
            .subscribe(onNext: { state in
                if case .running = state {
                    stateExpectation.fulfill()
                } else {
                    XCTFail("Некорректное состояние viewModel.timerState")
                }
            })
            .disposed(by: disposeBag)

        let leftButtonActionExpectation = expectation(description: "Ожидание изменения левой кнопки")
        viewModel.leftButtonAction
            .asObservable()
            .debounce(0.1, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .take(1)
            .subscribe(onNext: { action in
                if case .lap = action {
                    leftButtonActionExpectation.fulfill()
                } else {
                    XCTFail("Некорректное состояние viewModel.leftButtonAction")
                }
            })
            .disposed(by: disposeBag)

        let rightButtonActionExpectation = expectation(description: "Ожидание изменения правой кнопки")
        viewModel.rightButtonAction
            .asObservable()
            .debounce(0.1, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .take(1)
            .subscribe(onNext: { action in
                if case .stop = action {
                    rightButtonActionExpectation.fulfill()
                } else {
                    XCTFail("Некорректное состояние rightButtonAction")
                }
            })
            .disposed(by: disposeBag)

        actionsRelay.accept(.start)

        wait(for: [stateExpectation, leftButtonActionExpectation, rightButtonActionExpectation], timeout: 1)
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
