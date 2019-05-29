//
//  StopwatchViewController.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

final class StopwatchViewController: UIViewController {

    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var leftButton: UIButton!
    @IBOutlet private var rightButton: UIButton!
    @IBOutlet private var lapsTableView: UITableView!

    // MARK: - Dependencies
    var viewModel: StopwatchViewModel!
    var durationConverter: DurationConverter!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let actionsRelay = PublishRelay<Event>()

        let input = StopwatchViewModel.Input(actions: actionsRelay.asSignal())

        viewModel.setup(with: input)?
            .disposed(by: disposeBag)

        viewModel.leftButtonAction
            .drive(onNext: { [button = leftButton!] event in
                button.setup(with: event)
            })
            .disposed(by: disposeBag)

        viewModel.rightButtonAction
            .drive(onNext: { [button = rightButton!] event in
                button.setup(with: event)
            })
            .disposed(by: disposeBag)

        viewModel.timerState
            .flatMapLatest { state -> Driver<TimeInterval> in
                switch state {
                case let .running(startAt, duration):
                    return Driver<Int>.timer(0, period: 0.01)
                        .map { _ in CFAbsoluteTimeGetCurrent() - startAt + duration }
                case let .stopped(duration):
                    return .just(duration)
                }
            }
            .map { [converter = durationConverter!] duration in converter.string(from: duration) }
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)

        let leftAction = leftButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.leftButtonAction)

        let rightAction = rightButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.rightButtonAction)

        Observable.merge(leftAction, rightAction)
            .bind(to: actionsRelay)
            .disposed(by: disposeBag)

        let identifier = "LapCell"
        lapsTableView.register(UINib.init(nibName: "LapTableViewCell", bundle: nil), forCellReuseIdentifier: identifier)
        viewModel.allLaps
            .drive(lapsTableView.rx.items(cellIdentifier: identifier)) { [converter = durationConverter!] index, model, cell in
                let lapCell = cell as! LapTableViewCell
                lapCell.setup(with: model, durationConverter: converter)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private
    private let disposeBag = DisposeBag()
}

private typealias Action = Event

private extension UIButton {

    func setup(with event: Action) {
        let title: String
        switch event {
        case .start:
            title = "Start"
        case .stop:
            title = "Stop"
        case .reset:
            title = "Reset"
        case .lap:
            title = "Lap"
        }

        setTitle(title, for: .normal)
    }
}
