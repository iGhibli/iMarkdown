//
//  ViewController.swift
//  iMarkdown
//
//  Created by 赛驰 on 2017/7/24.
//  Copyright © 2017年 iGhibli. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController {
    @IBOutlet weak var showWebView: UIWebView!
    @IBOutlet weak var inputTextView: UITextView!
    var jsContext: JSContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleMarkdownToHTMLNotification(notification:)), name: NSNotification.Name("markdownToHTMLNotification"), object: nil)
        
        do {
            print("111")
            let str = try String(contentsOf: URL(string: "https://github.com/iGhibli/iMarkdown/blob/master/LICENSE")!)
            print("222")
            print(str)
            self.inputTextView.text = str
            
        }catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 调用JSContext初始化
        initializeJSContext()
    }
    
    // 初始化JSContext
    func initializeJSContext() {
        self.jsContext = JSContext()
        
        // 实现JS异常打印操作
        self.jsContext.exceptionHandler = { context, exception in
            if let exc = exception {
                print("JS Exception:", exc.toString())
            }
        }
        // 实现JS调用Swift打印Log功能
        let consoleLogObject = unsafeBitCast(self.consoleLog, to: AnyObject.self)
        self.jsContext.setObject(consoleLogObject, forKeyedSubscript: "consoleLog" as (NSCopying & NSObjectProtocol)!)
        _ = self.jsContext.evaluateScript("consoleLog")
        
        // 加载本地JS文件
        if let jsSourcePath = Bundle.main.path(forResource: "jssource", ofType: "js") {
            do {
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                self.jsContext.evaluateScript(jsSourceContents)
                // 获取Showdown脚本
                let showdownScript = try String(contentsOf: URL(string: "https://cdn.rawgit.com/showdownjs/showdown/1.6.3/dist/showdown.min.js")!)
                self.jsContext.evaluateScript(showdownScript)
                
            }catch {
                print(error.localizedDescription)
            }
        }
        
        // 实现JS调用Swift返回转换过的HTML内容
        let htmlResultsHandler = unsafeBitCast(self.markdownToHTMLHandler, to: AnyObject.self)
        self.jsContext.setObject(htmlResultsHandler, forKeyedSubscript: "handleConvertedMarkdown" as (NSCopying & NSObjectProtocol)!)
        _ = self.jsContext.evaluateScript("handleConvertedMarkdown")
        
    }
    
    // JS打印Log的Swift块（闭包）
    let consoleLog: @convention(block) (String) -> Void = { logMessage in
        print("\nJS Console", logMessage)
    }
    
    // JS返回转换过的HTML的Swift块（闭包）
    let markdownToHTMLHandler: @convention(block) (String) -> Void = { htmlOutput in
        NotificationCenter.default.post(name: NSNotification.Name("markdownToHTMLNotification"), object: htmlOutput)
    }
    
    func handleMarkdownToHTMLNotification(notification: Notification) {
        if let html = notification.object as? String {
            let newContent = "<html><head><style>body { background-color: #3498db; color: #ffffff; } </style></head><body>\(html)</body></html>"
            self.showWebView.loadHTMLString(newContent, baseURL: nil)
        }
    }
    
    //
    func convertMarkdownToHTML() {
        if let functionConvertMarkdownToHTML = self.jsContext.objectForKeyedSubscript("convertMarkdownToHTML") {
            print("Input text:",self.inputTextView.text)
            _ = functionConvertMarkdownToHTML.call(withArguments: [self.inputTextView.text!])
        }
    }
    
    @IBAction func convertAction(_ sender: AnyObject) {
        self.convertMarkdownToHTML()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

