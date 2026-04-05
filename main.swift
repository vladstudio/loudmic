import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var targetVolume = 100
    var statusItem: NSStatusItem!
    var volume100Item: NSMenuItem!, volume80Item: NSMenuItem!, loginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let b64 = "iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJKADAAQAAAABAAAAJAAAAAAqDuP8AAAB30lEQVRYCe2XPS8EURSG13cjQqEQLYVGFGiUJEqrEPEbfCVKf0WDRrsSP0AiglZBCDoUIhoFhY/3YU5yMxt3Z+bujmwyb/LmnLnnPR+5u3fubqlUoMl2oCVw3i7lz4lTUZ1j2X3xPXrO1Qyq26H4FSNrxHJFu7odiPFh7JlYW54TTajZp2cgYmhSozV1xm/CiIzv+0cMTWpkHagjQackmqoyWQfiu1ILSTRVNbIOVFWoXgvFQLV2stihptshrgAfuJOWIsGNbMUn9sTKig1F8T3Ze4/WG5pU1O6nE0c566xbPG7RGMi1ODUzY0CZLyLFHsReEfSI16I1idurSCPzk0MuGmpRMzM4hUeiNVx0Kk3Lt2Etbk1nHB05FqdW8Mledgqey+8WDWNydsRL8ULcFlkzoCXHBlqxQIjtU/KdU3RXfvzi7NQadMGBQWvD3MqnVl0wryofohWvyB/2VOZEoTE9uWWPPlNo02lAo2dxS1wQ+TEG8VkjZsNgyW0IVlX1VXSb+Xy05DQU46rOx/Em/jUMMTRoc8OoOm2Ip6INdhatEfs3rKmzDbQeOkXwS0oDuMc9/jpIPV89Bkrd1JfAyysUfFy8ZwB+EHz/rZIW7pfQLsxH+U9JEwtdsQON2IFvG+6PRw/dh7cAAAAASUVORK5CYII="
        if let data = Data(base64Encoded: b64), let img = NSImage(data: data) {
            img.size = NSSize(width: 18, height: 18); img.isTemplate = true; statusItem.button?.image = img
        }
        let menu = NSMenu()
        volume100Item = NSMenuItem(title: "100% Volume", action: #selector(set100), keyEquivalent: ""); volume100Item.target = self; volume100Item.state = .on
        volume80Item = NSMenuItem(title: "80% Volume", action: #selector(set80), keyEquivalent: ""); volume80Item.target = self
        loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin), keyEquivalent: ""); loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        [volume100Item, volume80Item, NSMenuItem.separator(), loginItem, NSMenuItem.separator(), NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")].forEach { menu.addItem($0) }
        statusItem.menu = menu
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let v = self?.targetVolume else { return }
            DispatchQueue.global().async {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                p.arguments = ["-e", "set volume input volume \(v)"]
                try? p.run()
                p.waitUntilExit()
            }
        }
    }
    @objc func set100() { targetVolume = 100; volume100Item.state = .on; volume80Item.state = .off }
    @objc func set80() { targetVolume = 80; volume100Item.state = .off; volume80Item.state = .on }
    @objc func toggleLogin() {
        do { if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() } }
        catch { NSLog("Login item toggle failed: %@", error.localizedDescription) }
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate(); app.delegate = delegate
app.run()
