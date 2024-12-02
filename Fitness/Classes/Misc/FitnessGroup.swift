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
            return "https://calisthenics.cocorporateapps.com"
        case .chairYoga:
            return "https://chair.cocorporateapps.com"
        case .somatic:
            return "https://somatic.cocorporateapps.com"
        case .stretching:
            return "https://stretching.cocorporateapps.com"
        case .wallPilates:
            return "https://pilates.cocorporateapps.com"
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
}
