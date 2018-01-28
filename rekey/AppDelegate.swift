//
//  AppDelegate.swift
//
//  Created by nemoto on 2017/12/16.
//  Copyright © 2017年 nemoto. All rights reserved.
//

import Cocoa
import Pods_rekey
import Swifter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        guard let path = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "www") else {
            print("index.html is missing")
            return
        }

        DispatchQueue(label: Constants.httpServerQueueName).async {
            let server = HttpServer()

            server["/"] = shareFile(path)
            server["/files/:path"] = directoryBrowser("/")

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


}

