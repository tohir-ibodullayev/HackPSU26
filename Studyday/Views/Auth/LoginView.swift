import SwiftUI

/// Welcome / login matching the Studyday MHTML mockup layout and copy.
struct LoginView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var appear = false
    @State private var showProviders = false

    var body: some View {
        ZStack {
            StudydayBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 26)
                    .padding(.top, 18)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero
                            .padding(.top, 36)
                        if showProviders {
                            providerStack
                                .padding(.top, 28)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            ctaStack
                                .padding(.top, 28)
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                appear = true
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("CampusMate")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(StudydayTheme.ink)
                    .tracking(-0.4)
                Text("·")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(StudydayTheme.accent)
            }
            Spacer()
            Text("YOUR CAMPUS BUDDY")
                .font(.system(size: 7, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(StudydayTheme.sage)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(StudydayTheme.badgeBorder, lineWidth: 1)
                )
        }
        .opacity(appear ? 1 : 0)
    }

    private var hero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: StudydayTheme.cornerIcon, style: .continuous)
                    .fill(StudydayTheme.paperElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: StudydayTheme.cornerIcon, style: .continuous)
                            .stroke(StudydayTheme.borderSoft, lineWidth: 1)
                    )
                    .frame(width: 76, height: 76)
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(StudydayTheme.ink)
                    )

                Circle()
                    .fill(StudydayTheme.accent)
                    .frame(width: 14, height: 14)
                    .offset(x: 3, y: -3)
            }
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)

            VStack(spacing: 15) {
                Text("Your semester.\nA little lighter.")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .tracking(-0.6)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StudydayTheme.ink)
                    .lineSpacing(2)

                Text("A buddy for your goals, study days,\nand everything in between.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StudydayTheme.muted)
                    .lineSpacing(3)
            }
            .padding(.top, 28)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)

            previewCard
                .padding(.top, 28)
                .opacity(appear ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                .fill(StudydayTheme.mistDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                        .stroke(StudydayTheme.border, lineWidth: 1)
                )
                .rotationEffect(.degrees(-5))
                .offset(y: 8)
                .padding(.horizontal, 7)

            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(StudydayTheme.mist)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(StudydayTheme.iconBlue)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("A buddy in your corner")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(StudydayTheme.ink)
                    Text("Your college journey, together")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(StudydayTheme.muted)
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(StudydayTheme.softGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                    .fill(StudydayTheme.paperElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: StudydayTheme.cornerCard, style: .continuous)
                            .stroke(StudydayTheme.border, lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: 340)
        .frame(height: 88)
    }

    private var ctaStack: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    showProviders = true
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Get started")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 58)
                .background(
                    RoundedRectangle(cornerRadius: StudydayTheme.corner, style: .continuous)
                        .fill(StudydayTheme.accent)
                )
            }
            .buttonStyle(.plain)

            Button {
                appModel.beginDemo()
            } label: {
                Text("Try the demo")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(StudydayTheme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 58)
                    .background(
                        RoundedRectangle(cornerRadius: StudydayTheme.corner, style: .continuous)
                            .fill(StudydayTheme.chipFill)
                    )
            }
            .buttonStyle(.plain)
            .disabled(appModel.isAuthenticating)

            if appModel.isAuthenticating {
                ProgressView()
                    .tint(StudydayTheme.ink)
            }

            if let authError = appModel.authError {
                Text(authError)
                    .font(.footnote)
                    .foregroundStyle(StudydayTheme.danger)
            }

            Text("A little structure. More room to breathe.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(StudydayTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }

    private var providerStack: some View {
        VStack(spacing: 16) {
            AccountForm()
            Button("Back") { showProviders = false }
                .foregroundStyle(StudydayTheme.muted)
        }
    }
}

private struct AccountForm: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var creating = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var error: String?
    @State private var recovery: String?
    private var validEmail: Bool {
        let parts = email.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !email.contains(where: { $0.isWhitespace })
    }
    var body: some View {
        VStack(spacing: 14) {
            Picker("Account", selection: $creating) {
                Text("Sign up").tag(true)
                Text("Log in").tag(false)
            }.pickerStyle(.segmented)
            Text(creating ? "Make room for a lighter semester." : "Good to see you again.")
                .font(.headline)
            if creating {
                TextField("Your name", text: $name).textContentType(.name)
            }
            TextField("Email address", text: $email)
                .keyboardType(.emailAddress).textContentType(.emailAddress)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            SecureField("Password", text: $password)
                .textContentType(creating ? .newPassword : .password)
            if creating {
                SecureField("Confirm password", text: $confirmation).textContentType(.newPassword)
            }
            if let error = error ?? appModel.authError {
                Text(error).font(.footnote).foregroundStyle(StudydayTheme.danger)
                    .accessibilityIdentifier("authError")
            }
            Button {
                error = nil; appModel.authError = nil
                guard validEmail else { error = "Enter a valid email address."; return }
                guard !creating || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "Enter your name."; return }
                guard password.count >= (creating ? 8 : 1) else { error = "Use at least 8 characters for your password."; return }
                guard !creating || confirmation == password else { error = "Passwords don’t match."; return }
                Task {
                    await appModel.authenticate(name: name, email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password, creating: creating)
                    password = ""; confirmation = ""
                }
            } label: {
                HStack {
                    if appModel.isAuthenticating { ProgressView().tint(.white) }
                    Text(creating ? "Create account" : "Log in")
                }.frame(maxWidth: .infinity).padding(16)
                    .foregroundStyle(.white).background(StudydayTheme.accent, in: RoundedRectangle(cornerRadius: 18))
            }.disabled(appModel.isAuthenticating)
            if !creating {
                Button("Forgot password?") {
                    guard validEmail else { error = "Enter your email address first."; return }
                    Task { recovery = await appModel.resetPassword(email: email) }
                }
            }
            if let recovery { Text(recovery).font(.footnote).foregroundStyle(StudydayTheme.muted) }
            Text("Account services aren’t connected yet. No real account will be created. Passwords are never saved by this prototype.")
                .font(.caption).foregroundStyle(StudydayTheme.muted)
            Button("Try the demo instead") { password = ""; confirmation = ""; appModel.beginDemo() }
                .fontWeight(.semibold)
        }
        .textFieldStyle(.roundedBorder)
        .padding(18)
        .background(StudydayTheme.paperElevated, in: RoundedRectangle(cornerRadius: 22))
        .onChange(of: creating) { _, _ in error = nil; appModel.authError = nil; recovery = nil; password = ""; confirmation = "" }
    }
}
