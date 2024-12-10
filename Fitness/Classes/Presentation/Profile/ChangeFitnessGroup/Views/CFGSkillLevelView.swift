//
//  CFGSkillLevelView.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class CFGSkillLevelView: UIView {
    lazy var closeButton = makeCloseButton()
    lazy var titleLabel = makeTitleLabel()
    lazy var slider = makeSlider()
    lazy var continueButton = makeContinueButton()
    lazy var preloader = makePreloader()
    
    private lazy var levelViews = [OSkillLevelScoreView]()
    
    private weak var vc: UIViewController?
    
    private lazy var disposeBag = DisposeBag()
    
    private lazy var activity = RxActivityIndicator()
    
    private lazy var contentManager = ContentManager()
    
    private lazy var observableRetrySingle = ObservableRetrySingle()
    
    private var fitnessGroup: FitnessGroup?
    private var profile: Profile?
    private let complete: ((FitnessGroup, Profile, SkillLevel) -> Void)
    
    init(
        vc: UIViewController?,
        complete: @escaping (FitnessGroup, Profile, SkillLevel) -> Void
    ) {
        self.vc = vc
        self.complete = complete
        
        super.init(frame: .zero)
        
        makeConstraints()
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Public
extension CFGSkillLevelView {
    func setup(fitnessGroup: FitnessGroup, profile: Profile) {
        self.fitnessGroup = fitnessGroup
        self.profile = profile
        
        func source() -> Single<[SkillLevel]> {
            contentManager
                .obtainLevels(group: fitnessGroup, forceUpdate: true, save: false)
        }
        
        func trigger(error: Error) -> Observable<Void> {
            open(error: error)
        }
        
        observableRetrySingle
            .retry(
                source: { source() },
                trigger: { trigger(error: $0) }
            )
            .trackActivity(activity)
            .asDriver(onErrorJustReturn: [])
            .drive(Binder(self) { base, levels in
                base.createLevelViews(at: levels)
                base.slider.maximumValue = Float(levels.count)
                if let index = base.levelViews.firstIndex(where: { $0.level.id == profile.skillLevelId }) {
                    base.slider.setValue(Float(index + 1), animated: true)
                    base.slider.sendActions(for: .valueChanged)
                }
                base.update(sender: base.slider)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Private
private extension CFGSkillLevelView {
    func initialize() {
        backgroundColor = Appearance.main100
        
        activity
            .drive(Binder(self) { base, activity in
                base.continueButton.isHidden = activity
                activity ? base.preloader.startAnimating() : base.preloader.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
    
    @objc
    func update(sender: UISlider) {
        let value = round(sender.value)
        sender.value = value
        
        levelViews.enumerated().forEach { index, levelView in
            let levelValue = Float(index + 1)
            
            levelView.marked = (value >= levelValue, value == levelValue)
        }
    }
    
    @objc
    func nextTapped() {
        guard let level = levelViews.last(where: { $0.marked.1 })?.level, let fitnessGroup, let profile else {
            return
        }
        
        complete(fitnessGroup, profile, level)
    }
    
    func createLevelViews(at levels: [SkillLevel]) {
        levelViews.forEach { $0.removeFromSuperview() }
        levelViews = []
        
        let padding = 8.scale
        let totalPadding = CGFloat(levels.count - 1) * padding
        let totalWidth = UIScreen.main.bounds.width - 132.scale - totalPadding
        
        let levelWidth = totalWidth / CGFloat(levels.count)
        
        var x = 66.scale
        var height = 121.scale
        
        levels.forEach { level in
            let view = OSkillLevelScoreView(level: level)
            view.layer.masksToBounds = false
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x),
                view.widthAnchor.constraint(equalToConstant: levelWidth),
                view.heightAnchor.constraint(equalToConstant: height),
                view.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -29.scale)
            ])
            
            x += levelWidth + padding
            height += 35.scale
            
            levelViews.append(view)
        }
    }
    
    func open(error: Error) -> Observable<Void> {
        Observable<Void>
            .create { [weak self] observe in
                guard let self = self else {
                    return Disposables.create()
                }
                
                let vc = TryAgainViewController.make(error: error) {
                    observe.onNext(())
                }
                self.vc?.present(vc, animated: true)
                
                return Disposables.create()
            }
    }
}

// MARK: Make constraints
private extension CFGSkillLevelView {
    func makeConstraints() {
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 24.scale),
            closeButton.heightAnchor.constraint(equalToConstant: 24.scale),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.scale),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: ScreenSize.isIphoneXFamily ? 120.scale : 52.scale),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 38.scale),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -38.scale),
            slider.heightAnchor.constraint(equalToConstant: 20.scale),
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ScreenSize.isIphoneXFamily ? 363.scale : 363.scale)
        ])
        
        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.scale),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.scale),
            continueButton.heightAnchor.constraint(equalToConstant: 54.scale),
            continueButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: ScreenSize.isIphoneXFamily ? -62.scale : -32.scale)
        ])
        
        NSLayoutConstraint.activate([
            preloader.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            preloader.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor)
        ])
    }
}

// MARK: Lazy initialization
private extension CFGSkillLevelView {
    func makeCloseButton() -> TapAreaButton {
        let view = TapAreaButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.setImage(UIImage(named: "Calendar.Close"), for: .normal)
        addSubview(view)
        return view
    }
    
    func makeTitleLabel() -> UILabel {
        let attrs = TextAttributes()
            .textColor(Appearance.mono100)
            .font(Fonts.Inter.bold(size: 24.scale))
            .lineHeight(28.8.scale)
            .textAlignment(.center)
        
        let view = UILabel()
        view.attributedText = "Onboarding.SkillLevel.Title".localized.attributed(with: attrs)
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeScoreView(level: SkillLevel) -> OSkillLevelScoreView {
        let view = OSkillLevelScoreView(level: level)
        view.backgroundColor = UIColor.clear
        view.layer.masksToBounds = false
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeSlider() -> UISlider {
        let view = UISlider()
        view.minimumValue = 1
        view.thumbTintColor = Appearance.main400
        view.maximumTrackTintColor = Appearance.main200
        view.minimumTrackTintColor = Appearance.main400
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(update(sender:)), for: .valueChanged)
        addSubview(view)
        return view
    }
    
    func makeContinueButton() -> UIButton {
        let attrs = TextAttributes()
            .textColor(Appearance.mono200)
            .font(Fonts.Inter.semiBold(size: 16.scale))
        
        let view = UIButton()
        view.backgroundColor = Appearance.main300
        view.layer.cornerRadius = 28.scale
        view.setAttributedTitle("Continue".localized.attributed(with: attrs), for: .normal)
        view.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makePreloader() -> Spinner {
        let view = Spinner(size: CGSize(width: 45.scale, height: 45.scale))
        view.stopAnimating()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
}
