//
//  DevRoot.swift
//  MatchMate
//
//  DEBUG-only launch router so screens can be inspected in isolation from the simulator via
//  `xcrun simctl launch ... -uiScreen <name>`. With no argument it is a passthrough to the real
//  app root.
//

#if DEBUG
import SwiftUI

struct DevRoot: View {
    let environment: AppEnvironment

    private var screen: String? {
        ProcessInfo.processInfo.arguments
            .firstIndex(of: "-uiScreen")
            .flatMap { ProcessInfo.processInfo.arguments[safe: $0 + 1] }
    }

    var body: some View {
        switch screen {
        case "decisions":
            let env = AppEnvironment(repository: PreviewProfileRepository())
            let vm = env.makeListViewModel()
            NavigationStack { DecisionsView(viewModel: vm, environment: env) }
                .task { await vm.start() }
        case "detail":
            let env = AppEnvironment(repository: PreviewProfileRepository())
            NavigationStack {
                MatchDetailView(viewModel: env.makeDetailViewModel(id: Profile.previewList().first!.id))
            }
        case "detail-decided":
            let env = AppEnvironment(repository: PreviewProfileRepository())
            NavigationStack {
                MatchDetailView(viewModel: env.makeDetailViewModel(id: Profile.previewList().last!.id))
            }
        default:
            DiscoverView(viewModel: environment.makeListViewModel(), environment: environment)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
