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

    struct Input {

    }

    func setup(with input: Input) -> Disposable? {

        let state = Observable.system(
            initialState: State.initial,
            reduce: reduce,
            scheduler: MainScheduler.instance,
            feedback: []
        )
        .share(replay: 1)

        return state.subscribe()
    }

    // MARK: - Private
    private func reduce(state: State, event: Event) -> State {
        return state
    }
}
