//
//  CFGFocusZoneView.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class CFGFocusZoneView: UIView {
    lazy var closeButton = makeCloseButton()
    lazy var titleLabel = makeTitleLabel()
    lazy var imageView = makeImageView()
    lazy var armsButton = makeFocusZoneButton(name: "Onboarding.FocusZone.Arms".localized)
    lazy var chestButton = makeFocusZoneButton(name: "Onboarding.FocusZone.Chest".localized)
    lazy var coreButton = makeFocusZoneButton(name: "Onboarding.FocusZone.Core".localized)
    lazy var glutesButton = makeFocusZoneButton(name: "Onboarding.FocusZone.Glutes".localized)
    lazy var legsButton = makeFocusZoneButton(name: "Onboarding.FocusZone.Legs".localized)
    lazy var continueButton = makeContinueButton()
    lazy var preloader = makePreloader()
    
    private lazy var buttons = [
        armsButton,
        chestButton,
        coreButton,
        glutesButton,
        legsButton
    ]
    
    private weak var vc: UIViewController?
    
    private lazy var disposeBag = DisposeBag()
    
    private lazy var activity = RxActivityIndicator()
    
    private lazy var workoutManager = WorkoutManager()
    
    private lazy var observableRetrySingle = ObservableRetrySingle()
    
    private var fitnessGroup: FitnessGroup?
    private var profile: Profile?
    private var focusZones: [FocusZone] = []
    private let complete: ((FitnessGroup, Profile, [FocusZone]) -> Void)
    
    init(
        vc: UIViewController?,
        complete: @escaping (FitnessGroup, Profile, [FocusZone]) -> Void
    ) {
        self.vc = vc
        self.complete = complete
        
        super.init(frame: .zero)
        
        makeConstraints()
        initialize()
        checkEnabled()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Public
extension CFGFocusZoneView {
    func setup(fitnessGroup: FitnessGroup, profile: Profile) {
        self.fitnessGroup = fitnessGroup
        self.profile = profile
        
        updateImage(profile: profile)
        
        func source() -> Single<[FocusZone]> {
            workoutManager
                .obtainFocusZones(group: fitnessGroup, forceUpdate: true, save: false)
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
            .drive(Binder(self) { base, focusZones in
                base.focusZones = focusZones
                
                let currentZonesIds = profile.focusZonesIds ?? []
                let currentZones = focusZones.filter { currentZonesIds.contains($0.id) }
                
                currentZones.forEach { focusZone in
                    if let button = base.buttons.first(where: { $0.name == focusZone.name }) {
                        button.sendActions(for: .touchUpInside)
                    }
                }
                
                base.checkEnabled()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Private
private extension CFGFocusZoneView {
    func initialize() {
        backgroundColor = Appearance.main100
        
        activity
            .drive(Binder(self) { base, activity in
                base.continueButton.isHidden = activity
                activity ? base.preloader.startAnimating() : base.preloader.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
    
    func updateImage(profile: Profile) {
        let image: UIImage?
        switch profile.gender {
        case .female:
            image = UIImage(named: ScreenSize.isIphoneXFamily ? "Onboarding.FocusZone.Female.X" : "Onboarding.FocusZone.Female.8")
        case .male:
            image = UIImage(named: ScreenSize.isIphoneXFamily ? "Onboarding.FocusZone.Male.X" : "Onboarding.FocusZone.Male.8")
        case .none:
            image = nil
        }
        imageView.image = image
    }
    
    @objc
    func focusZoneTapped(sender: UIButton) {
        guard let focusZoneButton = sender as? OFocusZoneButton else {
            return
        }
        
        focusZoneButton.marked.toggle()
        
        checkEnabled()
    }
    
    func checkEnabled() {
        let marked = buttons.contains(where: { $0.marked })
        continueButton.isHidden = !marked
    }
    
    @objc
    func nextTapped() {
        guard let fitnessGroup, let profile else { return }
        
        let selectedNames = buttons
            .filter { $0.marked }
            .map { $0.name }
        let selectedZones = focusZones
            .filter { selectedNames.contains($0.name) }
        
        complete(fitnessGroup, profile, selectedZones)
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
private extension CFGFocusZoneView {
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
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: ScreenSize.isIphoneXFamily ? 535.scale : 453.scale)
        ])
        
        NSLayoutConstraint.activate([
            armsButton.widthAnchor.constraint(equalToConstant: 152.scale),
            armsButton.heightAnchor.constraint(equalToConstant: 69.scale),
            armsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24.scale),
            armsButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ScreenSize.isIphoneXFamily ? 61.scale : 24.scale)
        ])
        
        NSLayoutConstraint.activate([
            chestButton.widthAnchor.constraint(equalToConstant: 152.scale),
            chestButton.heightAnchor.constraint(equalToConstant: 69.scale),
            chestButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24.scale),
            chestButton.topAnchor.constraint(equalTo: armsButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            coreButton.widthAnchor.constraint(equalToConstant: 152.scale),
            coreButton.heightAnchor.constraint(equalToConstant: 69.scale),
            coreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24.scale),
            coreButton.topAnchor.constraint(equalTo: chestButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            glutesButton.widthAnchor.constraint(equalToConstant: 152.scale),
            glutesButton.heightAnchor.constraint(equalToConstant: 69.scale),
            glutesButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24.scale),
            glutesButton.topAnchor.constraint(equalTo: coreButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            legsButton.widthAnchor.constraint(equalToConstant: 152.scale),
            legsButton.heightAnchor.constraint(equalToConstant: 69.scale),
            legsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24.scale),
            legsButton.topAnchor.constraint(equalTo: glutesButton.bottomAnchor, constant: 16.scale)
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
private extension CFGFocusZoneView {
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
        view.attributedText = "Onboarding.FocusZone.Title".localized.attributed(with: attrs)
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeImageView() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeFocusZoneButton(name: String) -> OFocusZoneButton {
        let view = OFocusZoneButton(name: name)
        view.layer.cornerRadius = 10.scale
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(focusZoneTapped(sender:)), for: .touchUpInside)
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
