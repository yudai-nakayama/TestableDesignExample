import UIKit
import enum Result.Result
import PromiseKit



protocol RootNavigatorContract {
    func navigateToRoot()
}



class RootNavigator: RootNavigatorContract {
    private let registry: BootstrapResourceRegistryContract
    private let window: UIWindow


    init(
        willUpdate window: UIWindow,
        byReading registry: BootstrapResourceRegistryContract
    ) {
        self.window = window
        self.registry = registry
    }


    func navigateToRoot() {
        let navigationController = NavigationController()
        let navigator = Navigator(for: navigationController)

        let repository = GitHubRepository(
            owner: GitHubUser.Name(text: "Kuniwak"),
            name: GitHubRepository.Name(text: "MirrorDiffKit")
        )

        guard let rootViewController = StargazersMvcComposer.create(
            byStargazersOf: repository,
            withResourceOf: self.registry,
            andFetchingVia:  GitHubApiClient(registry: self.registry),
            andNavigateBy: navigator
        ) else {
            self.window.rootViewController = FatalErrorViewController.create(
                debugInfo: "StarredRepositoriesViewController.create returned nil"
            )
            return
        }

        navigationController.setViewControllers([rootViewController], animated: true)

        self.window.rootViewController = navigationController
    }
}
