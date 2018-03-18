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
        let opts = NSDictionary(
                object: kCFBooleanTrue,
                forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        ) as CFDictionary

        guard AXIsProcessTrustedWithOptions(opts) else {
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

    private func babelToJs(_ babelSrc: String) -> String? {
        let compileTargetName = JsNames.System.BabelCompileSource.rawValue.appJsIntrinsicName
        let compiledVarName = JsNames.System.BabelCompiledSource.rawValue.appJsIntrinsicName
        jsContext?.store(compileTargetName, babelSrc)
        jsContext?.evaluateScript("try { " +
                "\(compiledVarName) = Babel.transform(\(compileTargetName), { presets: ['es2015'] }).code" +
                " } catch(e) {" +
                " \(compiledVarName) = undefined; console.log(String(e))" +
                " }")
        guard let v = jsContext?.fetch(compiledVarName) else{ return nil }
        guard v.isString else { return nil }
        return v.toString()
    }

    private func setUpObservers() {
        NotificationCenter.default.addObserver(forName: .compileAndExecuteJs, object: nil, queue: nil, using: { notification in
            guard let babelSource = notification.object as? String else {
                postLog("notification object is nil")
                return
            }
            postLog("[babel expression]: \(babelSource)")
            guard let jsSource = self.babelToJs(babelSource) else {
                return
            }
            self.executeBuffer(jsSource: jsSource)
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

    func executeBuffer(jsSource: String) {
        guard !jsSource.isEmpty else { return }

        postLog("[compiled expression]: \(jsSource)\n")

        executionLock.lock()
        defer{ executionLock.unlock() }
        let result = jsContext!.evaluateScript(jsSource)
        var expression = "\(result!)"
        if result?.isString == true {
            expression = "\"\(expression)\""
        }

        postLog("=> \(expression)")
    }

    private func loadConfig() {

        // load babel module
        do {
            postLog("loading babel")
            guard let babelPath = Bundle.main.path(forResource: "babel.min", ofType: "js", inDirectory: "www/static/vendors") else {
                throw RekeyErrors.filePathError
            }
            guard let jsSource = try? String(contentsOfFile: babelPath) else { throw RekeyErrors.fileLoadError(babelPath) }
            jsContext!.evaluateScript(jsSource)
        } catch {
            postLog("\(error)")
        }


        // get the home path directory
        let confPath = NSHomeDirectory() + Constants.configFilePathUnderHomeDirectory

        if FileManager.default.fileExists(atPath: confPath) {
            postLog("loading \(confPath)")
            if let jsSource = try? String(contentsOfFile: confPath) {
                postLog("compiling \(confPath)")
                if let bbl=babelToJs(jsSource) {
                    postLog("evaluating \(confPath)")
                    jsContext!.evaluateScript(bbl)
                }else{
                    postLog(String(format: "failed to load %@", confPath))
                }
            } else {
                postLog(String(format: "failed to load %@", confPath))
            }
        } else {
            postLog(String(format: "user config file does not exist. %@", confPath))
        }
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

