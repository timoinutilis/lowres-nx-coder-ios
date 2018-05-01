//
//  ShareViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 1/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class ShareViewController: UITableViewController {
    
    private var activity: ShareProgramActivity!
    private var programUrl: URL!
    
    func setup(activity: ShareProgramActivity, programUrl: URL) {
        self.activity = activity
        self.programUrl = programUrl
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onCancelTapped(_ sender: Any) {
        activity.activityDidFinish(false)
    }
    
    @IBAction func onPostTapped(_ sender: Any) {
        activity.activityDidFinish(true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
    
}
