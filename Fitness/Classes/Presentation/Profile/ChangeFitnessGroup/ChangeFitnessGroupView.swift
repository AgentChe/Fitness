//
//  ChangeFitnessGroupView.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class ChangeFitnessGroupView: UIView {
    private lazy var views: [Step: UIView] = [
        .fitnessGroup: fitnessGroupView,
        .skillLevel: skillLevelView,
        .daysOfWeek: daysOfWeekView,
        .goals: goalsView,
        .focusZone: focusZonesView
    ]
    
    private lazy var fitnessGroupView = CFGFitnesGroupView(vc: vc) { [weak self] fitnessGroup, profile in
        self?.didCollectedFitnessGroupTrigger.accept(fitnessGroup)
        self?.skillLevelView.setup(fitnessGroup: fitnessGroup, profile: profile)
        self?.scroll(to: .skillLevel)
        
    }
    private lazy var skillLevelView = CFGSkillLevelView(vc: vc) { [weak self] fitnessGroup, profile, skillLevel in
        self?.didCollectedSkillLevelTrigger.accept(skillLevel)
        self?.daysOfWeekView.setup(fitnessGroup: fitnessGroup, profile: profile)
        self?.scroll(to: .daysOfWeek)
    }
    private lazy var daysOfWeekView = CFGDaysOfWeekView { [weak self] fitnessGroup, profile, weekSchedule in
        self?.didCollectedWeekScheduleTrigger.accept(weekSchedule)
        self?.goalsView.setup(fitnessGroup: fitnessGroup, profile: profile)
        self?.scroll(to: .goals)
    }
    private lazy var goalsView = CFGGoalsView(vc: vc) { [weak self] fitnessGroup, profile, goals in
        self?.didCollectedGoalsTrigger.accept(goals)
        self?.focusZonesView.setup(fitnessGroup: fitnessGroup, profile: profile)
        self?.scroll(to: .focusZone)
    }
    private lazy var focusZonesView = CFGFocusZoneView(vc: vc) { [weak self] fitnessGroup, profile, focusZones in
        self?.didCollectedFocusZonesTrigger.accept(focusZones)
        self?.didCompleteTrigger.accept(Void())
    }
    
    private lazy var didCollectedFitnessGroupTrigger = PublishRelay<FitnessGroup>()
    private lazy var didCollectedSkillLevelTrigger = PublishRelay<SkillLevel>()
    private lazy var didCollectedWeekScheduleTrigger = PublishRelay<WeekSchedule>()
    private lazy var didCollectedGoalsTrigger = PublishRelay<[DrillCategory]>()
    private lazy var didCollectedFocusZonesTrigger = PublishRelay<[FocusZone]>()
    private lazy var didCompleteTrigger = PublishRelay<Void>()
    
    private weak var vc: UIViewController?
    
    private var currentStep = Step.fitnessGroup
    
    init(vc: UIViewController) {
        self.vc = vc
        
        super.init(frame: .zero)
        
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        views.forEach { step, view in
            view.frame.size = bounds.size
        }
    }
}

// MARK: Public
extension ChangeFitnessGroupView {
    var didCollectedFitnessGroup: Signal<FitnessGroup> {
        didCollectedFitnessGroupTrigger.asSignal()
    }
    
    var didCollectedSkillLevel: Signal<SkillLevel> {
        didCollectedSkillLevelTrigger.asSignal()
    }
    
    var didCollectedWeekSchedule: Signal<WeekSchedule> {
        didCollectedWeekScheduleTrigger.asSignal()
    }
    
    var didCollectedGoals: Signal<[DrillCategory]> {
        didCollectedGoalsTrigger.asSignal()
    }
    
    var didCollectedFocusZones: Signal<[FocusZone]> {
        didCollectedFocusZonesTrigger.asSignal()
    }
    
    var didComplete: Signal<Void> {
        didCompleteTrigger.asSignal()
    }
    
    var didClose: Signal<Void> {
        Signal<Void>.merge(
            fitnessGroupView.closeButton.rx.tap.asSignal(),
            skillLevelView.closeButton.rx.tap.asSignal(),
            daysOfWeekView.closeButton.rx.tap.asSignal(),
            goalsView.closeButton.rx.tap.asSignal(),
            focusZonesView.closeButton.rx.tap.asSignal()
        )
    }
}

// MARK: Private
private extension ChangeFitnessGroupView {
    enum Step: Int {
        case fitnessGroup
        case skillLevel
        case daysOfWeek
        case goals
        case focusZone
    }
    
    func initialize() {
        backgroundColor = Appearance.main100
        
        views
            .forEach { [weak self] step, view in
                guard let self else { return }
                
                view.clipsToBounds = true
                
                if step == self.currentStep {
                    addSubview(view)
                }
            }
    }
    
    func scroll(to newStep: Step) {
        let currentIndex = currentStep.rawValue
        let scrollToIndex = newStep.rawValue
        
        guard scrollToIndex != currentIndex else {
            return
        }
        
        let direction = scrollToIndex > currentIndex ? 1 : -1
        
        guard
            let currentView = views[currentStep],
            let scrollToView = views[newStep]
        else {
            return
        }
        
        scrollToView.frame.size = bounds.size
        scrollToView.frame.origin = CGPoint(x: bounds.width * CGFloat(direction), y: 0)
        
        addSubview(scrollToView)
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self else { return }
            
            currentView.frame.origin = CGPoint(x: bounds.width * CGFloat(-direction), y: 0)
            scrollToView.frame.origin = CGPoint(x: 0, y: 0)
        }, completion: { [weak self] result in
            guard let self = self else { return }
            
            currentView.removeFromSuperview()
            
            self.currentStep = newStep
        })
    }
}
