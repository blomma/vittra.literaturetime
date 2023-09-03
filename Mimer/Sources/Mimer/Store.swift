import Observation

/// Type that stores the state of the app or feature.
@Observable @dynamicMemberLookup public final class Store<State, Action> {
    private var state: State

    private let reducer: any Reducer<State, Action>
    private let middlewares: any Collection<any Middleware<State, Action>>

    /// Creates an instance of `Store` with the folowing parameters.
    public init(
        initialState state: State,
        reducer: some Reducer<State, Action>,
        middlewares: some Collection<any Middleware<State, Action>>
    ) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    /// A subscript providing access to the state of the store.
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }

    /// Use this method to mutate the state of the store by feeding actions.
    @MainActor public func send(_ action: Action) async {
        state = reducer.reduce(oldState: state, with: action)

        await withTaskGroup(of: Action?.self) { group in
            middlewares.forEach { middleware in
                group.addTask {
                    await middleware.process(state: self.state, with: action)
                }
            }

            for await case let nextAction? in group {
                await send(nextAction)
            }
        }
    }
}

import SwiftUI

public extension Store {
    /// Use this method to create a `SwiftUI.Binding` from any instance of `Store`.
    func binding<Value>(
        extract: @escaping (State) -> Value,
        embed: @escaping (Value) -> Action
    ) -> Binding<Value> {
        .init(
            get: { extract(self.state) },
            set: { newValue in Task { await self.send(embed(newValue)) } }
        )
    }
}
