import SwiftUI

struct HandleEditorSheet: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private var cleanHandle: String {
        let stripped = inputText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
        // Remove non-alphanumeric except underscores
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return String(stripped.unicodeScalars.filter { allowed.contains($0) })
    }

    private var isValid: Bool {
        let h = cleanHandle
        return h.count >= 3 && h.count <= 20
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppTheme.gold, AppTheme.goldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 64, height: 64)
                            Text("👤").font(.system(size: 28))
                        }

                        Text(auth.displayName ?? "مستخدم")
                            .font(AppTheme.arabic(16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("@\(cleanHandle.isEmpty ? "..." : cleanHandle)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isValid ? AppTheme.gold : AppTheme.textDim)
                    }
                    .padding(.top, 20)

                    // Input field
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("اختر اسم المستخدم")
                            .font(AppTheme.arabic(13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        HStack(spacing: 8) {
                            TextField("username", text: $inputText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .focused($isFocused)
                                .environment(\.layoutDirection, .leftToRight)

                            Text("@")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.gold)
                        }
                        .padding(14)
                        .background(AppTheme.card)
                        .cornerRadius(AppTheme.radius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radius)
                                .stroke(isFocused ? AppTheme.gold : AppTheme.surface, lineWidth: 1)
                        )

                        // Validation hints
                        HStack {
                            if let error = errorMessage {
                                Text(error)
                                    .font(AppTheme.arabic(11))
                                    .foregroundColor(AppTheme.accent)
                            }
                            Spacer()
                            Text("\(cleanHandle.count)/20")
                                .font(.system(size: 11))
                                .foregroundColor(isValid ? AppTheme.textDim : AppTheme.accent)
                        }

                        Text("أحرف إنجليزية، أرقام، أو _ — من 3 إلى 20 حرف")
                            .font(AppTheme.arabic(11))
                            .foregroundColor(AppTheme.textDim)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button {
                        Task { await saveHandle() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(AppTheme.background)
                            } else {
                                Text("حفظ")
                                    .font(AppTheme.arabic(15, weight: .bold))
                            }
                        }
                        .foregroundColor(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? AppTheme.goldGradient : LinearGradient(colors: [AppTheme.textDim.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(AppTheme.radius)
                    }
                    .disabled(!isValid || isSaving)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("اسم المستخدم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                        .foregroundColor(AppTheme.gold)
                }
            }
            .onAppear {
                // Pre-fill current handle (strip @)
                let current = auth.handle ?? ""
                inputText = current.hasPrefix("@") ? String(current.dropFirst()) : current
                isFocused = true
            }
        }
    }

    private func saveHandle() async {
        errorMessage = nil
        isSaving = true
        let formatted = "@\(cleanHandle)"

        // Check uniqueness
        guard let uid = auth.userId else {
            isSaving = false
            return
        }
        let taken = await FirestoreService.shared.isHandleTaken(formatted, excludingUid: uid)
        if taken {
            errorMessage = "اسم المستخدم محجوز، جرّب غيره"
            isSaving = false
            return
        }

        await auth.updateHandle(cleanHandle)
        isSaving = false
        dismiss()
    }
}
