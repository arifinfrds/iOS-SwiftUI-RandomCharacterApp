//
//  CharacterViewModelTests.swift
//  RandomCharacterAppTests
//
//  Created by arifin on 10/06/23.
//

import Combine
import XCTest
@testable import RandomCharacterApp

final class CharacterViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()

    func test_init_doesNotPerformRequest() {
        let (_, service) = makeSUT()
        
        XCTAssertEqual(service.loadUserCallCount, 0)
    }
    
    func test_onLoad_performRequest() async {
        let (sut, service) = makeSUT()
        
        await sut.onLoad(id: 1)
        
        XCTAssertEqual(service.loadUserCallCount, 1)
    }
    
    func test_onLoad_deliversCharacter() async {
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
    
    func test_onLoad_deliversError() async {
        let errors = RemoteCharacterService.Error.allCases
        for (index, error) in errors.enumerated() {
            let sut = makeSUT(result: .failure(error))
            var receivedStates = [CharacterViewModel.State]()
            sut.$state.dropFirst().sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

            await sut.onLoad(id: 1)

            XCTAssertEqual(receivedStates, [.loading, .error], "Expect error, got fail instead at index: \(index), error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: CharacterViewModel, SpyCharacterService) {
        let service = SpyCharacterService()
        let sut = CharacterViewModel(characterService: service)
        return (sut, service)
    }
    
    private func makeSUT(result: Result<Character, Error>) -> CharacterViewModel {
        let service = StubCharacterService(result: result)
        return CharacterViewModel(characterService: service)
    }
    
    private func anyCharacter() -> Character {
        Character(id: 0, name: "", status: "", species: "", gender: "", image: URL(string: "www.google.com")!)
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
        try result.get()
    }
}
