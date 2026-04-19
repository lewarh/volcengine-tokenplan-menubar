import AppKit
import CodingPlanKit
import Foundation

struct MenuBarPresentation: Equatable {
    let title: String
    let imageSystemName: String?
    let toolTip: String
}

enum PanelMode: Equatable {
    case dashboard
    case importCredentials
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var accounts: [StoredAccount] = []
    @Published var selectedAccountID: String? = nil
    @Published private(set) var snapshot: UsageSnapshot? = nil
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String? = nil
    @Published var importCurlText = ""
    @Published private(set) var importMessage: String? = nil
    @Published var panelMode: PanelMode = .dashboard
    @Published private(set) var menuBarPresentation = MenuBarPresentation(
        title: "导入",
        imageSystemName: "square.and.arrow.down",
        toolTip: "尚未导入账号"
    )

    private let store: AccountStore
    private let service: UsageService
    private var refreshTimer: Timer?

    init(store: AccountStore = AccountStore(), service: UsageService = UsageService()) {
        self.store = store
        self.service = service
    }

    func bootstrap() async {
        reloadAccounts()
        startAutoRefresh()
        if selectedAccountID != nil {
            panelMode = .dashboard
            await refresh()
        } else {
            errorMessage = nil
            importMessage = "导入 GetCodingPlanUsage 的 cURL 以开始。"
            panelMode = .importCredentials
            updatePresentation()
        }
    }

    func selectAccount(id: String?) async {
        selectedAccountID = id
        try? store.setSelectedAccount(id: id)
        await refresh()
    }

    func refresh() async {
        guard let account = selectedAccount else {
            snapshot = nil
            errorMessage = nil
            importMessage = "导入 GetCodingPlanUsage 的 cURL 以开始。"
            panelMode = .importCredentials
            updatePresentation()
            return
        }

        isRefreshing = true
        errorMessage = nil
        updatePresentation()

        do {
            let credentials = try store.loadCredentials(for: account.id)
            let latest = try await service.fetchUsage(credentials: credentials)
            snapshot = latest
            importMessage = nil
        } catch {
            if let codingPlanError = error as? CodingPlanError, codingPlanError == .missingImportedCredentials {
                snapshot = nil
                errorMessage = nil
                importMessage = codingPlanError.errorDescription
                panelMode = .importCredentials
                isRefreshing = false
                updatePresentation()
                return
            }
            snapshot = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isRefreshing = false
        reloadAccounts()
        updatePresentation()
    }

    func importFromText() async {
        let rawText = importCurlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawText.isEmpty else {
            importMessage = "请先粘贴完整 cURL。"
            return
        }

        do {
            let parsed = try CurlImportParser.parse(rawText)
            let savedAccount = try store.saveImportedAccount(parsed: parsed)
            reloadAccounts()
            selectedAccountID = savedAccount.id
            importMessage = "已保存账号“\(savedAccount.name)”，正在验证。"
            await refresh()
            if errorMessage == nil {
                importMessage = nil
                importCurlText = ""
                panelMode = .dashboard
            }
        } catch {
            importMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        updatePresentation()
    }

    func pasteFromClipboard() {
        importCurlText = NSPasteboard.general.string(forType: .string) ?? ""
    }

    func openConsolePage() {
        guard let url = URL(string: "https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?advancedActiveKey=subscribe") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func openImportPanel() {
        importMessage = nil
        panelMode = .importCredentials
    }

    func closeImportPanel() {
        if !accounts.isEmpty {
            panelMode = .dashboard
        }
    }

    func deleteSelectedAccount() {
        guard let selectedAccount else { return }

        do {
            let nextSelectedID = try store.deleteAccount(id: selectedAccount.id)
            selectedAccountID = nextSelectedID
            snapshot = nil
            errorMessage = nil
            reloadAccounts()

            if accounts.isEmpty {
                panelMode = .importCredentials
                importMessage = "已删除导入数据。请重新导入 GetCodingPlanUsage 的 cURL。"
            } else {
                panelMode = .dashboard
                importMessage = "已删除账号“\(selectedAccount.name)”。"
                Task { await refresh() }
            }
            updatePresentation()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    var selectedAccount: StoredAccount? {
        accounts.first { $0.id == selectedAccountID } ?? accounts.first
    }

    var credentialSummary: String {
        guard let account = selectedAccount, let expiry = account.credentialExpiresAt else {
            return "凭证有效期未知"
        }
        return "凭证剩余 \(FriendlyFormatting.remainingTime(until: expiry))"
    }

    var footerStatusLine: String {
        let updateText: String
        if let snapshot {
            updateText = "更新 \(FriendlyFormatting.formattedDate(snapshot.updatedAt))"
        } else {
            updateText = "尚未刷新"
        }
        return "\(credentialSummary) · \(updateText)"
    }

    var footerErrorLine: String? {
        errorMessage
    }

    private func reloadAccounts() {
        let loadedAccounts = (try? store.loadAccounts()) ?? []
        let storedSelectedID = (try? store.loadSelectedAccountID()) ?? nil
        accounts = loadedAccounts
        if let selectedAccountID, loadedAccounts.contains(where: { $0.id == selectedAccountID }) {
            self.selectedAccountID = selectedAccountID
        } else if let storedSelectedID, loadedAccounts.contains(where: { $0.id == storedSelectedID }) {
            selectedAccountID = storedSelectedID
        } else {
            selectedAccountID = loadedAccounts.first?.id
        }
    }

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    private func updatePresentation() {
        if accounts.isEmpty {
            menuBarPresentation = MenuBarPresentation(
                title: "导入",
                imageSystemName: "square.and.arrow.down",
                toolTip: "尚未配置 CodingPlan 账号"
            )
            return
        }

        if isRefreshing, snapshot == nil {
            menuBarPresentation = MenuBarPresentation(
                title: "...",
                imageSystemName: "arrow.clockwise",
                toolTip: "正在刷新用量"
            )
            return
        }

        if let errorMessage {
            menuBarPresentation = MenuBarPresentation(
                title: "错误",
                imageSystemName: "exclamationmark.triangle",
                toolTip: errorMessage
            )
            return
        }

        guard let snapshot, let account = selectedAccount else {
            menuBarPresentation = MenuBarPresentation(
                title: "待刷",
                imageSystemName: "chart.bar",
                toolTip: "请选择账号后刷新"
            )
            return
        }

        let menuQuota = snapshot.sessionQuota ?? snapshot.mostConstrainedQuota
        let title = menuQuota.map {
            "\(Int($0.remainingPercent.rounded()))%"
        } ?? "—"
        let quotaDescription = menuQuota.map {
            "5h limit 剩余 \(Int($0.remainingPercent.rounded()))%，\(FriendlyFormatting.remainingTime(until: $0.resetAt)) 后重置"
        } ?? "暂无配额信息"
        menuBarPresentation = MenuBarPresentation(
            title: title,
            imageSystemName: nil,
            toolTip: "\(account.name)：\(quotaDescription)"
        )
    }
}
