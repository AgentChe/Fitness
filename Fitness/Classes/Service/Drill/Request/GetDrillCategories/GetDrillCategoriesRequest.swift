//
//  GetDrillCategoriesRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 02.02.2023.
//

import Alamofire

struct GetDrillCategoriesRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String

    var url: String {
        domain + "/api/glossary/drill_categories"
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
