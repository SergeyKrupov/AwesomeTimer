//
//  StopwatchViewController.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import RxSwift
import UIKit

final class StopwatchViewController: UIViewController {

    var viewModel: StopwatchViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let input = StopwatchViewModel.Input()

        viewModel.setup(with: input)?
            .disposed(by: disposeBag)
    }

    // MARK: - Private
    private let disposeBag = DisposeBag()
}
