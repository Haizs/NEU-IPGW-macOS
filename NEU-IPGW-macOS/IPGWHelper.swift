//
//  IPGWHelper.swift
//  NEU-IPGW-macOS
//
//  Created by Haizs Chen on 2019/6/7.
//  Copyright © 2019 Haizs Chen. All rights reserved.
//

import Cocoa

class IPGWHelper: NSObject, URLSessionTaskDelegate {
    func urlSession(_: URLSession,
                    task _: URLSessionTask,
                    willPerformHTTPRedirection _: HTTPURLResponse,
                    newRequest _: URLRequest,
                    completionHandler: @escaping (URLRequest?)
                        -> Void) {
        completionHandler(nil)
    }

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration,
                          delegate: self, delegateQueue: nil)
    }()

    static let shared = IPGWHelper()

    func reset() {
        session.reset(completionHandler: {})
    }

    private func regexMatches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch {
            return []
        }
    }

    private func request(urlString: String,
                         dataString: String?,
                         onSuccess: @escaping (String, [String: String]?) -> Void,
                         onFailure: @escaping (String) -> Void) {
        let url = URL(string: urlString)!
        let data = dataString?.data(using: .utf8)
        var request = URLRequest(url: url)
        request.httpMethod = (data != nil) ? "POST" : "GET"
        request.httpBody = data
        let safariUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15"
        request.setValue(safariUA, forHTTPHeaderField: "User-Agent")
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                onFailure(error.localizedDescription)
                return
            }
            if let data = data, let httpResponse = response as? HTTPURLResponse {
                onSuccess(String(bytes: data, encoding: .utf8) ?? "", httpResponse.allHeaderFields as? [String: String])
            }
        }
        task.resume()
    }

    private func fetchCASTGC(onSuccess: @escaping () -> Void,
                             onFailure: @escaping (String) -> Void) {
        request(urlString: "https://pass.neu.edu.cn/tpass/login",
                dataString: nil,
                onSuccess: { data, header in
                    if let location = header?["Location"],
                        location.contains("portal") {
                        onSuccess()
                        return
                    }
                    guard let url = data.regexMatches(regex: #"(?<=id="loginForm" action=")[^"]*"#).first,
                        let ltt = data.regexMatches(regex: #"(?<=name="lt" value=")[^"]*"#).first else {
                        onFailure("网页加载失败")
                        return
                    }
                    let defaults = UserDefaults.standard
                    let username = defaults.string(forKey: "username") ?? ""
                    let password = defaults.string(forKey: "password") ?? ""
                    let userpass = username + password
                    let user = userpass.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let ull = String(username.count)
                    let pll = String(password.count)
                    let data = "rsa=\(user)\(ltt)&ul=\(ull)&pl=\(pll)&lt=\(ltt)&execution=e1s1&_eventId=submit"
                    self.request(urlString: "https://pass.neu.edu.cn" + url,
                                 dataString: data,
                                 onSuccess: { _, header in
                                     guard let setCookie = header?["Set-Cookie"],
                                         setCookie.contains("CASTGC")
                                     else {
                                         onFailure("账号或密码错误")
                                         return
                                     }
                                     onSuccess()
                                 }, onFailure: { error in
                                     onFailure(error)
                                     return
                    })
                }, onFailure: { error in
                    onFailure(error)
        })
    }

    func login(onSuccess: @escaping (Any) -> Void,
               onFailure: @escaping (String) -> Void) {
        fetchCASTGC(onSuccess: {
            let url = "https://pass.neu.edu.cn/tpass/login?service=https://ipgw.neu.edu.cn/srun_cas.php?ac_id=1"
            self.request(urlString: url,
                         dataString: nil,
                         onSuccess: { _, header in
                             guard let location = header?["Location"],
                                 location.contains("ticket") else {
                                 onFailure("网页跳转失败")
                                 return
                             }
                             self.request(urlString: location,
                                          dataString: nil,
                                          onSuccess: { data, header in
                                              guard let location = header?["Location"],
                                                  location.contains("srun_cas.php") else {
                                                  onFailure("IPGW登录失败")
                                                  return
                                              }
                                              self.refreshCAS(retriedTimes: 0,
                                                              onSuccess: { data in
                                                                  onSuccess(data)
                                                              }, onFailure: { error in
                                                                  onFailure(error)
                                              })
                                          }, onFailure: { error in
                                              onFailure(error)
                                              return
                             })
                         }, onFailure: { error in
                             onFailure(error)
                             return
            })
        }, onFailure: { error in
            onFailure(error)
        })
    }

    func refreshCAS(retriedTimes: Int,
                    onSuccess: @escaping (Any) -> Void,
                    onFailure: @escaping (String) -> Void) {
        if retriedTimes > 5 {
            onFailure("重试次数过多")
            return
        }
        let url = "https://ipgw.neu.edu.cn/srun_cas.php?ac_id=1"
        request(urlString: url,
                dataString: nil,
                onSuccess: { data, _ in
                    if data.contains("帮他下线") || data.contains(">0秒</span>") {
                        sleep(1)
                        self.refreshCAS(retriedTimes: retriedTimes + 1,
                                        onSuccess: { data in
                                            onSuccess(data)
                                        }, onFailure: { error in
                                            onFailure(error)
                        })
                        return
                    }
                    self.getTotalData(pageData: data, onSuccess: { data in
                        onSuccess(data)
                    }, onFailure: { error in
                        onFailure(error)
                    })
                }, onFailure: { error in
                    onFailure(error)
                    return
        })
    }

    private func getTotalData(pageData: String,
                              onSuccess: @escaping (Any) -> Void,
                              onFailure: @escaping (String) -> Void) {
        let key = String(arc4random() % 100_000)
        let url = "http://ipgw.neu.edu.cn/include/auth_action.php?k=\(key)"
        let data = "action=get_online_info&key=\(key)"
        request(urlString: url,
                dataString: data,
                onSuccess: { data, _ in
                    let value = data.split(separator: ",").map(String.init)
                    self.calculateData(data: pageData, balance: value[0], time: value[1] + "秒", onSuccess: { data in
                        onSuccess(data)
                    }, onFailure: { error in
                        onFailure(error)
                    })
                }, onFailure: { error in
                    onFailure(error)
                    return
        })
    }

    private func calculateData(data: String,
                               balance: String?,
                               time: String?,
                               onSuccess: @escaping (Any) -> Void,
                               onFailure: @escaping (String) -> Void) {
        guard let username = regexMatches(for: #"(?<=登录帐号：<span id="user_name" style="float:right;color: #894324;">)[^<]*"#, in: data).first,
            let userip = regexMatches(for: #"(?<=当前IP：<span id="user_ip" style="float:right;color: #894324;">)[^<]*"#, in: data).first,
            var totalBalance = balance,
            var totalTime = time else {
            onFailure("数据加载失败")
            return
        }
        let results = regexMatches(for: #"(?<=<td class="mhide" align="right"><div>)[^<]*"#, in: data)
        for (index, value) in results.enumerated() {
            if index & 1 == 0 {
                totalTime = sumTime(totalTime, value)
            } else {
                totalBalance = sumBalance(totalBalance, value)
            }
        }
        onSuccess(["username": username,
                   "userip": userip,
                   "balance": totalBalance,
                   "time": totalTime])
    }

    private func sumTime(_ suma: String, _ sumb: String) -> String {
        let houra = ((regexMatches(for: #"\d*?(?=小时)"#, in: suma).first ?? "") as NSString).intValue
        let minutea = ((regexMatches(for: #"\d*?(?=分)"#, in: suma).first ?? "") as NSString).intValue
        let seconda = ((regexMatches(for: #"\d*?(?=秒)"#, in: suma).first ?? "") as NSString).intValue
        let hourb = ((regexMatches(for: #"\d*?(?=小时)"#, in: sumb).first ?? "") as NSString).intValue
        let minuteb = ((regexMatches(for: #"\d*?(?=分)"#, in: sumb).first ?? "") as NSString).intValue
        let secondb = ((regexMatches(for: #"\d*?(?=秒)"#, in: sumb).first ?? "") as NSString).intValue
        var second = seconda + secondb
        var minute = minutea + minuteb
        var hour = houra + hourb
        minute += second / 60
        second %= 60
        hour += minute / 60
        minute %= 60
        if hour == 0, minute == 0 {
            return String(format: "%d秒", second)
        } else if hour == 0 {
            return String(format: "%d分%d秒", minute, second)
        } else {
            return String(format: "%d小时%d分%d秒", hour, minute, second)
        }
    }

    private func sumBalance(_ suma: String, _ sumb: String) -> String {
        let nsa = suma.replacingOccurrences(of: ",", with: "") as NSString
        let nsb = sumb.replacingOccurrences(of: ",", with: "") as NSString
        let balancea = nsa.contains("M") ? nsa.doubleValue * 1000 * 1000 :
            nsa.contains("K") ? nsa.doubleValue * 1000 : nsa.doubleValue
        let balanceb = nsb.contains("M") ? nsb.doubleValue * 1000 * 1000 :
            nsb.contains("K") ? nsb.doubleValue * 1000 : nsb.doubleValue
        let balance = balancea + balanceb
        if balance >= 1000 * 1000 * 1000 {
            let gPart = (balance / (1000 * 1000 * 1000)).rounded(.down)
            let mPart = (balance - gPart * 1000 * 1000 * 1000) / (1000 * 1000)
            return String(format: "%.0f,%03d.%2dM", gPart, Int(mPart), Int(mPart * 100) % 100)
        } else if balance >= 1000 * 1000 {
            return String(format: "%.2fM", balance / (1000 * 1000))
        } else if balance >= 1000 {
            return String(format: "%.2fK", balance / 1000)
        } else {
            return String(format: "%.0fB", balance)
        }
    }

    func logout(onSuccess: @escaping (Any) -> Void,
                onFailure: @escaping (String) -> Void) {
        fetchCASTGC(onSuccess: {
            let url = "http://ipgw.neu.edu.cn/srun_cas.php?logout"
            self.request(urlString: url,
                         dataString: nil,
                         onSuccess: { data, header in
                             guard let location = header?["Location"],
                                 location.contains("tpass/logout") else {
                                 onFailure("IPGW注销失败")
                                 return
                             }
                             let text = self.regexMatches(for: #"(?<=title>)[^<]*"#, in: data).first ?? ""
                             onSuccess(text)
                         }, onFailure: { error in
                             onFailure(error)
                             return
            })
        }, onFailure: { error in
            onFailure(error)
        })
    }
}

extension String {
    func regexMatches(regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            return []
        }
    }
}
