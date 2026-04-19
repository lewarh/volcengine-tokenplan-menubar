import AppKit
import CodingPlanKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState
    @State private var isShowingRefreshHint = false

    var body: some View {
        Group {
            switch appState.panelMode {
            case .dashboard:
                dashboardPanel
            case .importCredentials:
                importPanel
            }
        }
        .padding(.top, 4)
        .padding(.leading, 0)
        .padding(.trailing, 0)
        .padding(.bottom, 6)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var dashboardPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            compactQuotaSection
            Divider()
                .overlay(Color.secondary.opacity(0.08))
                .padding(.horizontal, 12)
            footerSection
        }
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("重新导入 cURL")
                        .font(.headline)
                    Text("直接粘贴 `GetCodingPlanUsage` 的 cURL，应用会自动解析用户名。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !appState.accounts.isEmpty {
                    Button("返回") {
                        appState.closeImportPanel()
                    }
                    .buttonStyle(.bordered)
                }
            }

            TextEditor(text: $appState.importCurlText)
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 220)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
                )

            if let errorMessage = appState.errorMessage, appState.importMessage == nil {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let importMessage = appState.importMessage {
                Text(importMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if appState.selectedAccount != nil {
                    Button(role: .destructive) {
                        appState.deleteSelectedAccount()
                    } label: {
                        Label("删除当前账号", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    appState.pasteFromClipboard()
                } label: {
                    Label("粘贴剪贴板", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    appState.openConsolePage()
                } label: {
                    Label("获取 cURL", systemImage: "safari")
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await appState.importFromText() }
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    appState.quitApp()
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("退出应用")
            }
        }
    }

    private var compactQuotaSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let snapshot = appState.snapshot, !snapshot.quotas.isEmpty {
                ForEach(snapshot.quotas) { quota in
                    CompactQuotaRow(quota: quota)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("没有可展示的配额数据")
                        .font(.subheadline.weight(.medium))
                    Text("先导入 cURL，再刷新即可展示 5h、week、all 三档配额。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let footerErrorLine = appState.footerErrorLine {
                Text(footerErrorLine)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text(appState.footerStatusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                accountMenu

                Button {
                    Task { await appState.refresh() }
                } label: {
                    Label(appState.isRefreshing ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.accounts.isEmpty || appState.isRefreshing)

                Button {
                    isShowingRefreshHint.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("每 8 分钟自动刷新。打开或悬停菜单栏图标时，30 秒内最多触发一次刷新。")
                .popover(isPresented: $isShowingRefreshHint, arrowEdge: .bottom) {
                    Text("每 8 分钟自动刷新。\n打开或悬停菜单栏图标时，30 秒内最多触发一次刷新。")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .padding(10)
                        .frame(width: 220, alignment: .leading)
                }

                Button {
                    appState.openImportPanel()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .help("重新导入")

                Spacer()

                if let statusBadgeText {
                    Text(statusBadgeText)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                }

                Button {
                    appState.openConsolePage()
                } label: {
                    Image(systemName: "safari")
                }
                .buttonStyle(.borderless)
                .help("打开控制台")

                Button {
                    appState.quitApp()
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("退出应用")
            }
        }
        .padding(.top, 2)
        .padding(.horizontal, 12)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var accountMenu: some View {
        Menu {
            ForEach(appState.accounts) { account in
                Button(account.name) {
                    Task { await appState.selectAccount(id: account.id) }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(appState.selectedAccount?.name ?? "未配置账号")
                    .lineLimit(1)
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.09))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var statusBadgeText: String? {
        if appState.isRefreshing {
            return "刷新中"
        } else if let snapshot = appState.snapshot {
            return snapshot.status == .running ? nil : snapshot.status.displayName
        } else if appState.accounts.isEmpty {
            return "待导入"
        } else {
            return "待刷新"
        }
    }
}

private struct CompactQuotaRow: View {
    let quota: QuotaSnapshot

    private let rightMetricWidth: CGFloat = 86
    private let durationWidth: CGFloat = 118

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(quota.level.compactTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                HStack(spacing: 4) {
                    Text("剩余")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(quota.remainingPercent.rounded()))%")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(quota.remainingPercent < 20 ? .red : .primary)
                }
                .frame(width: rightMetricWidth, alignment: .trailing)
            }

            MetricBar(
                title: "已用",
                percent: quota.usedPercent,
                alignment: .leading,
                tint: progressColor,
                valueWidth: rightMetricWidth
            )

            if quota.level == .session {
                MetricBar(
                    title: "重置",
                    percent: quota.resetRemainingPercent(),
                    alignment: .trailing,
                    tint: .secondary,
                    valueWidth: rightMetricWidth
                )

                HStack {
                    HStack(spacing: 6) {
                        Text("已用 \(quota.usedPercent.formatted(.number.precision(.fractionLength(1))))%")
                        DotDivider()
                        Text(FriendlyFormatting.formattedDate(quota.resetAt))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                    Text(FriendlyFormatting.remainingTime(until: quota.resetAt))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: durationWidth, alignment: .trailing)
                }
            } else {
                MetricBar(
                    title: "重置",
                    percent: quota.resetRemainingPercent(),
                    alignment: .trailing,
                    tint: .secondary,
                    valueWidth: rightMetricWidth,
                    trailingText: FriendlyFormatting.remainingTime(until: quota.resetAt)
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var progressColor: Color {
        switch quota.usedPercent {
        case 90...: return .red
        case 70...: return .orange
        default: return .accentColor
        }
    }
}

private struct MetricBar: View {
    let title: String
    let percent: Double
    let alignment: Alignment
    let tint: Color
    let valueWidth: CGFloat
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)

            GeometryReader { proxy in
                let width = max(0, proxy.size.width)
                let fillWidth = width * max(0, min(percent, 100)) / 100

                ZStack(alignment: alignment) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.14))
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: fillWidth)
                }
            }
            .frame(height: 6)

            Text(trailingText ?? "\(Int(percent.rounded()))%")
                .font(.caption2.monospacedDigit())
                .frame(width: valueWidth, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DotDivider: View {
    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 3, height: 3)
    }
}
