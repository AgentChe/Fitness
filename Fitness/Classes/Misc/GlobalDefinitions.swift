//
//  GlobalDefinitions.swift
//  Soccer
//
//  Created by Andrey Chernyshev on 16.01.2021.
//

import Foundation

final class GlobalDefinitions {
    static let domain = FitnessGroup.current.domain
    static let apiKey = FitnessGroup.current.apiKey
    
    static let otterScaleHost = "https://api.korrekted.com"
    static let otterScaleApiKey = "vdOg9Izc5iKZqRDB"
    
    static let applicationTag = "FITNESS_WORKOUT"
    static let amplitudeApiKey = "d433d2c66723aeefd10c5b65f91c1fa3"
    
    static let termsOfServiceUrl = URL(string: "https://coffeestop-ou.com/terms.html")!
    static let privacyPolicyUrl = URL(string: "https://coffeestop-ou.com/policy.html")!
    static let contactUsUrl = URL(string: "https://coffeestop-ou.com/contacts.html")!
    
    enum Paygate {
        static let defaultLifetime = "train.fitness.endless"
        static let defaultMonthly = "train.fitness.monthly"
    }
}
