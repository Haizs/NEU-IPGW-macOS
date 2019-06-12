//
//  AppDelegate.swift
//  NEU-IPGW-macOS
//
//  Created by Haizs Chen on 2018/10/4.
//  Copyright © 2018 Haizs Chen. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let userNotificationCenter = UNUserNotificationCenter.current()
    let aboutWindow = AboutWindow()
    let preferenceWindow = PreferenceWindow()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("NEU-IPGW"))
        }
        userNotificationCenter.delegate = self
        constructMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        userNotificationCenter.removeAllDeliveredNotifications()
    }

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "连接网络", action: #selector(AppDelegate.loginClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "断开网络", action: #selector(AppDelegate.logoutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "偏好设置...", action: #selector(AppDelegate.preferenceClicked(_:)), keyEquivalent: ",")
        menu.addItem(withTitle: "反馈", action: #selector(AppDelegate.issueClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "关于", action: #selector(AppDelegate.aboutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc func loginClicked(_ sender: AnyObject) {
        guardUser {
            IPGWHelper.shared.login(onSuccess: { result in
                let data = result as? [String: String]
                let username = data?["username"] ?? ""
                let userip = data?["userip"] ?? ""
                let balance = data?["balance"] ?? ""
                let time = data?["time"] ?? ""
                self.sendNotification(title: "\(username) 连接成功 \(userip)", body: "已用流量: \(balance)\n已用时长: \(time)")
            }, onFailure: { errorString in
                self.sendNotification(title: "连接失败", body: errorString)
            })
        }
    }

    @objc func logoutClicked(_ sender: AnyObject) {
        guardUser {
            IPGWHelper.shared.logout(onSuccess: { result in
                let data = result as? String ?? ""
                self.sendNotification(title: "断开成功", body: data)
            }, onFailure: { errorString in
                self.sendNotification(title: "断开失败", body: errorString)
            })
        }
    }

    @objc func preferenceClicked(_ sender: AnyObject) {
        preferenceWindow.showWindow(nil)
        preferenceWindow.window?.center()
        preferenceWindow.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func issueClicked(_ sender: AnyObject) {
        if let url = URL(string: "https://github.com/Haizs/NEU-IPGW-macOS/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func aboutClicked(_ sender: AnyObject) {
        aboutWindow.showWindow(nil)
        aboutWindow.window?.center()
        aboutWindow.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let uuidString = UUID().uuidString
        let notification = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)
        userNotificationCenter.add(notification)
        userNotificationCenter.getDeliveredNotifications { notifications in
            notifications.forEach { notification in
                if -notification.date.timeIntervalSinceNow > 60 * 60 * 24 {
                    self.userNotificationCenter.removeDeliveredNotifications(withIdentifiers:
                        [notification.request.identifier])
                }
            }
        }
    }

    func guardUser(callback: () -> Void) {
        let defaults = UserDefaults.standard
        guard let username = defaults.string(forKey: "username"),
            !username.isEmpty,
            let password = defaults.string(forKey: "password"),
            !password.isEmpty else {
                self.preferenceClicked(self)
                return
        }
        callback()
    }

}
