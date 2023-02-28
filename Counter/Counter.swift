//
//  Counter.swift
//  Counter
//
//  Created by Pann Cherry on 2/28/23.
//

import Combine
import SwiftUI
import PrimeAlert
import PrimeTimeComposableArchitecture

public typealias CounterEnvironment = (Int) -> Effect<Int?>

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeButtonDisabled: Bool
)

public enum CounterAction: Equatable {
    case decrementTapped
    case incrementTapped
    case nthPrimeButtonTapped
    case nthPrimeResponse(n: Int, prime: Int?)
    case alertDismissButtonTapped
}

public func counterReducer(
    state: inout CounterState,
    action: CounterAction,
    environment: CounterEnvironment
) -> [Effect<CounterAction>] {
    switch action {
    case .decrementTapped:
        state.count -= 1
        return []

    case .incrementTapped:
        state.count += 1
        return []

    case .nthPrimeButtonTapped:
      state.isNthPrimeButtonDisabled = true
      let n = state.count
      return [
        environment(state.count)
          .map { CounterAction.nthPrimeResponse(n: n, prime: $0) }
          .receive(on: DispatchQueue.main)
          .eraseToEffect()
      ]

    case let .nthPrimeResponse(n, prime):
      state.alertNthPrime = prime.map { PrimeAlert(n: n, prime: $0) }
      state.isNthPrimeButtonDisabled = false
      return []

    case .alertDismissButtonTapped:
        state.alertNthPrime = nil
        return []
    }
}
