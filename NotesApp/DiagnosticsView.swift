import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DiagnosticsView: View {
    let ephePath: String
    let fileCount: Int
    let samples: [String]
    let logs: [String]
    @State private var showCopiedAlert: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Swiss Ephemeris")) {
                    HStack { Text("Path"); Spacer(); Text(ephePath).foregroundColor(.secondary).multilineTextAlignment(.trailing) }
                    HStack { Text("Files"); Spacer(); Text("\(fileCount)").foregroundColor(.secondary) }
                    if !samples.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Samples").font(.subheadline)
                            ForEach(samples, id: \.self) { s in Text(s).font(.caption).foregroundColor(.secondary) }
                        }
                    }
                }

                Section(header: Text("Logs")) {
                    if logs.isEmpty {
                        Text("No logs yet").foregroundColor(.secondary)
                    } else {
                        ForEach(Array(logs.suffix(100).enumerated()), id: \.0) { _, line in
                            Text(line).font(.caption).textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Copy Logs") { copyLogs() }
                }
            }
            .alert("Copied", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Diagnostics text copied to clipboard")
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private func copyLogs() {
        var lines: [String] = []
        lines.append("Swiss Ephemeris Path: \(ephePath)")
        lines.append("File Count: \(fileCount)")
        if !samples.isEmpty {
            lines.append("Samples: \(samples.joined(separator: ", "))")
        }
        if logs.isEmpty {
            lines.append("Logs: (none)")
        } else {
            lines.append("Logs:")
            lines.append(contentsOf: logs)
        }
        let payload = lines.joined(separator: "\n")
        #if canImport(UIKit)
        UIPasteboard.general.string = payload
        #endif
        showCopiedAlert = true
    }
}
