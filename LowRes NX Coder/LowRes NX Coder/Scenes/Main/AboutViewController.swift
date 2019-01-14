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
        case upgrade
        case web(URL)
        case contact
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = "Version \(appVersion)"
        coreVersionLabel.text = "Core \(coreVersion)"
        
        menuEntries.append(MenuEntry(title: "This is a free preview version of the app. Later versions will have limitations in the editor, which will require an in-app purchase to unlock the full experience. However, playing games will always be free.", action: .none))
        
        if !AppController.shared().isFullVersion {
            menuEntries.append(MenuEntry(title: "Full Version", action: .upgrade))
        }
        menuEntries.append(MenuEntry(title: "Community Forum", action: .web(URL(string: "https://lowresnx.inutilis.com/programs.php")!), isBold: true))
        menuEntries.append(MenuEntry(title: "Twitter", action: .web(URL(string: "https://twitter.com/timo_inutilis")!)))
        menuEntries.append(MenuEntry(title: "inutilis.com", action: .web(URL(string: "http://www.inutilis.com")!)))
        menuEntries.append(MenuEntry(title: "Rate in App Store", action: .web(URL(string: "itms-apps://itunes.apple.com/app/id1318884577")!)))
        menuEntries.append(MenuEntry(title: "Contact", action: .contact))
    }
    
    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        return "\(shortVersion ?? "?") (\(bundleVersion ?? "?"))"
    }
    
    private var coreVersion: String {
        return CORE_VERSION
    }
    
    private func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let mailViewController = MFMailComposeViewController()
            
            mailViewController.view.tintColor = AppStyle.tintColor()
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
        case .upgrade:
            performSegue(withIdentifier: "Upgrade", sender: self)
            
        case .web(let url):
            UIApplication.shared.openURL(url)
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .contact:
            sendMail()
            tableView.deselectRow(at: indexPath, animated: true)
            
        default:
            break
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}
