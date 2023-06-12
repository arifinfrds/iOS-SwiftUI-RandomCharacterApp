//
//  CharacterViewModelTests.swift
//  RandomCharacterAppTests
//
//  Created by arifin on 13/06/23.
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

    func test_init_doesNotLoadUser() {
        let service = CharacterServiceSpy()
        let sut = CharacterViewModel(characterService: service)
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    private final class CharacterServiceSpy: CharacterService {
        private(set) var loadUserCallCount = 0
        
        func load(id: Int) async throws -> Character {
            loadUserCallCount += 1
            return Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
        }
    }

}
