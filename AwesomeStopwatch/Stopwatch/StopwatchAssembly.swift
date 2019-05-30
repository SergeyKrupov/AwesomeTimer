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
        container.register(DurationConverter.self) { _ -> DurationConverter in
            return DurationConverter()
        }
        .inObjectScope(.container)

        container.register(StopwatchStateHolder.self) { _ -> StopwatchStateHolder in
            return StopwatchStateHolderImpl()
        }

        container.register(StopwatchViewModel.self) { resolver -> StopwatchViewModel in
            return StopwatchViewModel(
                durationConverter: resolver.resolve(DurationConverter.self)!,
                stateHolder: resolver.resolve(StopwatchStateHolder.self)!
            )
        }

        container.storyboardInitCompleted(StopwatchViewController.self) { resolver, viewController in
            viewController.viewModel = resolver.resolve(StopwatchViewModel.self)!
            viewController.durationConverter = resolver.resolve(DurationConverter.self)!
        }
    }
}
