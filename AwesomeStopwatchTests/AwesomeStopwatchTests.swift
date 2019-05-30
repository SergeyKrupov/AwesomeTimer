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
        let expectedState = State.running(runningState)
        stateHolder.state = expectedState

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

        // TODO: check obtainedLaps
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
