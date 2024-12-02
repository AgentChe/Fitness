//
//  LoginRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 05.07.2022.
//

import Alamofire

struct LoginRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String

    var url: String {
        domain + "/api/users/login"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        [
            "_api_key": apiKey,
            "user_token": userToken
        ]
    }
}
