//
//  GlobalDefinitions.swift
//  Soccer
//
//  Created by Andrey Chernyshev on 16.01.2021.
//

import Foundation

final class GlobalDefinitions {
    static var domain: String { FitnessGroup.current.domain }
    static var apiKey: String { FitnessGroup.current.apiKey }
    
    static let otterScaleHost = "https://api.korrekted.com"
    static let otterScaleApiKey = "vdOg9Izc5iKZqRDB"
    
    static let termsOfServiceUrl = URL(string: "https://thinkaboutapps.com/terms")!
    static let privacyPolicyUrl = URL(string: "https://thinkaboutapps.com/policy")!
    static let contactUsUrl = URL(string: "https://thinkaboutapps.com/contact")!
    
    enum Paygate {
        static let defaultLifetime = "train.fitness.endless"
        static let defaultMonthly = "train.fitness.monthly"
    }
}
