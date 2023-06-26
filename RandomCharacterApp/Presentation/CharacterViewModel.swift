//
//  CharacterViewModel.swift
//  RandomCharacterApp
//
//  Created by arifin on 14/06/23.
//

import Foundation

final class CharacterViewModel {
    private let characterService: CharacterService
    
    enum State: Equatable {
        case initial
        case loading
        case display(Character)
        case error
    }
    
    @Published var state: State = .initial
    
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
