//
//  LapTableViewCell.swift
//  AwesomeStopwatch
//
//  Created by Sergey on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxSwift
import UIKit

final class LapTableViewCell: UITableViewCell {

    @IBOutlet private var lapNameLabel: UILabel!
    @IBOutlet private var lapDurationLabel: UILabel!

    func setup(with model: LapItem, durationConverter: DurationConverter) {
        lapNameLabel.text = model.name
        lapDurationLabel.text = durationConverter.string(from: model.duration)

        guard let startAt = model.starteAt else {
            return
        }

        let bag = DisposeBag()
        Observable<Int>.timer(.seconds(0), period: .milliseconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.lapDurationLabel.text = durationConverter.string(from: model.duration + CFAbsoluteTimeGetCurrent() - startAt)
            })
            .disposed(by: bag)

        disposeBag = bag
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = nil
    }

    // MARK: - Private
    var disposeBag: DisposeBag?
}
