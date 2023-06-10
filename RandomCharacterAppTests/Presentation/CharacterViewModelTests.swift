//
//  CharacterViewModelTests.swift
//  RandomCharacterAppTests
//
//  Created by arifin on 10/06/23.
//

import XCTest
@testable import RandomCharacterApp

final class CharacterViewModel {
    private let characterService: CharacterService
    
    init(characterService: CharacterService) {
        self.characterService = characterService
    }
}

final class CharacterViewModelTests: XCTestCase {

    func test_init_doesNotPerformRequest() {
        let service = MockCharacterService()
        let sut = CharacterViewModel(characterService: service)
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
}

final class MockCharacterService: CharacterService {
    
    var loadUserCallCount = 0
    
    func load(id: Int) async throws -> Character {
        Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
    }
}
