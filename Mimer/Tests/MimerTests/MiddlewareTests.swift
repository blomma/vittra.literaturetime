@testable import Mimer
import XCTest

final class MiddlewareTests: XCTestCase {
    struct State: Equatable {
        var counter: Int
    }

    enum Action: Equatable {
        case increment
        case decrement
    }

    typealias Dependencies = Void

    struct CounterMiddleware: Middleware {
        func process(state _: State, with action: Action) async -> Action? {
            switch action {
            case .increment: return .decrement
            case .decrement: return .increment
            }
        }
    }

    func testOptional() async {
        let state: State? = .init(counter: 1)

        let optional = CounterMiddleware().optional()
        let nextAction = await optional.process(state: nil, with: .increment)

        XCTAssertNil(nextAction)

        let anotherAction = await optional.process(state: state, with: .increment)

        XCTAssertEqual(anotherAction, .decrement)
    }

    func testLifted() async {
        struct LiftedState: Equatable {
            var state = State(counter: 1)
        }

        enum LiftedAction: Equatable {
            case action(Action)

            static var prism: Prism<LiftedAction, Action> {
                .init(embed: LiftedAction.action) {
                    guard case let LiftedAction.action(action) = $0 else {
                        return nil
                    }
                    return action
                }
            }
        }

        typealias LiftedDependencies = Void

        let lifted = CounterMiddleware().lifted(
            keyPath: \LiftedState.state,
            prism: LiftedAction.prism
        )

        let nextAction = await lifted.process(state: .init(), with: .action(.increment))
        XCTAssertEqual(nextAction, .action(.decrement))
    }

    func testKeyed() async {
        struct KeyedState: Equatable {
            var keyed = ["key": State(counter: 1)]
        }

        enum KeyedAction: Equatable {
            case action(String, Action)

            static var prism: Prism<KeyedAction, (String, Action)> {
                .init(embed: KeyedAction.action) {
                    guard case let KeyedAction.action(key, action) = $0 else {
                        return nil
                    }
                    return (key, action)
                }
            }
        }

        let keyed = CounterMiddleware().keyed(
            keyPath: \KeyedState.keyed,
            prism: KeyedAction.prism
        )

        let nextAction = await keyed.process(state: .init(), with: .action("key", .increment))
        XCTAssertEqual(nextAction, .action("key", .decrement))

        let nilAction = await keyed.process(state: .init(), with: .action("key1", .increment))
        XCTAssertNil(nilAction)
    }

    func testOffset() async {
        struct OffsetState: Equatable {
            var state: [State] = [.init(counter: 1)]
        }

        enum OffsetAction: Equatable {
            case action(Int, Action)

            static var prism: Prism<OffsetAction, (Int, Action)> {
                .init(embed: OffsetAction.action) {
                    guard case let OffsetAction.action(offset, action) = $0 else {
                        return nil
                    }
                    return (offset, action)
                }
            }
        }

        typealias OffsetDependencies = Void

        let offset = CounterMiddleware().offset(
            keyPath: \OffsetState.state,
            prism: OffsetAction.prism
        )

        let nextAction = await offset.process(state: .init(), with: .action(0, .increment))
        XCTAssertEqual(nextAction, .action(0, .decrement))
    }
}
