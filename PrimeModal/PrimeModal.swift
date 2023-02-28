//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by Pann Cherry on 2/28/23.
//

import SwiftUI
import PrimeTimeComposableArchitecture

public typealias PrimeModalState = (count: Int, favoritePrimes: [Int])

public enum PrimeModalAction: Equatable {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

/// Prime modal reducer
/// - Parameters:
///   - state: Mutable `AppState`
///   - action: Save or remove favorite prime
public func primeModalReducer(
    state: inout PrimeModalState,
    action: PrimeModalAction,
    environment: Void
) -> [Effect<PrimeModalAction>] {
    switch action {
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll(where: { $0 == state.count })
        return []
        
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
        return []
    }
}
