import Foundation
import PromiseKit
@testable import TestableDesignExample



struct GitHubApiClientStub: GitHubApiClientContract {
    var nextResult: Promise<Any>


    init(firstResult: Promise<Any>) {
        self.nextResult = firstResult
    }


    func fetch(endpoint: GitHubApiEndpoint, headers: [String: String], parameters: [(String, String)]) -> Promise<Data> {
        return self.nextResult
            .then { any -> Data in
                return try JSONSerialization.data(
                    withJSONObject: any,
                    options: [JSONSerialization.WritingOptions.prettyPrinted]
                )
            }
    }


    static let anyPending = GitHubApiClientStub(firstResult: Promise<Any>.pending().promise)
}
