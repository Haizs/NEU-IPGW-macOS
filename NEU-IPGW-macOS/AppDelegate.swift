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

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let userNotificationCenter = UNUserNotificationCenter.current()
    let aboutWindow = AboutWindow()
    let preferenceWindow = PreferenceWindow()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("NEU-IPGW"))
        }
        UNUserNotificationCenter.current().delegate = self
        constructMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "连接网络", action: #selector(AppDelegate.loginClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "断开全部连接", action: #selector(AppDelegate.logoutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "偏好设置...", action: #selector(AppDelegate.preferenceClicked(_:)), keyEquivalent: ",")
        menu.addItem(withTitle: "反馈", action: #selector(AppDelegate.issueClicked(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "关于", action: #selector(AppDelegate.aboutClicked(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let uuidString = UUID().uuidString
        let notification = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)
        userNotificationCenter.add(notification)
    }

    func postRequest(urlString: String, dataString: String, callback: @escaping (_ data: String) -> Void) {
        let url = URL(string: urlString)!
        let data = dataString.data(using: .utf8)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.sendNotification(title: "Error", body: error.localizedDescription)
                return
            }
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode) {
                let localizedString = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                self.sendNotification(title: "网络错误", body: localizedString)
                return
            }
            if let data = data, let string = String(data: data, encoding: .utf8) {
                callback(string)
            }
        }
        task.resume()
    }

    func formatFlux(byte: Double) -> String {
        if byte > 1000 * 1000 * 1000 {
            return String(format: "%.9fG", byte / (1000 * 1000 * 1000))
        } else if byte > 1000 * 1000 {
            return String(format: "%.6fM", byte / (1000 * 1000))
        } else if byte > 1000 {
            return String(format: "%.3fK", byte / (1000))
        } else {
            return String(format: "%fB", byte)
        }
    }

    func loginSuccess(username: String) {
        let key = String(arc4random() % 100000)
        let url = "http://ipgw.neu.edu.cn/include/auth_action.php?k=\(key)"
        let data = "action=get_online_info&key=\(key)"
        postRequest(urlString: url, dataString: data) { data in
            let value = data.split(separator: ",")
            let flux = self.formatFlux(byte: Double(value[0]) ?? 0)
            let balance = Double(value[2]) ?? 0
            self.sendNotification(title: "网络已连接 \(username)", body: "已用流量: \(flux)\n帐户余额: ￥\(balance)")
        }
    }

    func guardUser(callback: @escaping (_ username: String, _ passowrd: String) -> Void) {
        let defaults = UserDefaults.standard
        guard let username = defaults.string(forKey: "username"),
            !username.isEmpty,
            let password = defaults.string(forKey: "password"),
            !password.isEmpty else {
                self.preferenceClicked(self)
                return
        }
        callback(username, password)
    }

    @objc func loginClicked(_ sender: AnyObject) {
        guardUser { username, password in
            let url = "http://ipgw.neu.edu.cn/include/auth_action.php"
            let data = "action=login&username=\(username)&password=\(password)&ac_id=1&user_mac=&user_ip=&nas_ip=&save_me=0&ajax=1"
            self.postRequest(urlString: url, dataString: data) { data in
                if data.contains("login_ok") {
                    self.loginSuccess(username: username)
                } else {
                    self.sendNotification(title: "连接失败", body: data)
                    return
                }
            }
        }
    }

    @objc func logoutClicked(_ sender: AnyObject) {
        guardUser { username, password in
            let url = "http://ipgw.neu.edu.cn/include/auth_action.php"
            let data = "action=logout&username=\(username)&password=\(password)&ajax=1"
            self.postRequest(urlString: url, dataString: data) { data in
                self.sendNotification(title: "断开连接", body: data)
                return
            }
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

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

}
