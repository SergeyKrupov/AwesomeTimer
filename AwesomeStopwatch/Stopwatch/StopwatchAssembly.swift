//
//  StopwatchAssembly.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import Swinject
import SwinjectStoryboard

final class StopwatchAssembly: Assembly {

    func assemble(container: Container) {
        container.register(StopwatchViewModel.self) { resolver -> StopwatchViewModel in
            return StopwatchViewModel()
        }

        container.storyboardInitCompleted(StopwatchViewController.self) { resolver, viewController in
            guard let viewModel = resolver.resolve(StopwatchViewModel.self) else {
                fatalError()
            }
            viewController.viewModel = viewModel
        }
    }
}
