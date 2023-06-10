//
//  CharacterViewModelTests.swift
//  RandomCharacterAppTests
//
//  Created by arifin on 10/06/23.
//

import Combine
import XCTest
@testable import RandomCharacterApp

final class CharacterViewModel: ObservableObject {
    private let characterService: CharacterService
    
    @Published var state: State?
    
    enum State: Equatable {
        case loading
        case display(Character)
        case error
    }
    
    init(characterService: CharacterService) {
        self.characterService = characterService
    }
    
    func onLoad(id: Int) async {
        state = .loading
        do {
            let character = try await characterService.load(id: id)
            state = .display(character)
        } catch {
            state = .error
        }
    }
}

final class CharacterViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()

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
        var receivedStates = [CharacterViewModel.State]()
        sut.$state.sink { state in
            if let state = state {
                receivedStates.append(state)
            }
        }
        .store(in: &cancellables)
        
        await sut.onLoad(id: 1)
        

        XCTAssertEqual(receivedStates, [ .loading, .display(expectedCharacter) ])
    }
    
    func test_onLoad_deliversError() async {
        let service = StubCharacterService(result: .failure(RemoteCharacterService.Error.invalidJSONError))
        let sut = CharacterViewModel(characterService: service)
        var receivedStates = [CharacterViewModel.State]()
        sut.$state.sink { state in
            if let state = state {
                receivedStates.append(state)
            }
        }
        .store(in: &cancellables)

        await sut.onLoad(id: 1)

        XCTAssertEqual(receivedStates, [ .loading, .error ])
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
