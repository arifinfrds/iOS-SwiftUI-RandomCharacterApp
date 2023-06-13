//
//  CharacterViewModelTests.swift
//  RandomCharacterAppTests
//
//  Created by arifin on 13/06/23.
//

import Combine
import XCTest
@testable import RandomCharacterApp

final class CharacterViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()

    func test_init_doesNotLoadCharacter() {
        let (_, service) = makeSUT()
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    func test_onLoad_loadCharacter() async {
        let (sut, service) = makeSUT()
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(service.loadUserCallCount, 1)
    }
    
    func test_onLoad_showsError() async {
        let errors = RemoteCharacterService.Error.allCases
        for (index, error) in errors.enumerated() {
            let sut = makeSUT(result: .failure(error))
            var receivedStates = [CharacterViewModel.State]()
            sut.$state.dropFirst().sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
            
            await sut.onLoad(id: 1)
            
            XCTAssertEqual(receivedStates, [ .loading, .error ], "Fail at: \(index) with error: \(error)")
        }
    }
    
    func test_onLoad_showsCharacter() async {
        let expectedCharacter = anyCharacter()
        let sut = makeSUT(result: .success(expectedCharacter))
        var receivedStates = [CharacterViewModel.State]()
        sut.$state.dropFirst().sink { state in
            receivedStates.append(state)
        }
        .store(in: &cancellables)
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(receivedStates, [ .loading, .display(expectedCharacter) ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(result: Result<Character, Error>) -> CharacterViewModel {
        let service = CharacterServiceStub(result: result)
        let sut = CharacterViewModel(characterService: service)
        return sut
    }
    
    private func makeSUT() -> (sut: CharacterViewModel, service: CharacterServiceSpy) {
        let service = CharacterServiceSpy()
        let sut = CharacterViewModel(characterService: service)
        return (sut, service)
    }
    
    private func anyCharacter() -> Character {
        Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
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
