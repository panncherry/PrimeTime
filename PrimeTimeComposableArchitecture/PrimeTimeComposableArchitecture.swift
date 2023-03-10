//
//  PrimeTimeComposableArchitecture.swift
//  PrimeTimeComposableArchitecture
//
//  Created by Pann Cherry on 2/28/23.
//

import Combine
import SwiftUI

public struct Effect<Output>: Publisher {
    public typealias Failure = Never
    
    let publisher: AnyPublisher<Output, Failure>
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Never == S.Failure, Output == S.Input {
        self.publisher.receive(subscriber: subscriber)
    }
}

extension Effect {
    public static func fireAndForget(work: @escaping () -> Void) -> Effect {
        return Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }.eraseToEffect()
    }
}

extension Effect {
    public static func sync(work: @escaping () -> Output) -> Effect {
        return Deferred {
            Just(work())
        }.eraseToEffect()
    }
}

extension Publisher where Failure == Never {
    public func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: self.eraseToAnyPublisher())
    }
}

public typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]

/// Wrapper that conforms ObservableObject protocol
public final class Store<Value, Action>: ObservableObject {
    
    @Published public private(set) var value: Value
    
    private let reducer: Reducer<Value, Action, Any>
    private let environment: Any
    private var viewCancellable: Cancellable?
    private var effectCancellables: Set<AnyCancellable> = []
    
    public init<Environment>(
        value: Value,
        reducer: @escaping Reducer<Value, Action, Environment>,
        environment: Environment
    ) {
        self.value = value
        self.reducer = { value, action, environment in
            reducer(&value, action, environment as! Environment)
        }
        self.environment = environment
    }
    
    public func send(_ action: Action) {
        let effects = reducer(&value, action, self.environment)
        effects.forEach { effect in
            
            var effectCancellable: AnyCancellable?
            var didComplete = false
            
            effectCancellable = effect.sink(receiveCompletion: { [weak self] _ in
                didComplete = true
                guard let effectCancellable = effectCancellable else { return }
                self?.effectCancellables.remove(effectCancellable)
            }, receiveValue: self.send )
            
            if !didComplete, let effectCancellable = effectCancellable {
                effectCancellables.insert(effectCancellable)
            }
        }
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        
        let localStore = Store<LocalValue, LocalAction>(
            value: toLocalValue(self.value),
            reducer: { localValue, localAction, localEnvironment in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            },
            environment: self.environment
        )
        
        localStore.viewCancellable = self.$value.sink { [weak localStore] newValue in
            localStore?.value = toLocalValue(newValue)
        }
        
        return localStore
    }
    
}

/// Combine array of reducers
public func combine<Value, Action, Environment>(
    _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducers.flatMap { $0(&value, action, environment) }
        return effects
    }
}

/// Pulling back reducers along values and actions
/// Pullback reducers that know how to work with local actions to reducers that know how to work on global actions
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>,
    environment: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
    return { globalValue, globalAction, globalEnvironment in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction, environment(globalEnvironment))
        
        return localEffects.map { localEffect in
            localEffect.map { localAction -> GlobalAction in
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
            .eraseToEffect()
        }
    }
}

public func logging<Value, Action, Environment>(
    _ reducer: @escaping Reducer<Value, Action, Environment>
) -> Reducer<Value, Action, Environment> {
    return { value, action, environment in
        let effects = reducer(&value, action, environment)
        let newValue = value
        return [ .fireAndForget {
            print("Action: \(action)")
            print("Value:")
            dump(newValue)
            print("---")
        }] + effects
    }
}
