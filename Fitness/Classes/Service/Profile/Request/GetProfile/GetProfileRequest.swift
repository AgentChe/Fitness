//
//  GetProfileRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 03.02.2023.
//

import Alamofire

struct GetProfileRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String
    
    var url: String {
        domain + "/api/users/show"
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
