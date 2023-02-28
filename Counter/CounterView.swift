//
//  CounterView.swift
//  Counter
//
//  Created by Pann Cherry on 2/28/23.
//

import Combine
import SwiftUI
import PrimeAlert
import PrimeModal
import PrimeTimeComposableArchitecture

public struct CounterViewState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var count: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeButtonDisabled: Bool
    
    public init(
        alertNthPrime: PrimeAlert? = nil,
        count: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeButtonDisabled: Bool = false
    ) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }
    
    var counter: CounterState {
        get { (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled) }
        set { (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled) = newValue }
    }
    
    var primeModal: PrimeModalState {
        get { (self.count, self.favoritePrimes) }
        set { (self.count, self.favoritePrimes) = newValue }
    }
}

public enum CounterViewAction: Equatable {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }
    
    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
}


public let counterViewReducer: Reducer<CounterViewState, CounterViewAction, CounterEnvironment> = combine(
    pullback(counterReducer,
             value: \CounterViewState.counter,
             action: \CounterViewAction.counter,
             environment: {$0}
            ),
    pullback(
        primeModalReducer,
        value: \.primeModal,
        action: \.primeModal,
        environment: { _ in () }
    )
)
