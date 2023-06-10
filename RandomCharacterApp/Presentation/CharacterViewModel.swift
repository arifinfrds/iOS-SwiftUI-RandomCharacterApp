//
//  CharacterViewModel.swift
//  RandomCharacterApp
//
//  Created by arifin on 10/06/23.
//

import Foundation

final class CharacterViewModel: ObservableObject {
    private let characterService: CharacterService
    
    @Published var state: State = .initial
    
    enum State: Equatable {
        case initial
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
