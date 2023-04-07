//
//  RemoteCharacterServiceTests.swift
//  RandomCharacterAppTests
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import XCTest
import Moya

// success -> fetch character
// success -> not found
// success -> different format JSON
// success -> empty JSON
// failure -> timeout

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

class RemoteCharacterService {
    
    private let provider: MoyaProvider<CharacterTargetType>
    
    init(provider: MoyaProvider<CharacterTargetType>) {
        self.provider = provider
    }
    
    enum Error: Swift.Error {
        case timeoutError
    }
    
    func load() throws {
        throw Error.timeoutError
    }
}

final class RemoteCharacterServiceTests: XCTestCase {

    func test_load_returnsTimeoutErrorOnNetworkError() {
        let customEndpointClosure = { (target: CharacterTargetType) -> Endpoint in
            return Endpoint(
                url: URL(target: target).absoluteString,
                sampleResponseClosure: { .networkError(NSError()) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }
        
        let stubbingProvider = MoyaProvider<CharacterTargetType>(endpointClosure: customEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        let sut = RemoteCharacterService(provider: stubbingProvider)
        
        do {
            try sut.load()
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .timeoutError)
            } else {
                XCTFail("expecteding timeoutError, got \(error) instead.")
            }
        }
    }
}
