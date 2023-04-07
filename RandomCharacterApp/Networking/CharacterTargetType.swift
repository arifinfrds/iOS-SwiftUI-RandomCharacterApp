//
//  CharacterTargetType.swift
//  RandomCharacterApp
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import Foundation
import Moya

// success -> fetch character ✅
// success -> not found ✅
// success -> different format JSON ✅
// success -> empty JSON ✅
// success -> server error ✅
// failure -> timeout ✅

enum CharacterTargetType: TargetType {
    
    case fetchCharacter(id: Int)
    
    var baseURL: URL {
        return URL(string: "https://rickandmortyapi.com/api")!
    }
    
    var path: String {
        switch self {
        case let .fetchCharacter(id):
            return "/character/\(id)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .fetchCharacter:
            return .get
        }
    }
    
    var task: Moya.Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return nil
    }
}
