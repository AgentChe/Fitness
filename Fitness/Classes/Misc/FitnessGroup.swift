//
//  FitnessGroup.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import RxSwift
import RxCocoa

final class FitnessGroupMediator {
    static let shared = FitnessGroupMediator()
    
    private lazy var didUpdateAfterSetProfileTrigger = PublishRelay<Void>()
    
    private init() {}
    
    func updateAfterSetProfile() {
        didUpdateAfterSetProfileTrigger.accept(Void())
    }
    
    var didUpdateAfterSetProfile: Signal<Void> {
        didUpdateAfterSetProfileTrigger.asSignal()
    }
}

enum FitnessGroup: Codable, CaseIterable {
    case calisthenics
    case chairYoga
    case somatic
    case stretching
    case wallPilates
    
    private enum Constants {
        static let key = "fitness_group_key"
    }
    
    static var current: FitnessGroup {
        set(newValue) {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Constants.key)
            }
        }
        
        get {
            let group: FitnessGroup? = {
                guard let data = UserDefaults.standard.data(forKey: Constants.key) else { return nil }
                return try? JSONDecoder().decode(FitnessGroup.self, from: data)
            }()
            return group ?? .calisthenics
        }
    }
    
    var domain: String {
        switch self {
        case .calisthenics:
            return "https://calisthenics.thinkaboutapps.com"
        case .chairYoga:
            return "https://chair.thinkaboutapps.com"
        case .somatic:
            return "https://somatic.thinkaboutapps.com"
        case .stretching:
            return "https://stretching.thinkaboutapps.com"
        case .wallPilates:
            return "https://pilates.thinkaboutapps.com"
        }
    }
    
    var apiKey: String {
        switch self {
        case .calisthenics:
            return "hZJtjfDEKQzzAaQ8oMYg"
        case .chairYoga:
            return "DaF8GpH8HqEhKkC4oKpb"
        case .somatic:
            return "Btk4yD8ENGFbHaQcnn60"
        case .stretching:
            return "DzoCXXf4JZaUr4CmTkWU"
        case .wallPilates:
            return "7gOuz7NvJpQYVVCUkF69"
        }
    }

    var cacheKey: String {
        switch self {
        case .calisthenics:
            return "calisthenics"
        case .chairYoga:
            return "chair_yoga"
        case .somatic:
            return "somatic"
        case .stretching:
            return "stretching"
        case .wallPilates:
            return "wall_pilates"
        }
    }
}
