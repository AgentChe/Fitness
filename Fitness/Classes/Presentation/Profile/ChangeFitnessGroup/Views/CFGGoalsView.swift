//
//  CFGGoalsView.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class CFGGoalsView: UIView {
    lazy var closeButton = makeCloseButton()
    lazy var titleLabel = makeTitleLabel()
    lazy var tableView = makeTableView()
    lazy var continueButton = makeContinueButton()
    lazy var preloader = makePreloader()
    
    private weak var vc: UIViewController?
    
    private lazy var disposeBag = DisposeBag()
    
    private lazy var activity = RxActivityIndicator()
    
    private lazy var drillManager = DrillManager()
    
    private lazy var observableRetrySingle = ObservableRetrySingle()
    
    private var fitnessGroup: FitnessGroup?
    private var profile: Profile?
    private let complete: ((FitnessGroup, Profile, [DrillCategory]) -> Void)
    
    init(
        vc: UIViewController?,
        complete: @escaping (FitnessGroup, Profile, [DrillCategory]) -> Void
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
extension CFGGoalsView {
    func setup(fitnessGroup: FitnessGroup, profile: Profile) {
        self.fitnessGroup = fitnessGroup
        self.profile = profile
        
        func source() -> Single<[DrillCategory]> {
            drillManager
                .obtainDrillCategories(group: fitnessGroup, forceUpdate: true, save: false)
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
            .drive(Binder(self) { base, drillCategories in
                let initialSelected = profile.drillsIds ?? []
                
                let elements = drillCategories.map { goal -> ODrillsTableElement in
                    ODrillsTableElement(
                        drillCategory: goal,
                        marked: initialSelected.contains(where: { $0 == goal.id })
                    )
                }
                base.tableView.setup(elements: elements)
                
                base.checkEnabled()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Private
private extension CFGGoalsView {
    func initialize() {
        backgroundColor = Appearance.main100
        
        activity
            .drive(Binder(self) { base, activity in
                base.continueButton.isHidden = activity
                activity ? base.preloader.startAnimating() : base.preloader.stopAnimating()
            })
            .disposed(by: disposeBag)
        
        tableView.didChangeSelected = { [weak self] in
            self?.checkEnabled()
        }
    }
    
    func checkEnabled() {
        let marked = tableView.elements.contains(where: { $0.marked })
        continueButton.isHidden = !marked
    }
    
    @objc
    func nextTapped() {
        guard let fitnessGroup, let profile else { return }
        
        let goals = tableView.elements
            .filter { $0.marked }
            .map { $0.drillCategory }
        
        complete(fitnessGroup, profile, goals)
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
private extension CFGGoalsView {
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
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2.scale),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
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
private extension CFGGoalsView {
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
        view.attributedText = "Onboarding.Drills.Title".localized.attributed(with: attrs)
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeTableView() -> ODrillsTableView {
        let view = ODrillsTableView()
        view.contentInset = UIEdgeInsets(top: 8.scale,
                                         left: 0,
                                         bottom: (ScreenSize.isIphoneXFamily ? 62.scale : 32.scale) + 66.scale,
                                         right: 0)
        view.setContentOffset(CGPoint(x: 0, y: 8.scale), animated: false)
        view.separatorStyle = .none
        view.showsVerticalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
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
