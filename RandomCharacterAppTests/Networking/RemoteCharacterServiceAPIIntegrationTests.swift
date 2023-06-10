//
//  RemoteCharacterServiceAPIIntegrationTests.swift
//  RandomCharacterAppTests
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import XCTest
import Moya
@testable import RandomCharacterApp

final class RemoteCharacterServiceAPIIntegrationTests: XCTestCase {
    
    func test_load_returnsCorrectCharacter() async {
        let provider = MoyaProvider<CharacterTargetType>()
        let sut = RemoteCharacterService(provider: provider)
        
        do {
            let character = try await sut.load(id: 1)
            XCTAssertEqual(character.id, 1)
            XCTAssertEqual(character.name, "Rick Sanchez")
            XCTAssertEqual(character.status, "Alive")
            XCTAssertEqual(character.species, "Human")
            XCTAssertEqual(character.gender, "Male")
            XCTAssertEqual(character.image, URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!)
        } catch {
            XCTFail("exepcting to get real response, got \(error) instead.")
        }
    }

}
