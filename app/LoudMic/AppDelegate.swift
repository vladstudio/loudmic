import Cocoa
import CoreAudio
import MacAppKit

@MainActor class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var targetVolume = 100
    private var volume100Item: NSMenuItem!
    private var volume80Item: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var currentInputDeviceID: AudioDeviceID = 0
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let b64 = "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJKADAAQAAAABAAAAJAAAAAAqDuP8AAAB30lEQVRYCe2XPS8EURSG13cjQqEQLYVGFGiUJEqrEPEbfCVKf0WDRrsSP0AiglZBCDoUIhoFhY/3YU5yMxt3Z+bujmwyb/LmnLnnPR+5u3fubqlUoMl2oCVw3i7lz4lTUZ1j2X3xPXrO1Qyq26H4FSNrxHJFu7odiPFh7JlYW54TTajZp2cgYmhSozV1xm/CiIzv+0cMTWpkHagjQackmqoyWQfiu1ILSTRVNbIOVFWoXgvFQLV2stihptshrgAfuJOWIsGNbMUn9sTKig1F8T3Ze4/WG5pU1O6nE0c566xbPG7RGMi1ODUzY0CZLyLFHsReEfSI16I1idurSCPzk0MuGmpRMzM4hUeiNVx0Kk3Lt2Etbk1nHB05FqdW8Mledgqey+8WDWNydsRL8ULcFlkzoCXHBlqxQIjtU/KdU3RXfvzi7NQadMGBQWvD3MqnVl0wryofohWvyB/2VOZEoTE9uWWPPlNo02lAo2dxS1wQ+TEG8VkjZsNgyW0IVlX1VXSb+Xy05DQU46rOx/Em/jUMMTRoc8OoOm2Ip6INdhatEfs3rKmzDbQeOkXwS0oDuMc9/jpIPV89Bkrd1JfAyysUfFy8ZwB+EHz/rZIW7pfQLsxH+U9JEwtdsQON2IFvG+6PRw/dh7cAAAAASUVORK5CYII="
        if let data = Data(base64Encoded: b64), let img = NSImage(data: data) {
            img.size = NSSize(width: 18, height: 18)
            img.isTemplate = true
            statusItem.button?.image = img
        }

        let menu = NSMenu()
        menu.delegate = self

        let saved = UserDefaults.standard.integer(forKey: "targetVolume")
        if saved == 80 { targetVolume = 80 }

        volume100Item = NSMenuItem(title: "100% Volume", action: #selector(set100), keyEquivalent: "")
        volume100Item.target = self
        volume100Item.state = targetVolume == 100 ? .on : .off

        volume80Item = NSMenuItem(title: "80% Volume", action: #selector(set80), keyEquivalent: "")
        volume80Item.target = self
        volume80Item.state = targetVolume == 80 ? .on : .off

        loginItem = NSMenuItem(title: "Start on Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self

        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkUpdate), keyEquivalent: "")
        updateItem.target = self

        let aboutItem = NSMenuItem(title: "About LoudMic", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self

        [volume100Item, volume80Item, NSMenuItem.separator(),
         loginItem, NSMenuItem.separator(),
         updateItem, aboutItem, NSMenuItem.separator(),
         NSMenuItem(title: "Quit LoudMic", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        ].forEach { menu.addItem($0) }
        statusItem.menu = menu

        Self.setInputVolume(targetVolume)
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let v = self?.targetVolume else { return }
                AppDelegate.setInputVolume(v)
            }
        }

        watchDefaultDeviceChanges()
        watchCurrentDeviceVolume()

        UpdateChecker.check(repo: "vladstudio/loudmic", appName: "LoudMic")
    }

    @objc private func set100() {
        targetVolume = 100; volume100Item.state = .on; volume80Item.state = .off
        UserDefaults.standard.set(100, forKey: "targetVolume")
        Self.setInputVolume(100)
    }
    @objc private func set80() {
        targetVolume = 80; volume100Item.state = .off; volume80Item.state = .on
        UserDefaults.standard.set(80, forKey: "targetVolume")
        Self.setInputVolume(80)
    }
    @objc private func toggleLogin(_ sender: NSMenuItem) { LoginItem.toggle(); sender.state = LoginItem.isEnabled ? .on : .off }
    @objc private func checkUpdate() { UpdateChecker.check(repo: "vladstudio/loudmic", appName: "LoudMic", manual: true) }
    @objc private func openAbout() { NSWorkspace.shared.open(URL(string: "https://apps.vlad.studio/loudmic")!) }

    private func watchDefaultDeviceChanges() {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &addr, .main
        ) { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.unwatchCurrentDeviceVolume()
                self?.watchCurrentDeviceVolume()
                guard let v = self?.targetVolume else { return }
                AppDelegate.setInputVolume(v)
            }
        }
    }

    private func watchCurrentDeviceVolume() {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
              &addr, 0, nil, &size, &deviceID) == noErr else { return }
        currentInputDeviceID = deviceID
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated {
                guard let v = self?.targetVolume else { return }
                AppDelegate.setInputVolume(v)
            }
        }
        volumeListenerBlock = block
        var volAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(deviceID, &volAddr, .main, block)
    }

    private func unwatchCurrentDeviceVolume() {
        guard currentInputDeviceID != 0, let block = volumeListenerBlock else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectRemovePropertyListenerBlock(currentInputDeviceID, &addr, .main, block)
        volumeListenerBlock = nil
        currentInputDeviceID = 0
    }

    nonisolated private static func setInputVolume(_ v: Int) {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
              &addr, 0, nil, &size, &deviceID) == noErr else { return }

        var volume = Float32(v) / 100.0
        addr.mSelector = kAudioDevicePropertyVolumeScalar
        addr.mScope = kAudioDevicePropertyScopeInput
        size = UInt32(MemoryLayout<Float32>.size)
        for ch: UInt32 in [0, 1, 2] {
            addr.mElement = ch
            var settable: DarwinBoolean = false
            guard AudioObjectIsPropertySettable(deviceID, &addr, &settable) == noErr,
                  settable.boolValue else { continue }
            AudioObjectSetPropertyData(deviceID, &addr, 0, nil, size, &volume)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = LoginItem.isEnabled ? .on : .off
    }
}
