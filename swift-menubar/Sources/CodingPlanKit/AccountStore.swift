import Foundation

public final class AccountStore {
    private struct StoredAccountRecord: Codable {
        let account: StoredAccount
        let credentials: AccountCredentials
    }

    private struct FileState: Codable {
        let accounts: [StoredAccountRecord]
        let selectedAccountID: String?
    }

    private struct LegacyState: Codable {
        let accounts: [StoredAccount]
        let selectedAccountID: String?
    }

    private let fileManager: FileManager
    private let stateURL: URL

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = (appSupport ?? URL(fileURLWithPath: NSHomeDirectory()))
            .appendingPathComponent("CodingPlanMenuBar", isDirectory: true)
        if !fileManager.fileExists(atPath: root.path) {
            try? fileManager.createDirectory(
                at: root,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
        self.stateURL = root.appendingPathComponent("accounts.json")
        ensurePrivateDirectoryPermissionsIfPossible(at: root)
    }

    public func loadAccounts() throws -> [StoredAccount] {
        try loadState().accounts.map(\.account)
    }

    public func loadSelectedAccountID() throws -> String? {
        try loadState().selectedAccountID
    }

    public func loadCredentials(for accountID: String) throws -> AccountCredentials {
        guard let record = try loadState().accounts.first(where: { $0.account.id == accountID }) else {
            throw CodingPlanError.missingImportedCredentials
        }
        guard record.credentials.isComplete else {
            throw CodingPlanError.missingImportedCredentials
        }
        return record.credentials
    }

    public func saveImportedAccount(parsed: ParsedCurlImport) throws -> StoredAccount {
        let currentState = try loadState()
        let now = Date()
        let resolvedName = if let username = parsed.jwtPayload?.name, !username.isEmpty {
            username
        } else {
            "账号\(currentState.accounts.count + 1)"
        }

        let existing = currentState.accounts.first { $0.account.name == resolvedName }
        let account = StoredAccount(
            id: existing?.account.id ?? UUID().uuidString,
            name: resolvedName,
            username: parsed.jwtPayload?.name,
            credentialExpiresAt: parsed.jwtPayload?.exp.map { Date(timeIntervalSince1970: $0) },
            createdAt: existing?.account.createdAt ?? now,
            updatedAt: now
        )
        let record = StoredAccountRecord(account: account, credentials: parsed.credentials)

        let remainingRecords = currentState.accounts.filter { $0.account.id != account.id }
        let updatedRecords = (remainingRecords + [record]).sorted { lhs, rhs in
            lhs.account.updatedAt > rhs.account.updatedAt
        }
        let updatedState = FileState(accounts: updatedRecords, selectedAccountID: account.id)
        try persistState(updatedState)
        return account
    }

    public func deleteAccount(id: String) throws -> String? {
        let currentState = try loadState()
        let remainingRecords = currentState.accounts.filter { $0.account.id != id }
        let nextSelectedID = if currentState.selectedAccountID == id {
            remainingRecords.first?.account.id
        } else {
            currentState.selectedAccountID
        }

        let updatedState = FileState(accounts: remainingRecords, selectedAccountID: nextSelectedID)
        try persistState(updatedState)
        return nextSelectedID
    }

    public func setSelectedAccount(id: String?) throws {
        let currentState = try loadState()
        let updatedState = FileState(accounts: currentState.accounts, selectedAccountID: id)
        try persistState(updatedState)
    }

    private func loadState() throws -> FileState {
        guard fileManager.fileExists(atPath: stateURL.path) else {
            return FileState(accounts: [], selectedAccountID: nil)
        }

        let data = try Data(contentsOf: stateURL)
        if let state = try? JSONDecoder().decode(FileState.self, from: data) {
            return state
        }

        if (try? JSONDecoder().decode(LegacyState.self, from: data)) != nil {
            return FileState(
                accounts: [],
                selectedAccountID: nil
            )
        }

        throw CodingPlanError.network("本地账号配置损坏，请重新导入。")
    }

    private func persistState(_ state: FileState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        do {
            try data.write(to: stateURL, options: .atomic)
        } catch {
            throw CodingPlanError.network("保存本地账号配置失败：\(error.localizedDescription)")
        }
        ensurePrivateDirectoryPermissionsIfPossible(at: stateURL.deletingLastPathComponent())
        ensurePrivateFilePermissionsIfPossible(at: stateURL)
    }

    private func ensurePrivateDirectoryPermissionsIfPossible(at url: URL) {
        try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    private func ensurePrivateFilePermissionsIfPossible(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
