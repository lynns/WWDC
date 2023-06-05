//
//  TranscriptLanguagesProvider.swift
//  ConfCore
//
//  Created by Guilherme Rambo on 25/05/20.
//  Copyright © 2020 Guilherme Rambo. All rights reserved.
//

import Foundation
import RxSwift
import OSLog

public final class TranscriptLanguagesProvider: Logging {

    public static let log = makeLogger()

    let client: AppleAPIClient

    public init(client: AppleAPIClient = AppleAPIClient(environment: .current)) {
        self.client = client
    }

    public private(set) var availableLanguageCodes: BehaviorSubject<[TranscriptLanguage]> = BehaviorSubject(value: [])

    public func fetchAvailableLanguages() {
        log.debug("\(#function, privacy: .public)")

        client.fetchConfig { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let config):
                let languages = config.feeds.keys.compactMap(TranscriptLanguage.init)

                self.availableLanguageCodes.on(.next(languages))
            case .failure(let error):
                self.availableLanguageCodes.on(.error(error))
            }
        }
    }

}

public struct TranscriptLanguage: Hashable {
    public let name: String
    public let code: String

    public init?(code: String) {
        guard let name = Locale.current.localizedString(forLanguageCode: code) else {
            assertionFailure("Invalid language code \(code)")
            return nil
        }

        self.name = name
        self.code = code
    }
}
