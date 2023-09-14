@testable import Mimer
import XCTest

final class StoreTests: XCTestCase {
    struct State: Equatable {
        var counter = 0
    }

    enum Action: Equatable {
        case increment
        case decrement
        case sideEffect
        case set(Int)
    }

    struct TestMiddleware: Middleware {
        func process(state _: State, with action: Action) async -> Action? {
            guard action == .sideEffect else {
                return nil
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return Task.isCancelled ? nil : .increment
        }
    }

    struct TestReducer: Reducer {
        func reduce(oldState: State, with action: Action) -> State {
            var state = oldState
            switch action {
            case .increment:
                state.counter += 1
            case .decrement:
                state.counter -= 1
            case let .set(value):
                state.counter = value
            default:
                break
            }
            return state
        }
    }

    func testSend() async {
        let store = Store<State, Action>(
            initialState: .init(),
            reducer: TestReducer(),
            middlewares: [TestMiddleware()]
        )

        XCTAssertEqual(store.counter, 0)
        await store.send(.increment)
        XCTAssertEqual(store.counter, 1)
        await store.send(.decrement)
        XCTAssertEqual(store.counter, 0)
    }

    func testMiddleware() async {
        let store = Store<State, Action>(
            initialState: .init(),
            reducer: TestReducer(),
            middlewares: [TestMiddleware()]
        )

        XCTAssertEqual(store.counter, 0)
        let task = Task { await store.send(.sideEffect) }
        XCTAssertEqual(store.counter, 0)
        await task.value
        XCTAssertEqual(store.counter, 1)
    }

    func testMiddlewareCancellation() async {
        let store = Store<State, Action>(
            initialState: .init(),
            reducer: TestReducer(),
            middlewares: [TestMiddleware()]
        )

        XCTAssertEqual(store.counter, 0)
        let task = Task { await store.send(.sideEffect) }
        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertEqual(store.counter, 0)
        task.cancel()
        await task.value
        XCTAssertEqual(store.counter, 0)
    }

    func testBinding() async {
        let store = Store<State, Action>(
            initialState: .init(),
            reducer: TestReducer(),
            middlewares: [TestMiddleware()]
        )

        let binding = store.binding(
            extract: \.counter,
            embed: Action.set
        )

        binding.wrappedValue = 10

        try? await Task.sleep(nanoseconds: 1_000_000)
        XCTAssertEqual(store.counter, 10)
    }

    func testThreadSafety() async {
        let store = Store<State, Action>(
            initialState: .init(),
            reducer: TestReducer(),
            middlewares: [TestMiddleware()]
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 1 ... 1_000_000 {
                group.addTask {
                    await store.send(.increment)
                }
            }
        }

        XCTAssertEqual(store.counter, 1_000_000)
    }
}
