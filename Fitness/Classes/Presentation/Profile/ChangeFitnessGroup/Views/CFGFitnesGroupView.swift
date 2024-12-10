//
//  CFGFitnesGroupView.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class CFGFitnesGroupView: UIView {
    lazy var closeButton = makeCloseButton()
    lazy var titleLabel = makeTitleLabel()
    lazy var subTitleLabel = makeSubTitleLabel()
    lazy var scrollView = makeScrollView()
    lazy var calisthenicsButton = makeGroupButton(fitnessGroup: .calisthenics)
    lazy var chairYogaButton = makeGroupButton(fitnessGroup: .chairYoga)
    lazy var somaticButton = makeGroupButton(fitnessGroup: .somatic)
    lazy var stretchingButton = makeGroupButton(fitnessGroup: .stretching)
    lazy var wallPilatesButton = makeGroupButton(fitnessGroup: .wallPilates)
    lazy var continueButton = makeContinueButton()
    lazy var preloader = makePreloader()
    
    private weak var vc: UIViewController?
    
    private lazy var disposeBag = DisposeBag()
    
    private lazy var activity = RxActivityIndicator()
    
    private lazy var profileManager = ProfileManager()
    
    private lazy var groupsButtons = [
        calisthenicsButton,
        chairYogaButton,
        somaticButton,
        stretchingButton,
        wallPilatesButton
    ]
    
    private lazy var observableRetrySingle = ObservableRetrySingle()
    
    private let complete: ((FitnessGroup, Profile) -> Void)
    
    init(vc: UIViewController?, complete: @escaping (FitnessGroup, Profile) -> Void) {
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

// MARK: Private
private extension CFGFitnesGroupView {
    func initialize() {
        backgroundColor = Appearance.main100
        
        let currentGroup = FitnessGroup.current
        groupsButtons.forEach { $0.marked = $0.fitnessGroup == currentGroup }
        
        activity
            .drive(Binder(self) { base, activity in
                base.continueButton.isHidden = activity
                activity ? base.preloader.startAnimating() : base.preloader.stopAnimating()
            })
            .disposed(by: disposeBag)
        
        continueButton.rx.tap
            .flatMapLatest { [weak self] void -> Driver<(FitnessGroup, Profile)> in
                guard let self, let group = groupsButtons.first(where: { $0.marked })?.fitnessGroup else { return .never() }
                
                let newGroup = FitnessGroup.current != group
                return profile(group: group, forceUpdate: newGroup, save: newGroup)
                    .asDriver(onErrorDriveWith: .never())
                    .map { (group, $0) }
            }
            .asDriver(onErrorDriveWith: .never())
            .drive(Binder(self) { base, args in
                base.complete(args.0, args.1)
            })
            .disposed(by: disposeBag)
    }
    
    func profile(group: FitnessGroup, forceUpdate: Bool, save: Bool) -> Observable<Profile> {
        func source() -> Single<Profile> {
            profileManager
                .obtainProfile(group: group, forceUpdate: forceUpdate, save: save)
                .map {
                    $0 ?? Profile(
                        skillLevelId: nil,
                        gender: nil,
                        weekSchedule: nil,
                        drillsIds: nil,
                        focusZonesIds: nil
                    )
                }
        }
        
        func trigger(error: Error) -> Observable<Void> {
            open(error: error)
        }
        
        return observableRetrySingle
            .retry(
                source: { source() },
                trigger: { trigger(error: $0) }
            )
            .trackActivity(activity)
    }
    
    @objc
    func groupTapped(sender: UIButton) {
        guard let groupButton = sender as? OFitnessGroupButton else { return }
        
        groupsButtons.forEach { $0.marked = false }
        groupButton.marked = true
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
private extension CFGFitnesGroupView {
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
            subTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12.scale)
        ])
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.scale),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.scale),
            scrollView.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 2.scale),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -2.scale)
        ])
        
        NSLayoutConstraint.activate([
            calisthenicsButton.widthAnchor.constraint(equalToConstant: 343.scale),
            calisthenicsButton.heightAnchor.constraint(equalToConstant: 80.scale),
            calisthenicsButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            calisthenicsButton.topAnchor.constraint(equalTo: scrollView.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            chairYogaButton.widthAnchor.constraint(equalToConstant: 343.scale),
            chairYogaButton.heightAnchor.constraint(equalToConstant: 80.scale),
            chairYogaButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            chairYogaButton.topAnchor.constraint(equalTo: calisthenicsButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            somaticButton.widthAnchor.constraint(equalToConstant: 343.scale),
            somaticButton.heightAnchor.constraint(equalToConstant: 80.scale),
            somaticButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            somaticButton.topAnchor.constraint(equalTo: chairYogaButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            stretchingButton.widthAnchor.constraint(equalToConstant: 343.scale),
            stretchingButton.heightAnchor.constraint(equalToConstant: 80.scale),
            stretchingButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stretchingButton.topAnchor.constraint(equalTo: somaticButton.bottomAnchor, constant: 16.scale)
        ])
        
        NSLayoutConstraint.activate([
            wallPilatesButton.widthAnchor.constraint(equalToConstant: 343.scale),
            wallPilatesButton.heightAnchor.constraint(equalToConstant: 80.scale),
            wallPilatesButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            wallPilatesButton.topAnchor.constraint(equalTo: stretchingButton.bottomAnchor, constant: 16.scale),
            wallPilatesButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
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
private extension CFGFitnesGroupView {
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
        view.attributedText = "Onboarding.FitnessGroup.Title".localized.attributed(with: attrs)
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeSubTitleLabel() -> UILabel {
        let attrs = TextAttributes()
            .textColor(Appearance.mono100.withAlphaComponent(0.7))
            .font(Fonts.Inter.regular(size: 14.scale))
            .lineHeight(18.scale)
            .textAlignment(.center)
        
        let view = UILabel()
        view.attributedText = "Onboarding.FitnessGroup.SubTitle".localized.attributed(with: attrs)
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeScrollView() -> UIScrollView {
        let view = UIScrollView()
        view.contentInset = UIEdgeInsets(
            top: 30.scale,
            left: 0,
            bottom: 30.scale,
            right: 0
        )
        view.setContentOffset(CGPoint(x: 0, y: -30.scale), animated: false)
        view.backgroundColor = UIColor.clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeGroupButton(fitnessGroup: FitnessGroup) -> OFitnessGroupButton {
        let view = OFitnessGroupButton(fitnessGroup: fitnessGroup)
        view.backgroundColor = Appearance.main200
        view.layer.cornerRadius = 10.scale
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(groupTapped(sender:)), for: .touchUpInside)
        scrollView.addSubview(view)
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
