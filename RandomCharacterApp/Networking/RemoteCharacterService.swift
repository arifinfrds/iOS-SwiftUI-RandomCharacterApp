//
//  RemoteCharacterService.swift
//  RandomCharacterApp
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import Foundation
import Moya

protocol CharacterService {
    func load(id: Int) async throws -> Character
}

class RemoteCharacterService: CharacterService {
    
    private let provider: MoyaProvider<CharacterTargetType>
    
    init(provider: MoyaProvider<CharacterTargetType>) {
        self.provider = provider
    }
    
    enum Error: Swift.Error {
        case timeoutError
        case invalidJSONError
        case serverError
        case notFoundCharacterError
    }
    
    func load(id: Int) async throws -> Character {
        return try await withCheckedThrowingContinuation { contiunation in
            load(id: id) { result in
                contiunation.resume(with: result)
            }
        }
    }
    
    private func load(id: Int, completion: @escaping (Result<Character, Error>) -> Void) {
        provider.request(.fetchCharacter(id: id)) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(response):
                completion(map(response))
            case .failure:
                completion(.failure(.timeoutError))
            }
        }
    }
    
    private func map(_ response: Moya.Response) -> Result<Character, Error> {
        if response.statusCode == 201 {
            return .failure(.notFoundCharacterError)
        } else if response.statusCode == 500 {
            return .failure(.serverError)
        } else {
            do {
                let character = try JSONDecoder().decode(Character.self, from: response.data)
                return .success(character)
            } catch {
                return .failure(.invalidJSONError)
            }
        }
    }
}



