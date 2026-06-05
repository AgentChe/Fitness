//
//  ProfileManager.swift
//  Soccer
//
//  Created by Андрей Чернышев on 05.07.2022.
//

import RxSwift

protocol ProfileManagerProtocol {
    func set(
        group: FitnessGroup,
        skillLevelId: Int?,
        weekSchedule: WeekSchedule?,
        drillsIds: [Int]?,
        focusZonesIds: [Int]?,
        gender: Gender?
    ) -> Single<Void>
    func obtainProfile(group: FitnessGroup, forceUpdate: Bool, save: Bool) -> Single<Profile?>
    func syncTokens(group: FitnessGroup, oldToken: String, newToken: String) -> Single<Void>
    func login(group: FitnessGroup, userToken: String) -> Single<Void>
}

final class ProfileManager {
    enum Constants {
        static let skillLevelId = "profile_manager_skill_level_id_key"
        static let weekSchedule = "profile_manager_week_schedule_key"
        static let drillsIds = "profile_manager_drills_ids_key"
        static let focusZonesIds = "profile_manager_focus_zones_ids_key"
        static let gender = "profile_manager_gender_key"
    }
    
    private lazy var defaultRequestWrapper = DefaultRequestWrapper()
    
    private lazy var sessionManager = SessionManager()
}

// MARK: ProfileManagerProtocol
extension ProfileManager: ProfileManagerProtocol {
    func set(
        group: FitnessGroup = FitnessGroup.current,
        skillLevelId: Int? = nil,
        weekSchedule: WeekSchedule? = nil,
        drillsIds: [Int]? = nil,
        focusZonesIds: [Int]? = nil,
        gender: Gender? = nil
    ) -> Single<Void> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let weekScheduleDays = weekSchedule.map { weekSchedule -> [Int] in
            [
                weekSchedule.su ? 0 : nil,
                weekSchedule.mo ? 1: nil,
                weekSchedule.tu ? 2 : nil,
                weekSchedule.we ? 3 : nil,
                weekSchedule.th ? 4 : nil,
                weekSchedule.fr ? 5 : nil,
                weekSchedule.sa ? 6 : nil
            ].compactMap { $0 }
        }
        
        let timezone = TimeZone.current.identifier

        let request = SetRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken,
            skillLevel: skillLevelId,
            weekSchedule: weekScheduleDays,
            drills: drillsIds,
            focusZones: focusZonesIds,
            timezone: timezone,
            gender: gender?.code
        )

        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .mapToVoid()
            .do(onSuccess: { [weak self] in
                self?.store(skillLevelId: skillLevelId, group: group)
                self?.store(gender: gender, group: group)
                self?.store(weekSchedule: weekSchedule, group: group)
                self?.store(drillsIds: drillsIds, group: group)
                self?.store(focusZonesIds: focusZonesIds, group: group)
            })
    }

    func obtainProfile(group: FitnessGroup = FitnessGroup.current, forceUpdate: Bool, save: Bool = true) -> Single<Profile?> {
        forceUpdate ? loadProfile(group: group, save: save) : cachedProfile(group: group)
    }
    
    func syncTokens(group: FitnessGroup, oldToken: String, newToken: String) -> Single<Void> {
        let request = SyncTokensRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            oldToken: oldToken,
            newToken: newToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .mapToVoid()
    }
    
    func login(group: FitnessGroup, userToken: String) -> Single<Void> {
        let request = LoginRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .mapToVoid()
    }
}

// MARK: Private
private extension ProfileManager {
    static func key(_ base: String, group: FitnessGroup) -> String {
        base + "_" + group.cacheKey
    }
    
    func loadProfile(group: FitnessGroup, save: Bool) -> Single<Profile?> {
        guard let userToken = sessionManager.getSession()?.userToken else {
            return .error(SignError.tokenNotFound)
        }
        
        let request = GetProfileRequest(
            domain: group.domain,
            apiKey: group.apiKey,
            userToken: userToken
        )
        
        return defaultRequestWrapper
            .callServerApi(requestBody: request)
            .map { GetProfileResponse.map(from: $0) }
            .do(onSuccess: { [weak self] profile in
                if save {
                    self?.store(skillLevelId: profile?.skillLevelId, group: group)
                    self?.store(weekSchedule: profile?.weekSchedule, group: group)
                    self?.store(drillsIds: profile?.drillsIds, group: group)
                    self?.store(focusZonesIds: profile?.focusZonesIds, group: group)
                    self?.store(gender: profile?.gender, group: group)
                }
            })
    }

    func cachedProfile(group: FitnessGroup) -> Single<Profile?> {
        Single
            .zip(
                cachedSkillLevelId(group: group),
                cachedGender(group: group),
                cachedWeekSchedule(group: group),
                cachedDrillsIds(group: group),
                cachedFocusZonesIds(group: group)
            )
            .map { skillLevelId, gender, weekSchedule, drillsIds, focusZonesIds -> Profile in
                Profile(skillLevelId: skillLevelId,
                        gender: gender,
                        weekSchedule: weekSchedule,
                        drillsIds: drillsIds,
                        focusZonesIds: focusZonesIds)
            }
    }

    func store(skillLevelId: Int?, group: FitnessGroup) {
        guard let skillLevelId = skillLevelId else {
            return
        }

        UserDefaults.standard.set(skillLevelId, forKey: Self.key(Constants.skillLevelId, group: group))

        ProfileMediator.shared.notify(skillLevelId: skillLevelId)
    }

    func cachedSkillLevelId(group: FitnessGroup) -> Single<Int?> {
        Single<Int?>.create { event in
            let skillLevelId = UserDefaults.standard.value(forKey: Self.key(Constants.skillLevelId, group: group)) as? Int

            event(.success(skillLevelId))

            return Disposables.create()
        }
    }

    func store(weekSchedule: WeekSchedule?, group: FitnessGroup) {
        guard let weekSchedule = weekSchedule else {
            return
        }

        let data = try? JSONEncoder().encode(weekSchedule)

        UserDefaults.standard.set(data, forKey: Self.key(Constants.weekSchedule, group: group))

        ProfileMediator.shared.notify(weekSchedule: weekSchedule)
    }

    func cachedWeekSchedule(group: FitnessGroup) -> Single<WeekSchedule?> {
        Single<WeekSchedule?>.create { event in
            guard let data = UserDefaults.standard.data(forKey: Self.key(Constants.weekSchedule, group: group)) else {
                event(.success(nil))
                return Disposables.create()
            }

            let weekSchedule = try? JSONDecoder().decode(WeekSchedule.self, from: data)

            event(.success(weekSchedule))

            return Disposables.create()
        }
    }

    func store(drillsIds: [Int]?, group: FitnessGroup) {
        guard let drillsIds = drillsIds else {
            return
        }

        UserDefaults.standard.set(drillsIds, forKey: Self.key(Constants.drillsIds, group: group))

        ProfileMediator.shared.notify(drillsIds: drillsIds)
    }

    func cachedDrillsIds(group: FitnessGroup) -> Single<[Int]?> {
        Single<[Int]?>.create { event in
            let drillsIds = UserDefaults.standard.value(forKey: Self.key(Constants.drillsIds, group: group)) as? [Int]

            event(.success(drillsIds))

            return Disposables.create()
        }
    }

    func store(focusZonesIds: [Int]?, group: FitnessGroup) {
        guard let focusZonesIds = focusZonesIds else {
            return
        }

        UserDefaults.standard.set(focusZonesIds, forKey: Self.key(Constants.focusZonesIds, group: group))

        ProfileMediator.shared.notify(focusZonesIds: focusZonesIds)
    }

    func cachedFocusZonesIds(group: FitnessGroup) -> Single<[Int]?> {
        Single<[Int]?>.create { event in
            let focusZonesIds = UserDefaults.standard.value(forKey: Self.key(Constants.focusZonesIds, group: group)) as? [Int]

            event(.success(focusZonesIds))

            return Disposables.create()
        }
    }

    func store(gender: Gender?, group: FitnessGroup) {
        guard let gender else {
            return
        }

        UserDefaults.standard.set(gender.code, forKey: Constants.gender)
    }

    func cachedGender(group: FitnessGroup) -> Single<Gender?> {
        Single<Gender?>.create { event in
            let genderCode = UserDefaults.standard.value(forKey: Constants.gender) as? Int
            let gender = genderCode.flatMap { Gender(code: $0)}
            event(.success(gender))

            return Disposables.create()
        }
    }
}
