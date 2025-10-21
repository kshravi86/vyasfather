import SwiftUI

struct DiagnosticsView: View {
    let ephePath: String
    let fileCount: Int
    let samples: [String]
    let logs: [String]

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
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

