//
//  GetWorkoutCoversRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 07.03.2023.
//

import Alamofire

struct GetWorkoutCoversRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String
    
    var url: String {
        domain + "/api/glossary/workout_names"
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
