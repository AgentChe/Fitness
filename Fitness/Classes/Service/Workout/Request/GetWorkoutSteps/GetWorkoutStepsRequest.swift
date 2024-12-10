//
//  GetWorkoutStepsRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 02.03.2023.
//

import Alamofire

struct GetWorkoutStepsRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String
    
    var url: String {
        domain + "/api/glossary/training_steps"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        [
            "_api_key": apiKey,
            "_user_token": userToken
        ]
    }
}
