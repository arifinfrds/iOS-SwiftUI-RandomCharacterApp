//
//  Character.swift
//  RandomCharacterApp
//
//  Created by arifinfrds.engineer on 07/04/23.
//

import Foundation

struct Character: Decodable, Equatable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let gender: String
    let image: URL
}
