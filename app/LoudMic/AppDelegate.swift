import Cocoa
import MacAppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var targetVolume = 100
    private var volume100Item: NSMenuItem!
    private var volume80Item: NSMenuItem!

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let b64 = "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJKADAAQAAAABAAAAJAAAAAAqDuP8AAAB30lEQVRYCe2XPS8EURSG13cjQqEQLYVGFGiUJEqrEPEbfCVKf0WDRrsSP0AiglZBCDoUIhoFhY/3YU5yMxt3Z+bujmwyb/LmnLnnPR+5u3fubqlUoMl2oCVw3i7lz4lTUZ1j2X3xPXrO1Qyq26H4FSNrxHJFu7odiPFh7JlYW54TTajZp2cgYmhSozV1xm/CiIzv+0cMTWpkHagjQackmqoyWQfiu1ILSTRVNbIOVFWoXgvFQLV2stihptshrgAfuJOWIsGNbMUn9sTKig1F8T3Ze4/WG5pU1O6nE0c566xbPG7RGMi1ODUzY0CZLyLFHsReEfSI16I1idurSCPzk0MuGmpRMzM4hUeiNVx0Kk3Lt2Etbk1nHB05FqdW8Mledgqey+8WDWNydsRL8ULcFlkzoCXHBlqxQIjtU/KdU3RXfvzi7NQadMGBQWvD3MqnVl0wryofohWvyB/2VOZEoTE9uWWPPlNo02lAo2dxS1wQ+TEG8VkjZsNgyW0IVlX1VXSb+Xy05DQU46rOx/Em/jUMMTRoc8OoOm2Ip6INdhatEfs3rKmzDbQeOkXwS0oDuMc9/jpIPV89Bkrd1JfAyysUfFy8ZwB+EHz/rZIW7pfQLsxH+U9JEwtdsQON2IFvG+6PRw/dh7cAAAAASUVORK5CYII="
        if let data = Data(base64Encoded: b64), let img = NSImage(data: data) {
            img.size = NSSize(width: 18, height: 18); img.isTemplate = true; statusItem.button?.image = img
        }

        let menu = NSMenu()
        menu.delegate = self
        volume100Item = NSMenuItem(title: "100% Volume", action: #selector(set100), keyEquivalent: ""); volume100Item.target = self; volume100Item.state = .on
        volume80Item = NSMenuItem(title: "80% Volume", action: #selector(set80), keyEquivalent: ""); volume80Item.target = self
        let loginItem = NSMenuItem(title: "Start on Login", action: #selector(toggleLogin), keyEquivalent: ""); loginItem.target = self
        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkUpdate), keyEquivalent: ""); updateItem.target = self
        [volume100Item, volume80Item, NSMenuItem.separator(), loginItem, NSMenuItem.separator(), updateItem, NSMenuItem(title: "Quit LoudMic", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")].forEach { menu.addItem($0) }
        statusItem.menu = menu

        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let v = self?.targetVolume else { return }
            DispatchQueue.global().async { Self.setInputVolume(v) }
        }
    }

    @objc private func set100() { targetVolume = 100; volume100Item.state = .on; volume80Item.state = .off }
    @objc private func set80() { targetVolume = 80; volume100Item.state = .off; volume80Item.state = .on }
    @objc private func toggleLogin(_ sender: NSMenuItem) { LoginItem.toggle(); sender.state = LoginItem.isEnabled ? .on : .off }
    @objc private func checkUpdate() { UpdateChecker.check(repo: "vladstudio/mac-loudmic", appName: "LoudMic", manual: true) }

    private static func setInputVolume(_ v: Int) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", "set volume input volume \(v)"]
        try? p.run()
        p.waitUntilExit()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let item = menu.items.first(where: { $0.title == "Start on Login" }) {
            item.state = LoginItem.isEnabled ? .on : .off
        }
    }
}
