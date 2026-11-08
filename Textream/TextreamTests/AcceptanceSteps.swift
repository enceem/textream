import CucumberSwift
import Foundation
import XCTest
@testable import Textream

private struct NoOpRecentDocumentRegisterer: RecentDocumentRegistering {
    func register(_: URL) {}
}

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        class FeatureBundle {}
        return Bundle(for: FeatureBundle.self)
    }

    public func setupSteps() {
        var service: TextreamService?
        var directoryURL: URL?
        var expectedPages: [String] = []
        var lastDocumentURLBeforeScenario: String?

        BeforeScenario { _ in
            MainActor.assumeIsolated {
                lastDocumentURLBeforeScenario = UserDefaults.standard.string(forKey: "lastDocumentURL")
            }
        }

        Given("the presenter has a two-page script") { _, _ in
            MainActor.assumeIsolated {
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("TextreamAcceptance-\(UUID().uuidString)", isDirectory: true)
                do {
                    try FileManager.default.createDirectory(
                        at: directory,
                        withIntermediateDirectories: true
                    )
                } catch {
                    XCTFail("could not create an isolated script folder: \(error)")
                    return
                }

                let pages = ["Welcome to the opening line.", "The second page follows."]
                let presenter = service ?? TextreamService(
                    recentDocumentRegisterer: NoOpRecentDocumentRegisterer()
                )
                presenter.pages = pages
                presenter.savedPages = [""]
                presenter.currentPageIndex = 0
                presenter.readPages = []
                presenter.currentFileURL = directory.appendingPathComponent("presentation.textream")

                directoryURL = directory
                expectedPages = pages
                service = presenter
            }
        }

        When("they save and reopen the script") { _, _ in
            MainActor.assumeIsolated {
                guard let service, let currentFileURL = service.currentFileURL else {
                    XCTFail("scenario did not prepare a script file")
                    return
                }
                service.saveFile()
                service.pages = ["Temporary edit that must be replaced on reopen."]
                service.openFileAtURL(currentFileURL)
            }
        }

        Then("both page texts and their order are preserved") { _, _ in
            MainActor.assumeIsolated {
                XCTAssertEqual(service?.pages, expectedPages)
                XCTAssertEqual(service?.currentPageIndex, 0)
            }
        }

        AfterScenario { _ in
            MainActor.assumeIsolated {
                if let lastDocumentURLBeforeScenario {
                    UserDefaults.standard.set(lastDocumentURLBeforeScenario, forKey: "lastDocumentURL")
                } else {
                    UserDefaults.standard.removeObject(forKey: "lastDocumentURL")
                }
                service?.currentFileURL = nil
                service?.pages = [""]
                service?.savedPages = [""]
                service?.currentPageIndex = 0
                service?.readPages = []
                if let directoryURL {
                    try? FileManager.default.removeItem(at: directoryURL)
                }
                directoryURL = nil
                expectedPages = []
                lastDocumentURLBeforeScenario = nil
            }
        }
    }
}
