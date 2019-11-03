//
//  StopwatchViewController.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

final class StopwatchViewController: UIViewController {

    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var leftButton: RoundButton!
    @IBOutlet private var rightButton: RoundButton!
    @IBOutlet private var lapsTableView: UITableView!

    // MARK: - Dependencies
    var viewModel: StopwatchViewModel!
    var durationConverter: DurationConverter!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        let actionsRelay = PublishRelay<Action>()

        let input = StopwatchViewModel.Input(actions: actionsRelay.asSignal())

        viewModel.setup(with: input)?
            .disposed(by: disposeBag)

        viewModel.leftButtonAction
            .drive(onNext: leftButton.setup)
            .disposed(by: disposeBag)

        viewModel.rightButtonAction
            .drive(onNext: rightButton.setup)
            .disposed(by: disposeBag)

        viewModel.timerState
            .flatMapLatest { state -> Driver<TimeInterval> in
                switch state {
                case let .running(startAt, duration):
                    return Driver<Int>.timer(.seconds(0), period: .milliseconds(10))
                        .map { _ in CFAbsoluteTimeGetCurrent() - startAt + duration }
                case let .stopped(duration):
                    return .just(duration)
                }
            }
            .map(durationConverter.string)
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)

        let leftAction = leftButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.leftButtonAction)

        let rightAction = rightButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.rightButtonAction)

        Observable.merge(leftAction, rightAction)
            .bind(to: actionsRelay)
            .disposed(by: disposeBag)

        viewModel.allLaps
            .drive(lapsTableView.rx.items(cellIdentifier: cellIdentifier)) { [converter = durationConverter!] _, model, cell in
                let lapCell = cell as! LapTableViewCell
                lapCell.setup(with: model, durationConverter: converter)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private
    private let cellIdentifier = "LapCell"
    private let disposeBag = DisposeBag()

    private func setupTableView() {
        let lineView = UIView()
        lineView.backgroundColor = lapsTableView.separatorColor
        lineView.bounds = CGRect(x: 0, y: 0, width: 0, height: 1.0 / UIScreen.main.scale)
        lapsTableView.tableHeaderView = lineView
        lapsTableView.separatorInset = .zero

        lapsTableView.register(UINib(nibName: "LapTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
}

private extension RoundButton {

    func setup(with event: Action) {
        let title: String
        let color: UIColor
        switch event {
        case .start:
            title = "Start"
            color = .green
        case .stop:
            title = "Stop"
            color = .red
        case .reset:
            title = "Reset"
            color = .lightGray
        case .lap:
            title = "Lap"
            color = .lightGray
        }

        UIView.performWithoutAnimation {
            setTitle(title, for: .normal)
            self.color = color
            layoutIfNeeded()
        }
    }
}
