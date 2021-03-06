import XCTest
import PromiseKit
import MirrorDiffKit
import RxSwift
import RxBlocking
@testable import TestableDesignExample


class StarredRepositoriesModelTests: XCTestCase {
    private struct TestCase {
        let scenario: () -> StargazerModel
        let expected: StargazerModelState
    }


    private let repository = GitHubRepository(
        owner: GitHubUser.Name(text: "octocat"),
        name: GitHubRepository.Name(text: "Hello-world")
    )


    func testScenarios() {
        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                scenario: {
                    let stargazerRepository = self.createPendingRepository()
                    return StargazerModel(
                        for: self.repository,
                        fetchingVia: stargazerRepository
                    )
                },
                expected: .firstFetching
            ),


            #line: TestCase(
                scenario: {
                    let repository = StargazerRepositoryStub(
                        firstResult: Promise(value: [
                            GitHubUser(name: GitHubUser.Name(text: "stargazer-1"), avatar: URL(string: "http://example.com/avatar-1.png")!),
                            GitHubUser(name: GitHubUser.Name(text: "stargazer-2"), avatar: URL(string: "http://example.com/avatar-2.png")!),
                            GitHubUser(name: GitHubUser.Name(text: "stargazer-3"), avatar: URL(string: "http://example.com/avatar-3.png")!),
                        ])
                    )

                    let model = StargazerModel(
                        for: self.repository,
                        fetchingVia: repository
                    )
                    self.waitUntilFetched(model)

                    return model
                },
                expected: .fetched(
                    stargazers: [
                        GitHubUser(name: GitHubUser.Name(text: "stargazer-1"), avatar: URL(string: "http://example.com/avatar-1.png")!),
                        GitHubUser(name: GitHubUser.Name(text: "stargazer-2"), avatar: URL(string: "http://example.com/avatar-2.png")!),
                        GitHubUser(name: GitHubUser.Name(text: "stargazer-3"), avatar: URL(string: "http://example.com/avatar-3.png")!),
                    ],
                    error: nil
                )
            ),


            #line: TestCase(
                scenario: {
                    let repository = StargazerRepositoryStub(
                        firstResult: Promise(error: AnyError(debugInfo: "API call was failed"))
                    )

                    let model = StargazerModel(
                        for: self.repository,
                        fetchingVia: repository
                    )
                    self.waitUntilFetched(model)

                    return model
                },
                expected: .fetched(
                    stargazers: [],
                    error: .apiError(debugInfo: "\(AnyError(debugInfo: "API call was failed"))")
                )
            ),


            #line: TestCase(
                scenario: {
                    let repository = StargazerRepositoryStub(
                        firstResult: Promise(error: AnyError(debugInfo: "API call was failed"))
                    )

                    let model = StargazerModel(
                        for: self.repository,
                        fetchingVia: repository
                    )
                    self.waitUntilFetched(model)

                    repository.nextResult = Promise(value: [GitHubUser]())

                    model.fetch()
                    self.waitUntilFetched(model)

                    return model
                },
                expected: .fetched(
                    stargazers: [],
                    error: nil
                )
            ),


            #line: TestCase(
                scenario: {
                    let repository = StargazerRepositoryStub(
                        firstResult: Promise(value: [
                            GitHubUser(
                                name: GitHubUser.Name(text: "user-new"),
                                avatar: URL(string: "http://example.com/user-new.png")!
                            ),
                        ])
                    )

                    let model = StargazerModel(
                        for: self.repository,
                        fetchingVia: repository
                    )
                    self.waitUntilFetched(model)

                    repository.nextResult = Promise(value: [
                        GitHubUser(
                            name: GitHubUser.Name(text: "user-new"),
                            avatar: URL(string: "http://example.com/user-new.png")!
                        )
                    ])

                    model.fetch()
                    self.waitUntilFetching(model)
                    self.waitUntilFetched(model)

                    return model
                },
                expected: .fetched(
                    stargazers: [
                        GitHubUser(
                            name: GitHubUser.Name(text: "user-new"),
                            avatar: URL(string: "http://example.com/user-new.png")!
                        ),
                    ],
                    error: nil
                )
            ),
        ]


        testCases.forEach { (line, testCase) in
            let model = testCase.scenario()

            XCTAssert(
                Diffable.from(any: model.currentState) =~ Diffable.from(any: testCase.expected),
                diff(between: testCase.expected, and: model.currentState),
                line: line
            )
        }
    }



    private func waitUntilFetching(_ model: StargazerModel) {
        _ = try! model.didChange
            .filter { state in self.isFetching(state) }
            .take(1)
            .toBlocking()
            .last()
    }



    private func waitUntilFetched(_ model: StargazerModel) {
        _ = try! model.didChange
            .filter { state in self.isFetched(state) }
            .take(1)
            .toBlocking()
            .last()
    }



    private func isFetched(_ state: StargazerModelState) -> Bool {
        switch state {
        case .fetched:
            return true
        default:
            return false
        }
    }



    private func isFetching(_ state: StargazerModelState) -> Bool {
        switch state {
        case .fetching:
            return true
        default:
            return false
        }
    }


    private func createPendingRepository() -> StargazerRepositoryContract {
        return StargazerRepositoryStub(
            firstResult: Promise<[GitHubUser]>.pending().promise
        )
    }



    static var allTests : [(String, (StarredRepositoriesModelTests) -> () throws -> Void)] {
        return [
             ("testScenarios", self.testScenarios),
        ]
    }
}
