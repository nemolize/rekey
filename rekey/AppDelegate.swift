//
//  AppDelegate.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa
import Pods_rekey
import Swifter

let executionLock = NSLock()
var jsContext = JSContext()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private func trustThisApplication() {
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        guard AXIsProcessTrustedWithOptions([key: true] as NSDictionary) else {
            exit(1)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        trustThisApplication()
        Intrinsics().setUpAppIntrinsicJsObjects()

        self.startEventCaptureThread()
        setUpObservers()
        setUpWebServer()
    }

    private func setUpObservers() {
        NotificationCenter.default.addObserver(forName: .executeJs, object: nil, queue: nil, using: { notification in
            guard let object = notification.object as? ExecuteOptions else {
                return postLog("invalid notification object: \(notification.object ?? "")")
            }
            self.executeBuffer(object)
        })
        NotificationCenter.default.addObserver(forName: .reload, object: nil, queue: nil, using: { notification in
            self.reload()
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func getBytes(url: URL) throws -> [UInt8] { return try [UInt8](Data(contentsOf: url)) }

    func setUpWebServer() {
        DispatchQueue(label: Constants.httpServerQueueName).async {
            let server = HttpServer()

            server.GET["/"] = shareFile(Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "www")!)
            server.GET["/favicon.ico"] = { r in
                guard let faviconInternalUrl = Bundle.main.url(forResource: "favicon", withExtension: "ico", subdirectory: "www") else { return .notFound }
                return HttpResponse.raw(200, "OK", ["Content-Type": "image/x-icon"], { try $0.write(self.getBytes(url: faviconInternalUrl)) })
            }

            server.POST["/"] = { r in
                let jsSource = String(bytes: r.body, encoding: String.Encoding.utf8)
                NotificationCenter.postExecuteJS(jsSource!)
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"], { try $0.write([UInt8]("{\"result\":\"ok\"}".utf8)) })
            }

            server.POST["/reload"] = { r in
                self.reload()
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/json"], { try $0.write([UInt8]("{\"result\":\"ok\"}".utf8)) })
            }

            server["/static/:path"] = shareFilesFromDirectory("\(Bundle.main.resourcePath!)/www/static/")

            let semaphore = DispatchSemaphore(value: 0)
            do {
                try server.start(9080, forceIPv4: true)
                print("Server has started ( port = \(try server.port()) ). Try to connect now...")
                semaphore.wait()
            } catch {
                print("Server start error: \(error)")
                semaphore.signal()
            }
        }
    }

    func reload() {
        jsContext = JSContext()
        Intrinsics().setUpAppIntrinsicJsObjects()
        self.loadConfig()
        postLog("config reloaded")
    }

    func startEventCaptureThread() {
        DispatchQueue(label: Constants.captureEventQueueName).async {
            print("starting background thread")
            jsContext?.exceptionHandler = { context, exception in
                // type of String
                guard let stacktrace = exception?.objectForKeyedSubscript("stack").toString() else {
                    postLog("JS Error: \(exception.debugDescription)")
                    return
                }
                // type of Number
                guard let lineNumber = exception?.objectForKeyedSubscript("line")?.toUInt32() else {
                    postLog("JS Error: \(exception.debugDescription)")
                    return
                }
                // type of Number
                guard let column = exception?.objectForKeyedSubscript("column")?.toUInt32() else {
                    postLog("JS Error: \(exception.debugDescription)")
                    return
                }
                postLog("JS Error: \(column):\(lineNumber) \(stacktrace) : \(exception?.debugDescription ?? "")")
            }
            self.loadConfig()
            self.createEventTap()
        }
    }

    func executeBuffer(_ executeOptions: ExecuteOptions) {
        guard !executeOptions.source.isEmpty else { return }

        executeOptions.suppressLog ? nil : postLog(executeOptions.source)

        // TODO use queue.sync
        executionLock.lock()
        defer{ executionLock.unlock() }

        guard let result = jsContext!.evaluateScript(executeOptions.source) else {return}

        if executeOptions.suppressLog { return }

        let expression = result.isString ? "\"\(result)\"" : "\(result)"
        postLog("=> \(expression)")

    }

    private func loadConfig() {
        // get the home path directory
        let tryLoad: (String) -> () = { path in
            guard FileManager.default.fileExists(atPath: path) else {
                postLog(String(format: "user config file does not exist. \(path)", path))
                return
            }

            postLog("loading \(path)")
            guard let jsSource = try? String(contentsOfFile: path) else {
                postLog(String(format: "failed to load \(path)"))
                return
            }
            NotificationCenter.postExecuteJS(jsSource, true)
        }
        tryLoad(Bundle.main.path(forResource: "core", ofType: "js", inDirectory: "scripts")!)
        tryLoad(NSHomeDirectory() + Constants.configFilePathUnderHomeDirectory)
    }

    private func createEventTap() {
        let eventMask = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
            UInt32(NX_SYSDEFINED)
        ].reduce(0) { prev, next in prev | (1 << next) }

        guard let eventTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: onKeyEvent,
                userInfo: nil)
                else {
            print("failed to create event tap")
            exit(1)
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }

}

