import SwiftUI
import Onde

enum ExampleDefaults {
    static let systemPrompt = "You are a helpful on-device assistant. Be concise, practical, and truthful."

    static let promptSuggestions: [PromptSuggestion] = [
        PromptSuggestion(
            title: "Explain Onde",
            prompt: "In simple terms, what is Onde Inference and when would I use it in an iOS app?"
        ),
        PromptSuggestion(
            title: "SwiftUI idea",
            prompt: "Give me three ideas for an on-device AI feature in a SwiftUI app."
        ),
        PromptSuggestion(
            title: "Debugging help",
            prompt: "What are the first things to check when a local iOS ML model fails to load?"
        ),
        PromptSuggestion(
            title: "Prompt writing",
            prompt: "Write a strong system prompt for an iOS coding assistant focused on SwiftUI."
        )
    ]
}

struct PromptSuggestion: Identifiable, Hashable {
    let title: String
    let prompt: String

    var id: String { title }
}

enum SamplingPreset: String, CaseIterable, Identifiable {
    case balanced
    case deterministic
    case mobile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .deterministic:
            return "Deterministic"
        case .mobile:
            return "Fast / Mobile"
        }
    }

    var subtitle: String {
        switch self {
        case .balanced:
            return "General-purpose responses with a bit of creativity."
        case .deterministic:
            return "Best for reproducible, focused coding and analysis tasks."
        case .mobile:
            return "Shorter responses with lower latency on constrained devices."
        }
    }

    var samplingConfig: SamplingConfig {
        switch self {
        case .balanced:
            return defaultSamplingConfig()
        case .deterministic:
            return deterministicSamplingConfig()
        case .mobile:
            return mobileSamplingConfig()
        }
    }
}

struct ModelSettingsSheet: View {
    let initialSystemPrompt: String
    let initialSamplingPreset: SamplingPreset
    let onSave: (String, SamplingPreset) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var systemPrompt: String
    @State private var samplingPreset: SamplingPreset

    init(
        systemPrompt: String,
        samplingPreset: SamplingPreset,
        onSave: @escaping (String, SamplingPreset) -> Void
    ) {
        self.initialSystemPrompt = systemPrompt
        self.initialSamplingPreset = samplingPreset
        self.onSave = onSave
        _systemPrompt = State(initialValue: systemPrompt)
        _samplingPreset = State(initialValue: samplingPreset)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 140)
                } header: {
                    Text("System Prompt")
                } footer: {
                    Text("This prompt applies to future generations. Leave it blank to clear the runtime system prompt.")
                }

                Section("Response Style") {
                    Picker("Sampling Preset", selection: $samplingPreset) {
                        ForEach(SamplingPreset.allCases) { preset in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                Text(preset.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(preset)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Current Configuration") {
                    LabeledContent("System prompt") {
                        Text(initialSystemPrompt.isEmpty ? "None" : "Custom")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Sampling preset") {
                        Text(initialSamplingPreset.title)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Model Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(systemPrompt, samplingPreset)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
