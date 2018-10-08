//
//  PreferenceWindow.swift
//  NEU-IPGW-macOS
//
//  Created by Haizs Chen on 2018/10/5.
//  Copyright © 2018 Haizs Chen. All rights reserved.
//

import Cocoa
import ServiceManagement

class PreferenceWindow: NSWindowController, NSWindowDelegate {

    let helperBundleName = "com.haizs.NEU-IPGW-macOS-LaunchHelper"

    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var autoLaunchCheckbox: NSButton!

    @IBAction func toggleAutoLaunch(_ sender: NSButton) {
        let isAuto = sender.state == .on
        SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
    }

    override var windowNibName: String! {
        return "PreferenceWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self

        let foundHelper = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == helperBundleName
        }
        autoLaunchCheckbox.state = foundHelper ? .on : .off

        let defaults = UserDefaults.standard
        usernameField.stringValue = defaults.string(forKey: "username") ?? ""
        passwordField.stringValue = defaults.string(forKey: "password") ?? ""
    }

    func windowWillClose(_ notification: Notification) {
        let defaults = UserDefaults.standard
        defaults.set(usernameField.stringValue, forKey: "username")
        defaults.set(passwordField.stringValue, forKey: "password")
    }

}
