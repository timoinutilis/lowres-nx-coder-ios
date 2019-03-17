//
//  AboutViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 26/3/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    enum Action {
        case none
        case donate
        case web(URL)
        case contact
        case logout
    }
    
    class MenuEntry {
        let title: String
        let action: Action
        let isBold: Bool
        
        init(title: String, action: Action, isBold: Bool = false) {
            self.title = title
            self.action = action
            self.isBold = isBold
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var coreVersionLabel: UILabel!
    @IBOutlet weak var copyrightLabel: UILabel!
    
    private var menuEntries = [MenuEntry]()
    private var currentUsername: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = "Version \(appVersion)"
        coreVersionLabel.text = "Core \(coreVersion)"
        
        coreVersionLabel.textColor = AppStyle.mediumGrayColor()
        copyrightLabel.textColor = AppStyle.mediumGrayColor()
        tableView.indicatorStyle = .white
        
        menuEntries.append(MenuEntry(title: "Community Forum", action: .web(URL(string: "https://lowresnx.inutilis.com/programs.php")!), isBold: true))
        menuEntries.append(MenuEntry(title: "Rate In App Store", action: .web(URL(string: "https://itunes.apple.com/app/id1318884577?action=write-review")!)))
        menuEntries.append(MenuEntry(title: "Donate To Developer", action: .donate))
        menuEntries.append(MenuEntry(title: "Twitter", action: .web(URL(string: "https://twitter.com/timo_inutilis")!)))
        menuEntries.append(MenuEntry(title: "Inutilis.com", action: .web(URL(string: "http://www.inutilis.com")!)))
        menuEntries.append(MenuEntry(title: "Contact", action: .contact))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLogin()
    }
    
    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        return "\(shortVersion ?? "?") (\(bundleVersion ?? "?"))"
    }
    
    private var coreVersion: String {
        return CORE_VERSION
    }
    
    private func updateLogin() {
        let username = AppController.shared.username
        if username != currentUsername {
            menuEntries.removeAll { (entry) -> Bool in
                switch entry.action {
                case .logout: return true
                default: return false
                }
            }
            if let username = username {
                menuEntries.append(MenuEntry(title: "Log Out (\(username))", action: .logout))
            }
            currentUsername = username
            tableView.reloadData()
        }
    }
    
    private func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let mailViewController = MFMailComposeViewController()
            
            mailViewController.view.tintColor = AppStyle.darkTintColor()
            mailViewController.mailComposeDelegate = self
            
            let device = UIDevice.current
            
            mailViewController.setToRecipients(["support@inutilis.com"])
            mailViewController.setSubject("LowRes NX Coder")
            
            let body = "\n\n\n\n\(device.model)\n\(device.systemName) \(device.systemVersion)\nApp \(appVersion)\nCore \(coreVersion)"
            mailViewController.setMessageBody(body, isHTML: false)
            
            present(mailViewController, animated: true, completion: nil)
        } else {
            let url = URL(string: "mailto:support@inutilis.com")!
            UIApplication.shared.openURL(url)
        }
    }
    
    private func logout() {
        let urlString = ShareViewController.baseUrl.appendingPathComponent("logout.php").absoluteString + "?webmode=app";
        let vc = WebViewController()
        vc.url = URL(string: urlString)!
        vc.title = "Log Out"
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
        
        AppController.shared.didLogOut()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuEntries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = menuEntries[indexPath.row]
        
        switch entry.action {
        case .none:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Info", for: indexPath)
            cell.textLabel!.text = entry.title
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Disclosure", for: indexPath)
            cell.textLabel!.text = entry.title
            cell.textLabel!.font = entry.isBold ? UIFont.boldSystemFont(ofSize: 17) : UIFont.systemFont(ofSize: 17)
            return cell
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = menuEntries[indexPath.row]
        
        switch entry.action {
        case .donate:
            performSegue(withIdentifier: "Donate", sender: self)
            
        case .web(let url):
            UIApplication.shared.openURL(url)
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .contact:
            sendMail()
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .logout:
            logout()
            
        default:
            break
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}
