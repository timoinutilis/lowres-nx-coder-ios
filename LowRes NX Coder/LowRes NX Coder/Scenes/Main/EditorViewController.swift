//
//  EditorViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 28/9/17.
//  Copyright © 2017-2019 Inutilis Software. All rights reserved.
//

import UIKit

class EditorViewController: UIViewController, UITextViewDelegate, EditorTextViewDelegate, SearchToolbarDelegate, ProjectDocumentDelegate, LowResNXViewControllerDelegate {
    
    @IBOutlet weak var sourceCodeTextView: EditorTextView!
    @IBOutlet weak var searchToolbar: SearchToolbar!
    @IBOutlet weak var indexSideBar: IndexSideBar!
    @IBOutlet weak var searchToolbarConstraint: NSLayoutConstraint!
    @IBOutlet weak var indexSideBarConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var didAppearAlready = false
    var didRunProgramAlready = false
    var spacesToInsert: String?
    var shouldUpdateSideBar = false
    var didAddProject = false
    
    private var documentStateChangedObserver: Any?
    var document: ProjectDocument!
    var keyboardRect = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let startItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onRunTapped))
        let searchItem = UIBarButtonItem(image: UIImage(named:"search"), style: .plain, target: self, action: #selector(onSearchTapped))
        let toolsItem = UIBarButtonItem(image: UIImage(named:"tools"), style: .plain, target: self, action: #selector(onToolsTapped))
        let projectItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onProjectTapped))
        
        navigationItem.rightBarButtonItems = [startItem, searchItem, toolsItem, projectItem]
        
        navigationItem.title = document.localizedName
        
        view.backgroundColor = AppStyle.darkGrayColor()
        sourceCodeTextView.backgroundColor = AppStyle.darkGrayColor()
        sourceCodeTextView.textColor = AppStyle.brightTintColor()
        sourceCodeTextView.tintColor = AppStyle.whiteColor()
        sourceCodeTextView.indicatorStyle = .white
        
        sourceCodeTextView.layoutManager.allowsNonContiguousLayout = false
        sourceCodeTextView.delegate = self
        sourceCodeTextView.editorDelegate = self

        sourceCodeTextView.keyboardAppearance = .dark
        if let keyboardToolbar = sourceCodeTextView.keyboardToolbar {
            keyboardToolbar.isTranslucent = true
            keyboardToolbar.barStyle = .black
        }
        
        sourceCodeTextView.text = document.sourceCode ?? ""
        
        searchToolbar.searchDelegate = self

        indexSideBar.textView = sourceCodeTextView

        keyboardRect = CGRect()

        activityIndicatorView.isHidden = true
        sourceCodeTextView.isEditable = false
        
        document.delegate = self
        
        documentStateChangedObserver = NotificationCenter.default.addObserver(forName: .UIDocumentStateChanged, object: document, queue: nil) { [weak self] (notification) in
            self?.documentStateChanged()
        }
        
        if document.documentState.contains(.closed) {
            activityIndicatorView.startAnimating()
            setBarButtonsEnabled(false)
            document.open(completionHandler: { (success) in
                self.activityIndicatorView.stopAnimating()
                self.setBarButtonsEnabled(true)
            })
        } else {
            fatalError("unexpected document state")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(projectManagerDidAddProgram), name: .ProjectManagerDidAddProgram, object: nil)

    }
    
    deinit {
        removeDocumentStateChangedObserver()
        NotificationCenter.default.removeObserver(self)
        updateDocument()
        document.close(completionHandler: nil)
    }
    
    func removeDocumentStateChangedObserver() {
        if let observer = documentStateChangedObserver {
            NotificationCenter.default.removeObserver(observer)
            documentStateChangedObserver = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !didAppearAlready {
            didAppearAlready = true
            
            // hide search bar
            view.layoutIfNeeded()
            searchToolbarConstraint.constant = -searchToolbar.bounds.size.height
            searchToolbar.isHidden = true
        }
        updateEditorInsets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        indexSideBar.update()
        sourceCodeTextView.flashScrollIndicators()
        
        if didAddProject {
            navigationController?.popViewController(animated: true)
            didAddProject = false
        } else if didRunProgramAlready && AppController.shared.numRunProgramsThisVersion >= 20 {
            AppController.shared.requestAppStoreReview()
        }
    }
    
    private func setBarButtonsEnabled(_ enabled: Bool) {
        for item in navigationItem.rightBarButtonItems! {
            item.isEnabled = enabled
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardRect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        updateEditorInsets()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardRect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        updateEditorInsets()
    }
    
    func updateEditorInsets() {
        var insets = UIEdgeInsets()
        if keyboardRect.size.height > 0.0 {
            if let nav = navigationController {
                let rect = nav.view.convert(sourceCodeTextView.frame, from: view)
                let textBottomY = rect.origin.y + rect.size.height
                if self.keyboardRect.origin.y < textBottomY {
                    insets.bottom = textBottomY - keyboardRect.origin.y;
                }
            }
        }
        sourceCodeTextView.contentInset = insets
        sourceCodeTextView.scrollIndicatorInsets = insets
        indexSideBarConstraint.constant = -insets.bottom
    }
    
    @objc func applicationWillResignActive(_ notification: Notification) {
        let app = UIApplication.shared
        var bgTask = UIBackgroundTaskInvalid
        
        bgTask = app.beginBackgroundTask {
            app.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }
        
        updateDocument()
        document.autosave(completionHandler: { (succeeded) in
            app.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        })
    }
    
    @objc func projectManagerDidAddProgram(_ notification: Notification) {
        didAddProject = true
    }
    
    func updateDocument() {
        let state = document.documentState
        if !state.contains(.closed) && sourceCodeTextView.text != document.sourceCode {
            document.sourceCode = sourceCodeTextView.text.uppercased()
            document.updateChangeCount(.done)
        }
    }
    
    func documentStateChanged() {
        let state = document.documentState
        
        if state.contains(.editingDisabled) || state.contains(.closed) {
            sourceCodeTextView.resignFirstResponder()
            sourceCodeTextView.isEditable = false
        } else {
            sourceCodeTextView.isEditable = true
        }
        
        if state.contains(.inConflict) {
            removeDocumentStateChangedObserver()
            showAlert(withTitle: "iCloud Conflict", message: "Solution not yet implemented.", block: {
                self.navigationController?.popViewController(animated: true)
            })
        } else if state.contains(.savingError) {
            showAlert(withTitle: "Saving Error", message: "Solution not yet implemented.", block: nil)
        }
    }
    
    @objc func onRunTapped(_ sender: Any) {
        runProject()
    }
    
    @objc func onSearchTapped(_ sender: Any) {
        view.layoutIfNeeded()
        let wasVisible = (searchToolbarConstraint.constant == 0.0)
        if wasVisible {
            searchToolbarConstraint.constant = -searchToolbar.bounds.size.height;
            searchToolbar.endEditing(true)
        } else {
            searchToolbar.isHidden = false
            searchToolbarConstraint.constant = 0.0
            sourceCodeTextView.endEditing(true)
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            if wasVisible && self.searchToolbarConstraint.constant != 0.0 {
                self.searchToolbar.isHidden = true
            }
        }
    }
    
    @objc func onToolsTapped(_ sender: Any) {
        view.endEditing(true)
        
        let config = ToolsMenuConfiguration()
        
        let alert = UIAlertController(title: "Edit ROM Entries with Tool...", message: nil, preferredStyle: .actionSheet)
        
        for programUrl in config.programUrls {
            let title = programUrl.deletingPathExtension().lastPathComponent
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { [unowned self] (action) in
                self.editUsingTool(url: programUrl)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "More...", style: .default, handler: { [unowned self] (action) in
            self.onToolsMoreTapped(sender, config: config)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem;
        present(alert, animated: true, completion: nil)
    }
    
    func onToolsMoreTapped(_ sender: Any, config: ToolsMenuConfiguration) {
        let alert = UIAlertController(title: "Tools Menu Configuration",
                                      message: "When you run a program from the tools menu, it uses the current program as a virtual disk and can edit its ROM entries.",
                                      preferredStyle: .actionSheet)
        
        let addTitle = "Add \"\(document.localizedName)\""
        alert.addAction(UIAlertAction(title: addTitle, style: .default, handler: { [unowned self] (action) in
            config.addProgram(url: self.document.fileURL)
        }))
        
        alert.addAction(UIAlertAction(title: "Reset Menu", style: .destructive, handler: { (action) in
            config.reset()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem;
        present(alert, animated: true, completion: nil)
    }
    
    @objc func onProjectTapped(_ sender: Any) {
        view.endEditing(true)
        
        if sourceCodeTextView.text.isEmpty {
            showAlert(withTitle: "Cannot Share this Program", message: "This program is empty. Please write something!", block: nil)
        } else {
            updateDocument()
            if document.hasUnsavedChanges {
                BlockerView.show()
            }
            document.autosave(completionHandler: { (success) in
                BlockerView.dismiss()
                if !success {
                    self.showAlert(withTitle: "Could not Save Program", message: nil, block: nil)
                } else {
                    let activityVC = UIActivityViewController(
                        activityItems: [self.document.fileURL],
                        applicationActivities: [ShareActivity()]
                    )
                    activityVC.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
                    self.present(activityVC, animated: true, completion: nil)
                }
            })
        }
    }
    
    func editUsingTool(url: URL) {
        view.endEditing(true)
        updateDocument()
        
        let storyboard = UIStoryboard(name: "LowResNX", bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! LowResNXViewController
        vc.document = ProjectDocument(fileURL: url)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    func runProject() {
        updateDocument()
        
        guard let sourceCode = document.sourceCode else {
            return
        }
        
        let coreWrapper = CoreWrapper()
        let error = coreWrapper.compileProgram(sourceCode: sourceCode)
        
        if let error = error {
            // show error
            let alert = UIAlertController(title: error.message, message: error.line, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Go to Error", style: .default, handler: { [weak self] (action) in
                let range = NSMakeRange(Int(error.coreError.sourcePosition), 0)
                self?.sourceCodeTextView.selectedRange = range
                self?.sourceCodeTextView.becomeFirstResponder()
            }))
            present(alert, animated: true, completion: nil)
            
        } else {
            // start
            view.endEditing(true)
            let storyboard = UIStoryboard(name: "LowResNX", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! LowResNXViewController
            vc.document = document
            vc.coreWrapper = coreWrapper
            present(vc, animated: true, completion: nil)
            
            AppController.shared.numRunProgramsThisVersion += 1
            didRunProgramAlready = true
        }
    }
    
    //MARK: - ProjectDocumentDelegate
    
    func projectDocumentContentDidUpdate(_ projectDocument: ProjectDocument) {
        sourceCodeTextView.text = projectDocument.sourceCode ?? ""
    }
    
    //MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let oldText = (textView.text as NSString).substring(with: range)
        
        // check for indent
        spacesToInsert = nil
        if text == "\n" {
            let nsText = textView.text as NSString
            let lineRange = nsText.lineRange(for: textView.selectedRange)
            for i in 0 ..< lineRange.length {
                if nsText.character(at: lineRange.location + i) != UInt16(32) {
                    spacesToInsert = nsText.substring(with: NSMakeRange(lineRange.location, i))
                    break;
                }
            }
        }
        
        // check for new or deleted label
        if text.range(of: ":") != nil || (range.length > 0 && oldText.range(of: ":") != nil)
        {
            shouldUpdateSideBar = true
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // indent
        if let spaces = spacesToInsert {
            spacesToInsert = nil
            textView.insertText(spaces)
        }
        
        // side bar
        if shouldUpdateSideBar {
            // immediate update
            shouldUpdateSideBar = false
            indexSideBar.update()
        } else {
            // update later
            indexSideBar.shouldUpdateOnTouch = true
        }
    }
    
    //MARK: - EditorTextViewDelegate
    
    func editorTextView(_ editorTextView: EditorTextView, didSelectHelpWith range: NSRange) {
        let text = editorTextView.text!
        let selectedRange = Range(range, in: text)!
        var selectedText = String(text[selectedRange])
        
        var index = selectedRange.upperBound
        if index < text.endIndex {
            if text[index] == "$" {
                // include "$" (e.g. for LEFT$)
                selectedText.append("$")
                index = text.index(after: index)
            } else if text[index] == "." {
                // include "." and following letters (e.g. for SPRITE.X)
                let charSet = CharacterSet(charactersIn: ".ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
                while index < text.endIndex, charSet.contains(text[index].unicodeScalars.first!) {
                    selectedText.append(text[index])
                    index = text.index(after: index)
                }
            }
        }
        
        let helpContent = AppController.shared.helpContent
        let results = helpContent.chapters(forSearchText: selectedText)

        if results.count == 1 {
            let chapter = results.first!
            AppController.shared.tabBarController.showHelp(forChapter: chapter.htmlChapter)
        
        } else if results.count > 1 {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for chapter in results {
                alert.addAction(UIAlertAction(title: chapter.title, style: .default, handler: { (action) in
                    AppController.shared.tabBarController.showHelp(forChapter: chapter.htmlChapter)
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            if let ppc = alert.popoverPresentationController {
                ppc.sourceView = sourceCodeTextView;
                ppc.sourceRect = sourceCodeTextView.layoutManager.boundingRect(forGlyphRange: range, in: sourceCodeTextView.textContainer)
                ppc.permittedArrowDirections = [.up, .down]
            }
            present(alert, animated: true, completion: nil)
            
        } else {
            showAlert(withTitle: "\(selectedText) Is not a Keyword", message: nil, block: nil)
        }
    }
    
    //MARK: - SearchToolbarDelegate
    
    func searchToolbar(_ toolbar: SearchToolbar!, didSearch findText: String!, backwards: Bool) {
        let sourceText = sourceCodeTextView.text as NSString
        
        let selectedRange = sourceCodeTextView.selectedRange
        var startIndex = 0
        var didRestart = false
        if backwards {
            startIndex = selectedRange.location
            if startIndex == 0 {
                startIndex = sourceText.length
                didRestart = true
            }
        } else {
            startIndex = selectedRange.location + selectedRange.length
            if startIndex == sourceText.length {
                startIndex = 0
                didRestart = true
            }
        }
        let found = find(findText, backwards: backwards, startIndex: startIndex)
        if !found && !didRestart {
            startIndex = backwards ? sourceText.length : 0
            _ = find(findText, backwards: backwards, startIndex: startIndex)
        }
    }
    
    func searchToolbar(_ toolbar: SearchToolbar!, didReplace findText: String!, with replaceText: String!) {
        let sourceText = sourceCodeTextView.text as NSString
        
        let selectedRange = sourceCodeTextView.selectedRange
        if sourceText.substring(with: selectedRange) == findText {
            if !sourceCodeTextView.isFirstResponder {
                // activate editor
                sourceCodeTextView.becomeFirstResponder()
                sourceCodeTextView.scrollSelectedRangeToVisible()
                return
            }
            // replace
            let changedSourceText = sourceText.replacingCharacters(in: selectedRange, with: replaceText)
            sourceCodeTextView.text = changedSourceText
            sourceCodeTextView.selectedRange = NSMakeRange(selectedRange.location + replaceText.count, 0)
            sourceCodeTextView.scrollSelectedRangeToVisible()
        }
        
        // find next
        searchToolbar(toolbar, didSearch: findText, backwards: false)
    }
    
    func find(_ findText: String, backwards: Bool, startIndex: Int) -> Bool {
        let sourceText = sourceCodeTextView.text as NSString
        
        let searchRange = backwards ? NSMakeRange(0, startIndex) : NSMakeRange(startIndex, sourceText.length - startIndex)
        let resultRange = sourceText.range(of: findText, options: backwards ? [.caseInsensitive, .backwards] : [.caseInsensitive], range: searchRange)
        
        if resultRange.location != NSNotFound {
            sourceCodeTextView.selectedRange = resultRange
            sourceCodeTextView.becomeFirstResponder()
            sourceCodeTextView.scrollSelectedRangeToVisible()
            return true
        }
        return false
    }
    
    //MARK: - LowResNXViewControllerDelegate
    
    func nxSourceCodeForVirtualDisk() -> String {
        return document.sourceCode ?? ""
    }
    
    func nxDidSaveVirtualDisk(sourceCode: String) {
        if sourceCode != document.sourceCode {
            document.sourceCode = sourceCode
            document.updateChangeCount(.done)
            projectDocumentContentDidUpdate(document)
        }
    }
    
}
