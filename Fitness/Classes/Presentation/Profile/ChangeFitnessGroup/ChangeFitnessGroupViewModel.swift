//
//  ChangeFitnessGroupViewModel.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import RxSwift
import RxCocoa

final class ChangeFitnessGroupViewModel {
    enum Route {
        case close
    }
    
    var tryAgain: ((Error) -> (Observable<Void>))?
    
    private lazy var activity = RxActivityIndicator()
    
    private lazy var profileManager = ProfileManager()
    private lazy var contentManager = ContentManager()
    private lazy var workoutManager = WorkoutManager()
    private lazy var drillManager = DrillManager()
    
    private lazy var observableRetrySingle = ObservableRetrySingle()
}

// MARK: Public
extension ChangeFitnessGroupViewModel {
    struct Input {
        let didCollectedFitnessGroup: Signal<FitnessGroup>
        let didCollectedSkillLevel: Signal<SkillLevel>
        let didCollectedWeekSchedule: Signal<WeekSchedule>
        let didCollectedGoals: Signal<[DrillCategory]>
        let didCollectedFocusZones: Signal<[FocusZone]>
        let didSaveProfile: Signal<Void>
        let didClose: Signal<Void>
    }
    
    struct Output {
        let activity: Driver<Bool>
        let route: Driver<Route>
    }
    
    func configure(input: Input) -> Output {
        Output(
            activity: activity.asDriver(),
            route: makeRoute(
                didSaveProfile: input.didSaveProfile,
                editableData: makeEditableData(
                    didCollectedFitnessGroup: input.didCollectedFitnessGroup,
                    didCollectedSkillLevel: input.didCollectedSkillLevel,
                    didCollectedWeekSchedule: input.didCollectedWeekSchedule,
                    didCollectedGoals: input.didCollectedGoals,
                    didCollectedFocusZones: input.didCollectedFocusZones
                ),
                didClose: input.didClose
            )
        )
    }
}

// MARK: Private
private extension ChangeFitnessGroupViewModel {
    struct EditableData {
        let fitnessGroup: FitnessGroup
        let skillLevel: SkillLevel
        let weekSchedule: WeekSchedule
        let goals: [DrillCategory]
        let focusZones: [FocusZone]
    }
    
    func makeRoute(
        didSaveProfile: Signal<Void>,
        editableData: Driver<EditableData>,
        didClose: Signal<Void>
    ) -> Driver<Route> {
        let save = didSaveProfile
            .withLatestFrom(editableData)
            .flatMapLatest { [weak self] editableData -> Driver<Route> in
                guard let self else { return .never() }
                
                func source() -> Single<Route> {
                    profileManager
                        .set(
                            group: editableData.fitnessGroup,
                            skillLevelId: editableData.skillLevel.id,
                            weekSchedule: editableData.weekSchedule,
                            drillsIds: editableData.goals.map { $0.id },
                            focusZonesIds: editableData.focusZones.map { $0.id }
                        )
                        .flatMap { [weak self] void -> Single<Void> in
                            guard let self else { return .never() }
                            
                            let drillCategories = drillManager
                                .obtainDrillCategories(group: editableData.fitnessGroup, forceUpdate: true)
                                .mapToVoid()
                            let levels = contentManager
                                .obtainLevels(group: editableData.fitnessGroup, forceUpdate: true)
                                .mapToVoid()
                            let focusZones = workoutManager
                                .obtainFocusZones(group: editableData.fitnessGroup, forceUpdate: true)
                                .mapToVoid()
                            let workoutSteps = workoutManager
                                .obtainWorkoutSteps(group: editableData.fitnessGroup, forceUpdate: true)
                                .mapToVoid()
                            let workoutCovers = workoutManager
                                .obtainWorkoutCovers(group: editableData.fitnessGroup, forceUpdate: true)
                                .mapToVoid()
                            
                            return Single
                                .zip([
                                    drillCategories,
                                    levels,
                                    focusZones,
                                    workoutSteps,
                                    workoutCovers
                                ])
                                .mapToVoid()
                        }
                        .do(onSuccess: {
                            FitnessGroup.current = editableData.fitnessGroup
                            FitnessGroupMediator.shared.updateAfterSetProfile()
                        })
                        .map { Route.close }
                }
                
                func trigger(error: Error) -> Observable<Void> {
                    guard let tryAgain = self.tryAgain?(error) else {
                        return .empty()
                    }
                    
                    return tryAgain
                }
                
                return self.observableRetrySingle
                    .retry(
                        source: source,
                        trigger: trigger
                    )
                    .trackActivity(activity)
                    .asDriver(onErrorDriveWith: .never())
            }
        
        let close = didClose
            .map { Route.close }
            .asDriver(onErrorDriveWith: .never())
        
        return Driver
            .merge(save, close)
    }
    
    func makeEditableData(
        didCollectedFitnessGroup: Signal<FitnessGroup>,
        didCollectedSkillLevel: Signal<SkillLevel>,
        didCollectedWeekSchedule: Signal<WeekSchedule>,
        didCollectedGoals: Signal<[DrillCategory]>,
        didCollectedFocusZones: Signal<[FocusZone]>
    ) -> Driver<EditableData> {
        Signal
            .combineLatest(
                didCollectedFitnessGroup,
                didCollectedSkillLevel,
                didCollectedWeekSchedule,
                didCollectedGoals,
                didCollectedFocusZones
            ) { fitnessGroup, skillLevel, weekSchedule, goals, focusZones -> EditableData in
                EditableData(
                    fitnessGroup: fitnessGroup,
                    skillLevel: skillLevel,
                    weekSchedule: weekSchedule,
                    goals: goals,
                    focusZones: focusZones
                )
            }
            .asDriver(onErrorDriveWith: .never())
    }
}
