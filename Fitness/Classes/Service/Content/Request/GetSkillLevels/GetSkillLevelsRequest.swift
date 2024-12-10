//
//  GetSkillLevelsRequest.swift
//  Soccer
//
//  Created by Андрей Чернышев on 01.03.2023.
//

import Alamofire

struct GetSkillLevelsRequest: APIRequestBody {
    let domain: String
    let apiKey: String
    let userToken: String
    
    var url: String {
        domain + "/api/glossary/levels"
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
