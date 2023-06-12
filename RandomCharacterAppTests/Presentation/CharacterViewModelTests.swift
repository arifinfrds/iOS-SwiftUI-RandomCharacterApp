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
    
    var errorMessage: String = ""
    var character: Character?
    
    init(characterService: CharacterService) {
        self.characterService = characterService
    }
    
    func onLoad(id: Int) async {
        do {
            character = try await characterService.load(id: id)
        } catch {
            errorMessage = "Oops, an error occur, Please try again later."
        }
    }
}

final class CharacterViewModelTests: XCTestCase {

    func test_init_doesNotLoadCharacter() {
        let service = CharacterServiceSpy()
        let sut = CharacterViewModel(characterService: service)
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    func test_onLoad_loadCharacter() async {
        let service = CharacterServiceSpy()
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(service.loadUserCallCount, 1)
    }
    
    func test_onLoad_showsError() async {
        let service = CharacterServiceStub(result: .failure(RemoteCharacterService.Error.serverError))
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(sut.errorMessage, "Oops, an error occur, Please try again later.")
    }
    
    func test_onLoad_showsCharacter() async {
        let expectedCharacter = Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
        let service = CharacterServiceStub(result: .success(expectedCharacter))
        let sut = CharacterViewModel(characterService: service)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(sut.character, expectedCharacter)
    }
    
    private final class CharacterServiceStub: CharacterService {
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
    
    private final class CharacterServiceSpy: CharacterService {
        private(set) var loadUserCallCount = 0
        
        func load(id: Int) async throws -> Character {
            loadUserCallCount += 1
            return Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
        }
    }

}
