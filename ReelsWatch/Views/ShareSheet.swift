import SwiftUI

/// DM방을 골라 현재 릴스를 보낸다. 대화 기능은 없다.
struct ShareSheet: View {
    let model: ReelsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<DMThread.ID> = []
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Group {
                if !model.threadsLoaded {
                    ProgressView()
                } else if model.threads.isEmpty {
                    Text("대화방이 없어요")
                } else {
                    List(model.threads) { thread in
                        Button { toggle(thread) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: thread.isGroup ? "person.2.fill" : "person.fill")
                                    .frame(width: 24)
                                Text(thread.title).lineLimit(1)
                                Spacer()
                                Image(systemName: selected.contains(thread.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(thread.id) ? Color.accentColor : Color.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("보내기")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(selected.isEmpty ? "보내기" : "보내기 \(selected.count)") {
                        send()
                    }
                    .disabled(selected.isEmpty || isSending)
                }
            }
        }
        .task { await model.loadThreadsIfNeeded() }
    }

    private func toggle(_ thread: DMThread) {
        if selected.contains(thread.id) {
            selected.remove(thread.id)
        } else {
            selected.insert(thread.id)
        }
    }

    private func send() {
        isSending = true
        Task {
            let ok = await model.shareCurrentReel(to: selected)
            isSending = false
            if ok {
                Haptics.success()
                dismiss()
            } else {
                Haptics.failure()
            }
        }
    }
}
