//
//  WorkoutManager.swift
//  Soccer
//
//  Created by Андрей Чернышев on 01.03.2023.
//

import RxSwift

protocol WorkoutManagerProtocol {
    func obtainFocusZones(group: FitnessGroup, forceUpdate: Bool, save: Bool) -> Single<[FocusZone]>
    func obtainWorkoutSteps(group: FitnessGroup, forceUpdate: Bool, save: Bool) -> Single<[WorkoutStep]>
    func obtainWorkoutCovers(group: FitnessGroup, forceUpdate: Bool, save: Bool) -> Single<[WorkoutCover]>
    func obtainWorkoutTemplate(coverId: Int, levelId: Int) -> Single<WorkoutTemplate?>
    func obtainWorkoutTemplate(focusZoneId: Int, levelId: Int) -> Single<WorkoutTemplate?>
    func obtainWorkoutTemplate(stepId: Int, levelId: Int) -> Single<WorkoutTemplate?>
    func assignWorkout(id: Int) -> Single<AssignedWorkout?>
    func scheduleWorkout(id: Int, scheduleDate: TimeInterval) -> Single<AssignedWorkout?>
    func obtainWorkoutTraining(customerWorkoutId: Int) -> Single<WorkoutTraining?>
    func logProgress(customerWorkoutId: Int, exerciseId: Int, trainedTime: Int, finish: Bool) -> Single<AssignedWorkout?>
}

final class WorkoutManager {
    enum Constants {
        static let focusZones = "workout_manager_focus_zones_key"
        static let workoutSteps = "workout_manager_workout_steps_key"
        static let workoutCovers = "workout_manager_workout_covers_key"
    }
    
    private lazy var defaultRequestWrapper = DefaultRequestWrapper()
    
    private lazy var sessionManager = SessionManager()
}

// MARK: WorkoutManagerProtocol
extension WorkoutManager: WorkoutManagerProtocol {
    func obtainFocusZones(group: FitnessGroup = FitnessGroup.current, forceUpdate: Bool, save: Bool = true) -> Single<[FocusZone]> {
        forceUpdate ? loadFocusZones(group: group, save: save) : cachedFocusZones(group: group)
    }

    func obtainWorkoutSteps(group: FitnessGroup = FitnessGroup.current, forceUpdate: Bool, save: Bool = true) -> Single<[WorkoutStep]> {
        forceUpdate ? loadWorkoutSteps(group: group, save: save) : cachedWorkoutSteps(group: group)
    }

    func obtainWorkoutCovers(group: FitnessGroup = FitnessGroup.current, forceUpdate: Bool, save: Bool = true) -> Single<[WorkoutCover]> {
        forceUpdate ? loadWorkoutCovers(group: group, save: save) : cachedWorkoutCovers(group: group)
    }
    
    func obtainWorkoutTemplate(coverId: Int, levelId: Int) -> Single<WorkoutTemplate?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutTemplateRequest(
            userToken: userToken,
            workoutCoverId: coverId,
            focusZoneId: nil,
            workoutStepId: nil,
            levelId: levelId
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutTemplateResponse.map(from: $0) }
    }
    
    func obtainWorkoutTemplate(focusZoneId: Int, levelId: Int) -> Single<WorkoutTemplate?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutTemplateRequest(
            userToken: userToken,
            workoutCoverId: nil,
            focusZoneId: focusZoneId,
            workoutStepId: nil,
            levelId: levelId
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutTemplateResponse.map(from: $0) }
    }
    
    func obtainWorkoutTemplate(stepId: Int, levelId: Int) -> Single<WorkoutTemplate?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutTemplateRequest(
            userToken: userToken,
            workoutCoverId: nil,
            focusZoneId: nil,
            workoutStepId: stepId,
            levelId: levelId
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutTemplateResponse.map(from: $0) }
    }
    
    func assignWorkout(id: Int) -> Single<AssignedWorkout?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = AssignWorkoutRequest(
            userToken: userToken,
            workoutId: id
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { AssignWorkoutResponse.map(from: $0) }
            .do(onSuccess: { assignedWorkout in
                guard let assignedWorkout = assignedWorkout else {
                    return
                }
                
                WorkoutMediator.shared.didAssign(assignedWorkout)
            })
    }
    
    func scheduleWorkout(id: Int, scheduleDate: TimeInterval) -> Single<AssignedWorkout?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = ScheduleWorkoutRequest(
            userToken: userToken,
            customerWorkoutId: id,
            scheduleDate: scheduleDate
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map {  ScheduleWorkoutResponse.map(from: $0)}
            .do(onSuccess: { assignedWorkout in
                guard let assignedWorkout = assignedWorkout else {
                    return
                }
                
                WorkoutMediator.shared.didSchedule(assignedWorkout)
            })
    }
    
    func obtainWorkoutTraining(customerWorkoutId: Int) -> Single<WorkoutTraining?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutTrainingRequest(
            userToken: userToken,
            customerWorkoutId: customerWorkoutId
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutTrainingResponse.map(from: $0) }
    }
    
    func logProgress(customerWorkoutId: Int, exerciseId: Int, trainedTime: Int, finish: Bool) -> Single<AssignedWorkout?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = LogWorkoutProgressRequest(
            userToken: userToken,
            customerWorkoutId: customerWorkoutId,
            exerciseId: exerciseId,
            trainedTime: trainedTime,
            finish: finish
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { LogWorkoutProgressResponse.map(from: $0) }
            .do(onSuccess: { assignedWorkout in
                guard let assignedWorkout = assignedWorkout else {
                    return
                }
                
                WorkoutMediator.shared.didLogProgress(assignedWorkout)
            })
    }
}

// MARK: Private
private extension WorkoutManager {
    func loadFocusZones(group: FitnessGroup, save: Bool) -> Single<[FocusZone]> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetFocusZonesRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetFocusZonesResponse.map(from: $0) }
            .do(onSuccess: { focusZones in
                guard save, let data = try? JSONEncoder().encode(focusZones) else {
                    return
                }

                UserDefaults.standard.set(data, forKey: Self.key(Constants.focusZones, group: group))
            })
    }

    func cachedFocusZones(group: FitnessGroup) -> Single<[FocusZone]> {
        Single<[FocusZone]>.create { event in
            guard let data = UserDefaults.standard.data(forKey: Self.key(Constants.focusZones, group: group)) else {
                event(.success([]))
                return Disposables.create()
            }
            
            let focusZones = try? JSONDecoder().decode([FocusZone].self, from: data)
            
            event(.success(focusZones ?? []))
            
            return Disposables.create()
        }
    }
    
    func loadWorkoutSteps(group: FitnessGroup, save: Bool) -> Single<[WorkoutStep]> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutStepsRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutStepsResponse.map(from: $0) }
            .do(onSuccess: { workoutSteps in
                guard save, let data = try? JSONEncoder().encode(workoutSteps) else {
                    return
                }

                UserDefaults.standard.set(data, forKey: Self.key(Constants.workoutSteps, group: group))
            })
    }

    func cachedWorkoutSteps(group: FitnessGroup) -> Single<[WorkoutStep]> {
        Single<[WorkoutStep]>.create { event in
            guard let data = UserDefaults.standard.data(forKey: Self.key(Constants.workoutSteps, group: group)) else {
                event(.success([]))
                return Disposables.create()
            }
            
            let workoutSteps = try? JSONDecoder().decode([WorkoutStep].self, from: data)
            
            event(.success(workoutSteps ?? []))
            
            return Disposables.create()
        }
    }
    
    func loadWorkoutCovers(group: FitnessGroup, save: Bool) -> Single<[WorkoutCover]> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetWorkoutCoversRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetWorkoutCoversResponse.map(from: $0) }
            .do(onSuccess: { workoutCovers in
                guard save, let data = try? JSONEncoder().encode(workoutCovers) else {
                    return
                }

                UserDefaults.standard.set(data, forKey: Self.key(Constants.workoutCovers, group: group))
            })
    }

    func cachedWorkoutCovers(group: FitnessGroup) -> Single<[WorkoutCover]> {
        Single<[WorkoutCover]>.create { event in
            guard let data = UserDefaults.standard.data(forKey: Self.key(Constants.workoutCovers, group: group)) else {
                event(.success([]))
                return Disposables.create()
            }
            
            let workoutCovers = try? JSONDecoder().decode([WorkoutCover].self, from: data)

            event(.success(workoutCovers ?? []))

            return Disposables.create()
        }
    }

    static func key(_ base: String, group: FitnessGroup) -> String {
        base + "_" + group.cacheKey
    }
}
