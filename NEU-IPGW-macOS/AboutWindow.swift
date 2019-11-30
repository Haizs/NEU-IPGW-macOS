//
//  AboutWindow.swift
//  NEU-IPGW-macOS
//
//  Created by Haizs Chen on 2018/10/5.
//  Copyright © 2018 Haizs Chen. All rights reserved.
//

import Cocoa

class AboutWindow: NSWindowController {
    @IBOutlet var versionField: NSTextField!

    override var windowNibName: String! {
        return "AboutWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Version 0.0.0"
        versionField.stringValue = "Version \(appVersion)"
    }
}
