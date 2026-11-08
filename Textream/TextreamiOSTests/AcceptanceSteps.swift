import AVFoundation
import CucumberSwift
import Speech
import XCTest
@testable import TextreamiOS

extension Cucumber: @retroactive StepImplementation {
    public var bundle: Bundle {
        class FeatureBundle {}
        return Bundle(for: FeatureBundle.self)
    }

    public func setupSteps() {
        var session: PromptSessionController?
        var defaults: UserDefaults?
        var suiteName: String?
        var authorizationBeforeStart: (
            AVAuthorizationStatus,
            AVAuthorizationStatus,
            SFSpeechRecognizerAuthorizationStatus
        )?

        BeforeScenario { _ in
            MainActor.assumeIsolated {
                session?.shutdown()
                if let defaults, let suiteName {
                    defaults.removePersistentDomain(forName: suiteName)
                }
                session = nil
                defaults = nil
                suiteName = nil
                authorizationBeforeStart = nil
            }
        }

        Given("the presenter is in Read mode with the camera disabled and Classic selected") { _, _ in
            MainActor.assumeIsolated {
                let newSuiteName = "Textream.CucumberAcceptance.\(UUID().uuidString)"
                let scenarioDefaults = UserDefaults(suiteName: newSuiteName)!
                defaults = scenarioDefaults
                suiteName = newSuiteName

                let presenter = AppModel(defaults: scenarioDefaults)
                presenter.script = "Welcome to the opening line."
                presenter.sessionMode = .read
                presenter.cameraEnabled = false
                presenter.followMode = .classic
                presenter.scrollSpeed = 0.5

                authorizationBeforeStart = (
                    AVCaptureDevice.authorizationStatus(for: .video),
                    AVCaptureDevice.authorizationStatus(for: .audio),
                    SFSpeechRecognizer.authorizationStatus()
                )
                let configuration = presenter.configuration()
                XCTAssertFalse(configuration.usesCamera)
                XCTAssertFalse(configuration.requiresAudioCapture)
                session = PromptSessionController(configuration: configuration)
            }
        }

        When("they start the prompt") { _, step in
            let expectation = XCTestExpectation(description: "prompt session prepares")
            let currentSession = MainActor.assumeIsolated { session }
            Task { @MainActor in
                await currentSession?.prepare()
                expectation.fulfill()
            }
            step.testCase?.wait(for: [expectation], timeout: 10)
        }

        Then("the prompt starts at the beginning of the script") { _, _ in
            MainActor.assumeIsolated {
                XCTAssertTrue(session?.isPrepared == true)
                XCTAssertTrue(session?.isPromptRunning == true)
                XCTAssertEqual(session?.prompt.text, "Welcome to the opening line.")
                XCTAssertEqual(session?.progress, 0)
            }
        }

        Then("camera, microphone, and speech access remain unrequested") { _, _ in
            MainActor.assumeIsolated {
                guard let authorizationBeforeStart else {
                    XCTFail("scenario did not capture authorization state before startup")
                    return
                }
                XCTAssertEqual(
                    AVCaptureDevice.authorizationStatus(for: .video),
                    authorizationBeforeStart.0
                )
                XCTAssertEqual(
                    AVCaptureDevice.authorizationStatus(for: .audio),
                    authorizationBeforeStart.1
                )
                XCTAssertEqual(
                    SFSpeechRecognizer.authorizationStatus(),
                    authorizationBeforeStart.2
                )
            }
        }

        AfterScenario { _ in
            MainActor.assumeIsolated {
                session?.shutdown()
                if let defaults, let suiteName {
                    defaults.removePersistentDomain(forName: suiteName)
                }
            }
        }
    }
}
