//
//  DependenciesContainer.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 29/05/2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {

    @objc
    class func setup() {
        StopwatchAssembly().assemble(container: defaultContainer)
    }
}
