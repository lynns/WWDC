//
//  BookmarkSyncObject.swift
//  ConfCore
//
//  Created by Guilherme Rambo on 24/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import CloudKitCodable
import OSLog

public struct BookmarkSyncObject: CustomCloudKitCodable, BelongsToSession {
    public var cloudKitSystemFields: Data?
    public var cloudKitIdentifier: String
    public let sessionId: String?
    let createdAt: Date
    var modifiedAt: Date
    var body: String
    var timecode: Double
    var attributedBody: Data
    var snapshot: URL?
    var isDeleted: Bool
}

extension Bookmark: SyncObjectConvertible, BelongsToSession, Logging {
    public static let log = makeLogger(subsystem: "ConfCore", category: "\(String(describing: Bookmark.self))+Sync")

    public static var syncThrottlingInterval: TimeInterval {
        return 0
    }

    public typealias SyncObject = BookmarkSyncObject

    public var sessionId: String? {
        return session.first?.identifier
    }

    public static func from(syncObject: BookmarkSyncObject) -> Bookmark {
        let bookmark = Bookmark()

        bookmark.ckFields = syncObject.cloudKitSystemFields ?? Data()
        bookmark.identifier = syncObject.cloudKitIdentifier
        bookmark.createdAt = syncObject.createdAt
        bookmark.modifiedAt = syncObject.modifiedAt
        bookmark.body = syncObject.body
        bookmark.timecode = syncObject.timecode
        bookmark.attributedBody = syncObject.attributedBody
        bookmark.isDeleted = syncObject.isDeleted

        if let snapshotURL = syncObject.snapshot {
            do {
                bookmark.snapshot = try Data(contentsOf: snapshotURL)
            } catch {
                log.fault("Failed to load bookmark snapshot from CloudKit: \(String(describing: error), privacy: .public)")
                bookmark.snapshot = Data()
            }
        } else {
            bookmark.snapshot = Data()
        }

        return bookmark
    }

    public var syncObject: BookmarkSyncObject? {
        guard let sessionId = session.first?.identifier else {
            log.fault("Bookmark \(self.identifier) is not associated to a session. That's illegal!")

            return nil
        }

        let snapshotURL = try? snapshot.writeToTempLocationForCloudKitUpload()

        return BookmarkSyncObject(cloudKitSystemFields: ckFields.isEmpty ? nil : ckFields,
                                  cloudKitIdentifier: identifier,
                                  sessionId: sessionId,
                                  createdAt: createdAt,
                                  modifiedAt: modifiedAt,
                                  body: body,
                                  timecode: timecode,
                                  attributedBody: attributedBody,
                                  snapshot: snapshotURL,
                                  isDeleted: isDeleted)
    }

}
