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
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var autoLaunchCheckbox: NSButton!

    @IBAction func toggleAutoLaunch(_ sender: NSButton) {
        let helperBundleName = "com.haizs.NEU-IPGW-macOS-LaunchHelper"
        let isAuto = sender.state == .on
        SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
    }

    override var windowNibName: String! {
        return "PreferenceWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self

        let defaults = UserDefaults.standard
        usernameField.stringValue = defaults.string(forKey: "username") ?? ""
        passwordField.stringValue = defaults.string(forKey: "password") ?? ""
        autoLaunchCheckbox.stringValue = defaults.string(forKey: "autoLaunch") ?? ""
    }

    func windowWillClose(_: Notification) {
        let defaults = UserDefaults.standard
        defaults.set(usernameField.stringValue, forKey: "username")
        defaults.set(passwordField.stringValue, forKey: "password")
        defaults.set(autoLaunchCheckbox.stringValue, forKey: "autoLaunch")
        IPGWHelper.shared.reset()
    }
}
