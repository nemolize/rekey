//
//  AppDelegate.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let appService = AppService()

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_: Notification) {
        if !appService.hasAccessibilityPermission() {
            NSApplication.shared.terminate(self)
        }

        let icon = NSImage(named: NSImage.Name("MenuBarIcon"))
        icon?.isTemplate = true

        statusItem.button?.image = icon
        constructMenu()
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    @objc private func showWindow() {
        NSApp.windows.last?.setIsVisible(true)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func constructMenu() {
        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(
                title: "Preferences",
                action: #selector(showWindow),
                keyEquivalent: "P"
            )
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Rekey",
                action: #selector(NSApplication.shared.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        statusItem.menu = menu
    }
}
