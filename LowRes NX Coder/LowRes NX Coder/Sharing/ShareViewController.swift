//
//  ShareViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 15/03/2019.
//  Copyright © 2019 Inutilis Software. All rights reserved.
//

import UIKit
import WebKit

class ShareViewController: UIViewController, WKNavigationDelegate {

    weak var activity: ShareActivity?
    var programUrl: URL?
    var imageUrl: URL?
    
    private var webView: WKWebView!
    private var activityView: UIActivityIndicatorView!
    
    override func loadView() {
        webView = WKWebView(frame: CGRect.zero)
        webView.backgroundColor = AppStyle.darkGrayColor()
        webView.isOpaque = false
        webView.scrollView.indicatorStyle = .white
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Post To Forum"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityView.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        
        let urlRequest = URLRequest(url: URL(string: "http://localhost:8888/app_auth.php")!)
        webView.load(urlRequest)
    }
    
    @objc func cancel(_ sender: Any) {
        webView.stopLoading()
        activity?.activityDidFinish(false)
    }
    
    func uploadProgram() {
        guard let programUrl = programUrl, let imageUrl = imageUrl else {
            showError()
            return
        }
        
        do {
            let programData = try Data(contentsOf: programUrl)
            let imageData = try Data(contentsOf: imageUrl)
            
            var urlRequest = URLRequest(url: URL(string: "http://localhost:8888/app_posting.php")!)
            urlRequest.httpMethod = "POST"
            urlRequest.setMultipartBody(parameters: [
                "program_file": MultipartFile(filename: programUrl.lastPathComponent, data: programData, mime: "text/plain"),
                "image_file": MultipartFile(filename: imageUrl.lastPathComponent, data: imageData, mime: "image/png")
            ])
            webView.load(urlRequest)
        } catch {
            showError(error)
        }
    }
    
    func showError(_ error: Error? = nil) {
        showAlert(withTitle: "Something Went Wrong", message: error?.localizedDescription) {
            self.webView.stopLoading()
            self.activity?.activityDidFinish(false)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.path == "/topic.php" {
                activityView.stopAnimating()
                decisionHandler(.cancel)
                
                let alert = UIAlertController(title: "Your program has been published successfully.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Open In Safari", style: .default, handler: { (action) in
                    UIApplication.shared.openURL(url)
                    self.activity?.activityDidFinish(true)
                }))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self.activity?.activityDidFinish(true)
                }))
                present(alert, animated: true, completion: nil)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
        
        if let response = navigationResponse.response as? HTTPURLResponse {
            if  let userId = response.allHeaderFields["x-lowresnx-user-id"] as? String,
                let username = response.allHeaderFields["x-lowresnx-username"] as? String {
                
                AppController.shared.didLogIn(userId: userId, username: username)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.uploadProgram()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityView.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityView.stopAnimating()
        showError(error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityView.stopAnimating()
    }
    
}
