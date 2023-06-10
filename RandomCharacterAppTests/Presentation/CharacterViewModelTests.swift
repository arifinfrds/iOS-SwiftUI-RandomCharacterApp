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
    
    var shouldShowError = false
    var errorMessage: String? = nil
    var character: Character? = nil
    
    init(characterService: CharacterService) {
        self.characterService = characterService
    }
    
    func onLoad(id: Int) async {
        do {
            character = try await characterService.load(id: id)
        } catch {
            shouldShowError = true
            errorMessage = "Something went wrong, please try again"
        }
    }
}

final class CharacterViewModelTests: XCTestCase {

    func test_init_doesNotPerformRequest() {
        let service = SpyCharacterService()
        _ = CharacterViewModel(characterService: service)
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    func test_onLoad_performRequest() async {
        let service = SpyCharacterService()
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(service.loadUserCallCount, 1)
    }
    
    func test_onLoad_deliversCharacter() async {
        let expectedCharacter = Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
        let service = StubCharacterService(result: .success(expectedCharacter))
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(sut.character, expectedCharacter)
    }
    
    func test_onLoad_deliversError() async {
        let service = StubCharacterService(result: .failure(RemoteCharacterService.Error.invalidJSONError))
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(sut.shouldShowError, true)
        XCTAssertEqual(sut.errorMessage, "Something went wrong, please try again")
    }
}

final class SpyCharacterService: CharacterService {
    
    var loadUserCallCount = 0
    
    func load(id: Int) async throws -> Character {
        loadUserCallCount += 1
        return Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
    }
}

final class StubCharacterService: CharacterService {
    private let result: Result<Character, Error>
    
    init(result: Result<Character, Error>) {
        self.result = result
    }
    
    func load(id: Int) async throws -> Character {
        switch result {
        case .success(let character):
            return character
        case .failure(let error):
            throw error
        }
    }
}
