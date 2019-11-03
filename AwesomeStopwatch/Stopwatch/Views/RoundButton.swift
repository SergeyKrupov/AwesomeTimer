//
//  RoundButton.swift
//  AwesomeStopwatch
//
//  Created by Sergey V. Krupov on 03.11.2019.
//  Copyright © 2019 Sergey V. Krupov. All rights reserved.
//

import UIKit

final class RoundButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    var color: UIColor = .red {
        didSet {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            _ = withUnsafeMutablePointer(to: &red) { redPointer in
                withUnsafeMutablePointer(to: &green) { greenPointer in
                    withUnsafeMutablePointer(to: &blue) { bluePointer in
                        withUnsafeMutablePointer(to: &alpha) { alphaPointer in
                            color.getRed(redPointer, green: greenPointer, blue: bluePointer, alpha: alphaPointer)
                        }
                    }
                }
            }

            backgroundColor = .init(red: red, green: green, blue: blue, alpha: 0.4)
            setTitleColor(color, for: .normal)
            layer.borderColor = color.cgColor
            layer.borderWidth = 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = min(bounds.width, bounds.height) / 2.0
        layer.cornerRadius = radius
    }

    // MARK: - Private
    private func setup() {
        clipsToBounds = true
        color = .systemGreen
    }
}
