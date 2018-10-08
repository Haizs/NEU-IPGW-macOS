//
//  StatusMenuController.swift
//  NEU-IPGW-macOS
//
//  Created by Haizs Chen on 2018/10/5.
//  Copyright © 2018 Haizs Chen. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    override func awakeFromNib() {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("NEU-IPGW"))
        }
        constructMenu()
    }

    func constructMenu() {
        let menu = NSMenu()

        menu.addItem(withTitle: "连接网络", action: #selector(StatusMenuController.loginClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "断开全部连接", action: #selector(StatusMenuController.logoutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "偏好设置...", action: nil, keyEquivalent: ",")
        menu.addItem(withTitle: "反馈", action: #selector(AppDelegate.issueClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "关于", action: #selector(AppDelegate.aboutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc func loginClicked(_ sender: AnyObject) {

    }

    @objc func logoutClicked(_ sender: AnyObject) {

    }

    @objc func issueClicked(_ sender: AnyObject) {
        if let url = URL(string: "https://github.com/Haizs/NEU-IPGW-macOS/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func aboutClicked(_ sender: AnyObject) {
    }
}
