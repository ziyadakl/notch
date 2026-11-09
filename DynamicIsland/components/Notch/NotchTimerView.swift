/*
 * Atoll (DynamicIsland)
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI
import Defaults
#if canImport(AppKit)
import AppKit
#endif

struct NotchTimerView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    @Default(.enableTimerFeature) var enableTimerFeature
    @Default(.enableMinimalisticUI) private var enableMinimalisticUI
    @Default(.timerPresets) private var timerPresets
    @Default(.timerIconColorMode) private var colorMode
    @Default(.timerSolidColor) private var solidColor
    @Default(.timerShowsProgress) private var showsProgress
    @Default(.timerProgressStyle) private var progressStyle
    @Default(.showTimerPresetsInNotchTab) private var showTimerPresetsInNotchTab
    @Default(.timerInputStyle) private var timerInputStyle

    /// The custom length, in seconds. The single source of truth for both input styles.
    @AppStorage("customTimerDuration") private var customTimerDuration: Double = 600
    // The ruler picker edits hours, minutes and seconds; these mirror customTimerDuration.
    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 10
    @State private var customSeconds: Int = 0
    @State private var isSyncingCustomDuration = false
    @State private var lockedAccentColor: Color?

    var body: some View {
        Group {
            if enableTimerFeature {
                Group {
                    if timerManager.isTimerActive {
                        activeTimer
                    } else {
                        idleTimer
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: maxTabContentHeight)
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .blurReplace))
                .onAppear { syncCustomDuration(with: customTimerDuration) }
                .onChange(of: customTimerDuration) { _, newValue in syncCustomDuration(with: newValue) }
                .onChange(of: customHours) { _, _ in updateStoredCustomDuration() }
                .onChange(of: customMinutes) { _, _ in updateStoredCustomDuration() }
                .onChange(of: customSeconds) { _, _ in updateStoredCustomDuration() }
            } else {
                disabledState
            }
        }
        .onAppear {
            lockAccentColorIfNeeded()
        }
        .onChange(of: timerManager.isTimerActive) { _, isActive in
            if isActive {
                lockAccentColorIfNeeded()
            } else {
                lockedAccentColor = nil
            }
        }
        .onChange(of: timerManager.activePresetId) { _, _ in
            if timerManager.isTimerActive && lockedAccentColor == nil {
                lockAccentColorIfNeeded()
            }
        }
    }

    // MARK: - Idle: set a length, or pick a preset

    private var idleTimer: some View {
        HStack(alignment: .center, spacing: 24) {
            composer
                .frame(maxWidth: .infinity, alignment: .leading)
            if showTimerPresetsInNotchTab && !timerPresets.isEmpty {
                presetList
            }
        }
    }

    @ViewBuilder
    private var composer: some View {
        if timerInputStyle == .ruler {
            RulerTimerPicker(
                hours: $customHours,
                minutes: $customMinutes,
                seconds: $customSeconds,
                tintColor: timerAccentColor,
                startAction: startCustomTimer
            )
        } else {
            HStack(spacing: 10) {
                NotchDurationField(duration: $customTimerDuration, onSubmit: startCustomTimer)
                NotchRoundButton(
                    icon: "play.fill",
                    label: String(localized: "Start"),
                    isPrimary: true,
                    action: startCustomTimer
                )
                .disabled(customTimerDuration <= 0)
            }
        }
    }

    /// Sits centred beside the clock when it fits; scrolls when there are more presets than room.
    private var presetList: some View {
        let rows = VStack(spacing: 2) {
            ForEach(timerPresets) { preset in
                NotchPresetRow(preset: preset) { start(preset) }
            }
        }
        return ViewThatFits(in: .vertical) {
            rows
            ScrollView { rows }
                .scrollIndicators(.never)
        }
        .frame(width: 200)
        .frame(maxHeight: maxTabContentHeight)
    }

    // MARK: - Running: controls, name, time left

    private var activeTimer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                if timerManager.allowsManualInteraction {
                    controls
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timerDisplayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let status = timerStatusText {
                        Text(status)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(timerManager.isOvertime ? Color.red : Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdown
            }

            if showsProgress && progressStyle == .bar {
                progressBar
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 8) {
            if timerManager.isOvertime {
                NotchRoundButton(icon: "stop.fill", label: String(localized: "Stop"), action: stopTimerAction)
            } else {
                NotchRoundButton(
                    icon: timerManager.isPaused ? "play.fill" : "pause.fill",
                    label: timerManager.isPaused ? String(localized: "Resume") : String(localized: "Pause"),
                    action: togglePauseAction
                )
                NotchRoundButton(icon: "xmark", label: String(localized: "Cancel"), action: stopTimerAction)
            }
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if showsProgress && progressStyle == .ring {
            TimerProgressRing(
                progress: timerManager.progress,
                tint: timerAccentColor,
                timeText: timerManager.formattedRemainingTime(),
                isOvertime: timerManager.isOvertime,
                remainingTime: timerManager.remainingTime
            )
        } else {
            Text(timerManager.formattedRemainingTime())
                .font(.system(size: 34, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(timerManager.isOvertime ? Color.red : .white)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.25), value: timerManager.remainingTime)
                .lineLimit(1)
        }
    }

    private var progressBar: some View {
        Capsule()
            .fill(Color.white.opacity(0.12))
            .frame(height: 3)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(timerAccentColor)
                    .scaleEffect(x: normalizedProgress, y: 1, anchor: .leading)
                    .animation(.smooth(duration: 0.25), value: timerManager.progress)
            }
    }

    private var disabledState: some View {
        Label(String(localized: "Timer is off"), systemImage: "timer.slash")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func start(_ preset: TimerPreset) {
        timerManager.startTimer(duration: preset.duration, name: preset.name, preset: preset)
        if !enableMinimalisticUI {
            coordinator.currentView = .timer
        }
    }

    private func startCustomTimer() {
        guard customTimerDuration > 0 else { return }
        withAnimation(.smooth) {
            timerManager.startTimer(duration: customTimerDuration, name: String(localized: "Custom Timer"))
            if !enableMinimalisticUI {
                coordinator.currentView = .timer
            }
        }
    }

    private func togglePauseAction() {
        guard timerManager.allowsManualInteraction else { return }
        timerManager.isPaused ? timerManager.resumeTimer() : timerManager.pauseTimer()
    }

    private func stopTimerAction() {
        if timerManager.allowsManualInteraction {
            timerManager.stopTimer()
        } else {
            timerManager.endExternalTimer(triggerSmoothClose: false)
        }
    }

    private func syncCustomDuration(with value: Double) {
        isSyncingCustomDuration = true
        let components = TimerPreset.components(for: value)
        customHours = components.hours
        customMinutes = components.minutes
        customSeconds = components.seconds
        isSyncingCustomDuration = false
    }

    private func updateStoredCustomDuration() {
        guard !isSyncingCustomDuration else { return }
        customTimerDuration = TimeInterval(customHours * 3600 + customMinutes * 60 + customSeconds)
    }

    // MARK: - Derived values

    private var resolvedNotchHeight: CGFloat {
        let height = vm.notchSize.height
        return height > 0 ? height : openNotchSize.height
    }

    private var headerHeight: CGFloat {
        max(24, vm.effectiveClosedNotchHeight)
    }

    private var maxTabContentHeight: CGFloat {
        max(100, resolvedNotchHeight - headerHeight - 36)
    }

    private func lockAccentColorIfNeeded() {
        if timerManager.isTimerActive {
            lockedAccentColor = resolvedAccentColor
        }
    }

    private var timerAccentColor: Color {
        lockedAccentColor ?? resolvedAccentColor
    }

    private var resolvedAccentColor: Color {
        switch colorMode {
        case .adaptive:
            return timerManager.activePreset?.color ?? timerManager.timerColor
        case .solid:
            return solidColor
        }
    }

    private var normalizedProgress: CGFloat {
        CGFloat(max(0, min(timerManager.progress, 1)))
    }

    private var timerDisplayName: String {
        timerManager.timerName.isEmpty ? String(localized: "Timer") : timerManager.timerName
    }

    private var timerStatusText: String? {
        if timerManager.isOvertime {
            return String(localized: "Overtime")
        } else if timerManager.isPaused {
            return String(localized: "Paused")
        } else if timerManager.isFinished {
            return String(localized: "Completed")
        }
        return nil
    }
}

// MARK: - Pieces

/// A 28 pt round icon button. The primary one is white with a dark glyph; the rest are a quiet grey.
private struct NotchRoundButton: View {
    let icon: String
    let label: String
    var isPrimary = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isPrimary ? Color.black : Color.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(fill))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .opacity(isEnabled ? 1 : 0.35)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovering = $0 }
    }

    private var fill: Color {
        if isPrimary { return .white.opacity(isHovering ? 1 : 0.9) }
        return .white.opacity(isHovering ? 0.2 : 0.12)
    }
}

/// The custom length as one editable clock. Type "25", "1:30:00" or "1h 30"; Return starts it;
/// the up and down arrows add or take a minute.
private struct NotchDurationField: View {
    @Binding var duration: Double
    let onSubmit: () -> Void

    @State private var text = ""
    @State private var isHovering = false
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("0:00", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 34, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.white)
            .tint(.white)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(isFocused ? 0.1 : (isHovering ? 0.06 : 0)))
            )
            .focused($isFocused)
            .onHover { isHovering = $0 }
            .onAppear { text = TimerPreset.clockString(for: duration) }
            .onChange(of: duration) { _, newValue in
                if !isFocused { text = TimerPreset.clockString(for: newValue) }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused { commit() }
            }
            .onSubmit {
                commit()
                onSubmit()
            }
            .onKeyPress(.upArrow) { step(by: 60) }
            .onKeyPress(.downArrow) { step(by: -60) }
            .accessibilityLabel(String(localized: "Timer length"))
    }

    private func commit() {
        if let parsed = TimerPreset.parseDuration(text) {
            duration = parsed
        }
        text = TimerPreset.clockString(for: duration)
    }

    private func step(by seconds: Double) -> KeyPress.Result {
        if let parsed = TimerPreset.parseDuration(text) { duration = parsed }
        duration = max(60, duration + seconds)
        text = TimerPreset.clockString(for: duration)
        return .handled
    }
}

/// One preset on one line: its colour, its name, its length. Click to start it.
private struct NotchPresetRow: View {
    let preset: TimerPreset
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(preset.color)
                    .frame(width: 8, height: 8)
                Text(preset.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(preset.formattedDuration)
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(isHovering ? 0.08 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(localized: "Start \(preset.name)"))
        .onHover { isHovering = $0 }
    }
}

private struct TimerProgressRing: View {
    let progress: Double
    let tint: Color
    let timeText: String
    let isOvertime: Bool
    let remainingTime: TimeInterval

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 4)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.3), value: clampedProgress)

            Text(timeText)
                .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(isOvertime ? Color.red : .white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.25), value: remainingTime)
        }
        .frame(width: 72, height: 72)
    }
}

#Preview {
    NotchTimerView()
        .environmentObject(DynamicIslandViewModel())
        .frame(width: 600, height: 200)
        .background(.black)
}
