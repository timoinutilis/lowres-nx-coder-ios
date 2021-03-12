//
//  HelpTextViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 12.03.21.
//  Copyright © 2021 Inutilis Software. All rights reserved.
//

import UIKit
import WebKit

class HelpTextViewController: UIViewController, WKNavigationDelegate {
    
    private var chapter: String?
    
    private var webView: WKWebView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        view.insertSubview(webView, at: 0)
        
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        let helpContent = AppController.shared.helpContent
        webView.loadHTMLString(helpContent.manualHtml, baseURL: helpContent.url)
    }
    
    @objc func setChapter(_ chapter: String) {
        self.chapter = chapter
        if !webView.isLoading {
            jumpToChapter(chapter)
        }
    }
    
    private func jumpToChapter(_ chapter: String) {
        webView.evaluateJavaScript("document.getElementById('\(chapter)').scrollIntoView(true);") { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityView.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityView.stopAnimating()
        if let chapter = chapter {
            jumpToChapter(chapter)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityView.stopAnimating()
    }
    
}
