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
    
    func onLoad(id: Int) async {
        _ = try? await characterService.load(id: id)
    }
}

final class CharacterViewModelTests: XCTestCase {

    func test_init_doesNotPerformRequest() {
        let service = MockCharacterService()
        _ = CharacterViewModel(characterService: service)
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    func test_onLoad_performRequest() async {
        let service = MockCharacterService()
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(service.loadUserCallCount, 1)
    }
}

final class MockCharacterService: CharacterService {
    
    var loadUserCallCount = 0
    
    func load(id: Int) async throws -> Character {
        loadUserCallCount += 1
        return Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
    }
}
