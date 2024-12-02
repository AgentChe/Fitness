//
//  OFitnessGroupButton.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit

final class OFitnessGroupButton: UIButton {
    lazy var marked = false {
        didSet {
            update()
        }
    }
    
    lazy var label = makeLabel()
    
    let fitnessGroup: FitnessGroup
    
    init(fitnessGroup: FitnessGroup) {
        self.fitnessGroup = fitnessGroup
        
        super.init(frame: .zero)
        
        makeConstraints()
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Private
private extension OFitnessGroupButton {
    func update() {
        layer.borderColor = marked ? Appearance.main300.cgColor : UIColor.clear.cgColor
        layer.borderWidth = marked ? 1.scale : 0
    }
}

// MARK: Make constraints
private extension OFitnessGroupButton {
    func makeConstraints() {
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: Lazy initialization
private extension OFitnessGroupButton {
    func makeLabel() -> UILabel {
        let attrs = TextAttributes()
            .textColor(Appearance.mono100)
            .font(Fonts.PlusJakartaSans.regular(size: 16.scale))
            .lineHeight(25.6.scale)
            .textAlignment(.center)
        
        let view = UILabel()
        view.attributedText = fitnessGroup.localizedTitle.attributed(with: attrs)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
}

// MARK: Additional
private extension FitnessGroup {
    var localizedTitle: String {
        switch self {
        case .calisthenics:
            return "Onboarding.FitnessGroup.Calisthenics".localized
        case .chairYoga:
            return "Onboarding.FitnessGroup.ChairYoga".localized
        case .somatic:
            return "Onboarding.FitnessGroup.Somatic".localized
        case .stretching:
            return "Onboarding.FitnessGroup.Stretching".localized
        case .wallPilates:
            return "Onboarding.FitnessGroup.WallPilates".localized
        }
    }
}
