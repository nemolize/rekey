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
let jsContext = JSContext()
var modifierFlags: CGEventFlags = CGEventFlags(rawValue: 256)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let intrinsics=Intrinsics()
        intrinsics.setUpAppIntrinsicJsObjects()

        // capture key events in background thread
        DispatchQueue(label: Constants.captureEventQueueName).async {
            self.backgroundThread()
        }


        guard let path = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "www") else {
            print("index.html is missing")
            return
        }

        // append log notification from non UI threads to the UI thread
        NotificationCenter.default.addObserver(
                forName: .executeJs,
                object: nil,
                queue: nil,
                using: { notification in
                    guard let jsSource = notification.object as? String else {
                        print("notification object is nil");
                        return
                    }
                    self.executeBuffer(jsSource:jsSource)
                })

        DispatchQueue(label: Constants.httpServerQueueName).async {
            let server = HttpServer()

            server.GET["/"] = shareFile(path)
            server.POST["/"] = { r in
                let jsSource = String(bytes: r.body, encoding: String.Encoding.utf8)
                postLog(jsSource)
                return HttpResponse.raw(200, "OK", [:], { try $0.write([UInt8]("test".utf8)) })
            }

            server["/static/:path"] = shareFilesFromDirectory("\(Bundle.main.resourcePath!)/www/")

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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func backgroundThread(){
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
            postLog("JS Error: \(column):\(lineNumber) \(stacktrace)")
        }
        loadConfig()
        createEventTap()
    }

    func executeBuffer(jsSource: String) {
        guard !jsSource.isEmpty else { return }

        postLog("[expression]: \(jsSource)\n")

        executionLock.lock()
        defer{executionLock.unlock()}
        let result = jsContext!.evaluateScript(jsSource)
        var expression = "\(result!)"
        if result?.isString == true {
            expression = "\"\(expression)\""
        }

        postLog("=> \(expression)")
    }

    func loadConfig(){
        // get the home path directory
        let confPath = NSHomeDirectory()+Constants.configFilePathUnderHomeDirectory

        if FileManager.default.fileExists(atPath: confPath){
            if let jsSource = try? String(contentsOfFile: confPath){
                jsContext!.evaluateScript(jsSource)
            }else{
                postLog(String(format:"failed to load %@",confPath))
            }
        } else {
            postLog(String(format:"user config file does not exist. %@",confPath))
        }
    }

    func createEventTap(){
        let eventMask = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
            UInt32(NX_SYSDEFINED)
        ].reduce(0) { prev, next in prev | (1 << next) }

        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
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

