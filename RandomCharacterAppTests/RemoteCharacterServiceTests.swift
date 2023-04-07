//
//  RemoteCharacterServiceTests.swift
//  RandomCharacterAppTests
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import XCTest
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

struct Character: Decodable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let gender: String
    let image: URL
}

class RemoteCharacterService {
    
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
        
        return try await withCheckedThrowingContinuation { contunation in
            provider.request(.fetchCharacter(id: id)) { result in
                switch result {
                case let .success(response):
                    if response.statusCode == 201 {
                        contunation.resume(with: .failure(Error.notFoundCharacterError))
                    } else if response.statusCode == 500 {
                        contunation.resume(with: .failure(Error.serverError))
                    } else {
                        do {
                            let character = try JSONDecoder().decode(Character.self, from: response.data)
                            contunation.resume(with: .success(character))
                        } catch {
                            contunation.resume(with: .failure(Error.invalidJSONError))
                        }
                    }
                case .failure:
                    contunation.resume(throwing: Error.timeoutError)
                }
            }
        }
    }
}

final class RemoteCharacterServiceTests: XCTestCase {

    func test_load_returnsTimeoutErrorOnNetworkError() async {
        let sut = makeSUT(sampleResponseClosure: { .networkError(NSError()) })
        
        do {
            _ = try await sut.load(id: 1)
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .timeoutError)
            } else {
                XCTFail("expecteding timeoutError, got \(error) instead.")
            }
        }
    }
    
    func test_load_returnsServerErrorOn500HTTPResponse() async {
        let sut = makeSUT(sampleResponseClosure: { .networkResponse(500, "".data(using: .utf8)!) })
        
        do {
            _ = try await sut.load(id: 1)
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .serverError)
            } else {
                XCTFail("expecteding timeoutError, got \(error) instead.")
            }
        }
    }
    
    func test_load_returnsInvalidJSONErrorOn200HTTPResponseWhenHasEmptyJSON() async {
        let sut = makeSUT(sampleResponseClosure: { .networkResponse(200, "".data(using: .utf8)!) })
        
        do {
            _ = try await sut.load(id: 1)
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .invalidJSONError)
            } else {
                XCTFail("expecteding timeoutError, got \(error) instead.")
            }
        }
    }
    
    func test_load_returnsInvalidJSONErrorOn200HTTPResponseWhenHasInvalidJSONFormat() async {
        let sut = makeSUT(sampleResponseClosure: { .networkResponse(200, self.invalidJSONFormatData()) })
        
        do {
            _ = try await sut.load(id: 1)
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .invalidJSONError)
            } else {
                XCTFail("expecteding timeoutError, got \(error) instead.")
            }
        }
    }
    
    func test_load_returnsCharacterOn200HTTPResponseWhenValidJSONFormat() async {
        let sut = makeSUT(sampleResponseClosure: { .networkResponse(200, self.validJSONFormatData()) })
        
        do {
            let character = try await sut.load(id: 1)
            XCTAssertEqual(character.id, 1)
            XCTAssertEqual(character.name, "Rick Sanchez")
            XCTAssertEqual(character.status, "Alive")
            XCTAssertEqual(character.species, "Human")
            XCTAssertEqual(character.gender, "Male")
            XCTAssertEqual(character.image, URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!)
        } catch {
            XCTFail("expecting to decode, got \(error) instead.")
        }
    }
    
    func test_load_returnsNotFoundCharacterError() async {
        let notFoundCharacterJSONData = """
        {
            "error": "Character not found"
        }
        """.data(using: .utf8)!
        let sut = makeSUT(sampleResponseClosure: { .networkResponse(201, notFoundCharacterJSONData) })
        
        do {
            _ = try await sut.load(id: 1)
        } catch {
            if let error = error as? RemoteCharacterService.Error {
                XCTAssertEqual(error, .notFoundCharacterError)
            } else {
                XCTFail("expecteding notFoundCharacterError, got \(error) instead.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(sampleResponseClosure: @escaping Endpoint.SampleResponseClosure) -> RemoteCharacterService {
        let customEndpointClosure = { (target: CharacterTargetType) -> Endpoint in
            return Endpoint(
                url: URL(target: target).absoluteString,
                sampleResponseClosure: sampleResponseClosure,
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }
        
        let stubbingProvider = MoyaProvider<CharacterTargetType>(endpointClosure: customEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        let sut = RemoteCharacterService(provider: stubbingProvider)
        return sut
    }
    
    private func invalidJSONFormatData() -> Data {
        let invalidJSONFormatData = """
        {
          "id": 1,
          "name": {
            "first": "Rick",
            "last": "Sanchez"
          }
          "status": "Alive",
          "species": "Human",
          "gender": "Male",
          "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg"
        }
        """.data(using: .utf8)!
        
        return invalidJSONFormatData
    }
    
    private func validJSONFormatData() -> Data {
        let validJSONFormatData = """
        {
          "id": 1,
          "name": "Rick Sanchez",
          "status": "Alive",
          "species": "Human",
          "type": "",
          "gender": "Male",
          "origin": {
            "name": "Earth (C-137)",
            "url": "https://rickandmortyapi.com/api/location/1"
          },
          "location": {
            "name": "Citadel of Ricks",
            "url": "https://rickandmortyapi.com/api/location/3"
          },
          "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
          "episode": [
            "https://rickandmortyapi.com/api/episode/1",
            "https://rickandmortyapi.com/api/episode/2",
            "https://rickandmortyapi.com/api/episode/3",
            "https://rickandmortyapi.com/api/episode/4",
            "https://rickandmortyapi.com/api/episode/5",
            "https://rickandmortyapi.com/api/episode/6",
            "https://rickandmortyapi.com/api/episode/7",
            "https://rickandmortyapi.com/api/episode/8",
            "https://rickandmortyapi.com/api/episode/9",
            "https://rickandmortyapi.com/api/episode/10",
            "https://rickandmortyapi.com/api/episode/11",
            "https://rickandmortyapi.com/api/episode/12",
            "https://rickandmortyapi.com/api/episode/13",
            "https://rickandmortyapi.com/api/episode/14",
            "https://rickandmortyapi.com/api/episode/15",
            "https://rickandmortyapi.com/api/episode/16",
            "https://rickandmortyapi.com/api/episode/17",
            "https://rickandmortyapi.com/api/episode/18",
            "https://rickandmortyapi.com/api/episode/19",
            "https://rickandmortyapi.com/api/episode/20",
            "https://rickandmortyapi.com/api/episode/21",
            "https://rickandmortyapi.com/api/episode/22",
            "https://rickandmortyapi.com/api/episode/23",
            "https://rickandmortyapi.com/api/episode/24",
            "https://rickandmortyapi.com/api/episode/25",
            "https://rickandmortyapi.com/api/episode/26",
            "https://rickandmortyapi.com/api/episode/27",
            "https://rickandmortyapi.com/api/episode/28",
            "https://rickandmortyapi.com/api/episode/29",
            "https://rickandmortyapi.com/api/episode/30",
            "https://rickandmortyapi.com/api/episode/31",
            "https://rickandmortyapi.com/api/episode/32",
            "https://rickandmortyapi.com/api/episode/33",
            "https://rickandmortyapi.com/api/episode/34",
            "https://rickandmortyapi.com/api/episode/35",
            "https://rickandmortyapi.com/api/episode/36",
            "https://rickandmortyapi.com/api/episode/37",
            "https://rickandmortyapi.com/api/episode/38",
            "https://rickandmortyapi.com/api/episode/39",
            "https://rickandmortyapi.com/api/episode/40",
            "https://rickandmortyapi.com/api/episode/41",
            "https://rickandmortyapi.com/api/episode/42",
            "https://rickandmortyapi.com/api/episode/43",
            "https://rickandmortyapi.com/api/episode/44",
            "https://rickandmortyapi.com/api/episode/45",
            "https://rickandmortyapi.com/api/episode/46",
            "https://rickandmortyapi.com/api/episode/47",
            "https://rickandmortyapi.com/api/episode/48",
            "https://rickandmortyapi.com/api/episode/49",
            "https://rickandmortyapi.com/api/episode/50",
            "https://rickandmortyapi.com/api/episode/51"
          ],
          "url": "https://rickandmortyapi.com/api/character/1",
          "created": "2017-11-04T18:48:46.250Z"
        }
        """.data(using: .utf8)!
        
        return validJSONFormatData
    }
}
