//
//  EditorViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 28/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

/*
 int const EditorDemoMaxLines = 24;
 NSString *const CoachMarkIDStart = @"CoachMarkIDStart";
 NSString *const CoachMarkIDShare = @"CoachMarkIDShare";
 NSString *const CoachMarkIDHelp = @"CoachMarkIDHelp";
 
 NSString *const InfoIDExample = @"InfoIDExample";
 NSString *const InfoIDLongProgram = @"InfoIDLongProgram";
 NSString *const InfoIDPaste = @"InfoIDPaste";
 
 typedef void(^InfoBlock)(void);
*/

class EditorViewController: UIViewController, UITextViewDelegate, EditorTextViewDelegate, SearchToolbarDelegate, ProjectDocumentDelegate, LowResNXViewControllerDelegate {
    
    @IBOutlet weak var sourceCodeTextView: EditorTextView!
    @IBOutlet weak var searchToolbar: SearchToolbar!
    @IBOutlet weak var indexSideBar: IndexSideBar!
    @IBOutlet weak var searchToolbarConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var infoViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var indexSideBarConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var numLines: UInt = 0
    var didAppearAlready = false
    var spacesToInsert: String?
    var shouldUpdateSideBar = false
    
    private var documentStateChangedObserver: Any?
    
    /*
     @property BOOL wasEditedSinceOpened;
     @property BOOL wasEditedSinceLastRun;
     @property (strong) InfoBlock infoBlock;
     @property NSString *infoId;

 */
    
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
        
        view.backgroundColor = AppStyle.editorColor()
        sourceCodeTextView.backgroundColor = AppStyle.editorColor()
        sourceCodeTextView.textColor = AppStyle.tintColor()
        sourceCodeTextView.tintColor = AppStyle.brightColor()
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

        infoView.backgroundColor = AppStyle.warningColor()
        infoLabel.textColor = AppStyle.brightColor()

        indexSideBar.textView = sourceCodeTextView

        keyboardRect = CGRect()

//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpgrade:) name:UpgradeNotification object:nil];
        
        activityIndicatorView.isHidden = true
        sourceCodeTextView.isEditable = false
        
        document.delegate = self
        
        documentStateChangedObserver = NotificationCenter.default.addObserver(forName: .UIDocumentStateChanged, object: document, queue: nil) { [weak self] (notification) in
            self?.documentStateChanged()
        }
        
        if document.documentState.contains(.closed) {
            activityIndicatorView.startAnimating()
            document.open(completionHandler: { (success) in
                self.activityIndicatorView.stopAnimating()
            })
        } else {
            fatalError("unexpected document state")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
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
            
            // hide info bar
            infoViewConstraint.constant = -infoView.bounds.size.height
            infoView.isHidden = true
            view.layoutIfNeeded()
        }
        updateEditorInsets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        indexSideBar.update()
        sourceCodeTextView.flashScrollIndicators()
/*
        AppController *app = [AppController sharedController];
        if (app.replayPreviewViewController)
        {
            // Recorded Video!
            app.replayPreviewViewController.previewControllerDelegate = self;
            app.replayPreviewViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:app.replayPreviewViewController animated:YES completion:nil];
        }
             else if (self.project.isDefault.boolValue)
             {
             if ([app isUnshownInfoID:CoachMarkIDStart])
             {
             [app onShowInfoID:CoachMarkIDStart];
             CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Tap the Play button to run this program!" complete:nil];
             [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:0];
             [coachMark show];
             }
             }
             else if (!self.project.isDefault.boolValue && self.wasEditedSinceOpened && self.sourceCodeTextView.text.length >= 200)
             {
             if ([app isUnshownInfoID:CoachMarkIDShare])
             {
             [app onShowInfoID:CoachMarkIDShare];
             CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Are you happy with your program? Share it with the community!" complete:nil];
             [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:3];
             [coachMark show];
             }
             }
        else if ([self.sourceCodeTextView.text isEqualToString:@""])
        {
            if ([app isUnshownInfoID:CoachMarkIDHelp])
            {
                [app onShowInfoID:CoachMarkIDHelp];
                CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Go to the Help tab to learn how to create your own programs!" complete:nil];
                [coachMark setTargetTabBar:[AppController sharedController].tabBarController.tabBar itemIndex:1];
                [coachMark show];
            }
        }*/
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
            let rect = navigationController!.view.convert(sourceCodeTextView.frame, from: view)
            let textBottomY = rect.origin.y + rect.size.height
            if self.keyboardRect.origin.y < textBottomY {
                insets.bottom = textBottomY - keyboardRect.origin.y;
            }
        }
        sourceCodeTextView.contentInset = insets
        sourceCodeTextView.scrollIndicatorInsets = insets
        indexSideBarConstraint.constant = -insets.bottom
    }
    
    func updateDocument() {
        /*
         && ![self isExample]
         && ([AppController sharedController].isFullVersion || self.sourceCodeTextView.text.countLines <= EditorDemoMaxLines)
         */
        
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
        
        let alert = UIAlertController(title: "Edit ROM Entries With ...", message: nil, preferredStyle: .actionSheet)
        
        for programUrl in config.programUrls {
            let title = programUrl.deletingPathExtension().lastPathComponent
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { [unowned self] (action) in
                self.editUsingTool(url: programUrl)
            }))
        }
        
        if !config.programUrls.contains(self.document.fileURL) {
            let addTitle = "Add \"\(document.localizedName)\" to Menu"
            alert.addAction(UIAlertAction(title: addTitle, style: .default, handler: { [unowned self] (action) in
                config.addProgram(url: self.document.fileURL)
            }))
        }
        
        if config.canReset {
            alert.addAction(UIAlertAction(title: "Reset Menu", style: .destructive, handler: { (action) in
                config.reset()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem;
        present(alert, animated: true, completion: nil)
    }
    
    @objc func onProjectTapped(_ sender: Any) {
        view.endEditing(true)
        
        if sourceCodeTextView.text.isEmpty {
            showAlert(withTitle: "Cannot Share This Program", message: "This program is empty. Please write something!", block: nil)
        } else {
            updateDocument()
            if document.hasUnsavedChanges {
                BlockerView.show()
            }
            document.autosave(completionHandler: { (success) in
                BlockerView.dismiss()
                if !success {
                    self.showAlert(withTitle: "Could Not Save Program", message: nil, block: nil)
                } else {
                    let activityVC = UIActivityViewController(activityItems: [self.document.fileURL], applicationActivities: nil)
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
        
        let cString = sourceCode.cString(using: .ascii)
        let error = itp_compileProgram(&coreWrapper.core, cString)
        
        if error.code != ErrorNone {
            // show error
            let nxError = LowResNXError(error: error, sourceCode: sourceCode)
            
            let alert = UIAlertController(title: nxError.message, message: nxError.line, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Go to Error", style: .default, handler: { [weak self] (action) in
                let range = NSMakeRange(Int(error.sourcePosition), 0)
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
        }
    }
    
    //MARK: - ProjectDocumentDelegate
    
    func projectDocumentContentDidUpdate(_ projectDocument: ProjectDocument) {
        sourceCodeTextView.text = projectDocument.sourceCode ?? ""
        numLines = sourceCodeTextView.text.countLines()
    }
    
    //MARK: - UITextViewDelegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
/*        if ([self isExample])
        {
            if (self.infoId != InfoIDExample)
            {
                __weak EditorViewController *weakSelf = self;
                [self showInfo:@"Changes in example programs will not be saved.\nMake a copy?" infoId:InfoIDExample block:^{
                    [weakSelf onDuplicateTapped];
                    }];
            }
        }*/
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
/*        self.wasEditedSinceOpened = YES;
        self.wasEditedSinceLastRun = YES;*/
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let oldText = (textView.text as NSString).substring(with: range)
        let oldTextLineBreaks = oldText.countChar(UInt16(10))
        let newTextLineBreaks = text.countChar(UInt16(10))
        let newNumLines = numLines - oldTextLineBreaks + newTextLineBreaks
/*
        if (![AppController sharedController].isFullVersion)
        {
            __weak EditorViewController *weakSelf = self;
            if (text.length > 1 && newNumLines > EditorDemoMaxLines)
            {
                [self showInfo:@"Cannot paste into long programs.\nShow information about full version?" infoId:InfoIDPaste block:^{
                    [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
                    }];
                return NO;
            }
            
            if (self.infoId != InfoIDLongProgram && ![self isExample] && newNumLines > EditorDemoMaxLines)
            {
                [self showInfo:@"Changes in long programs will not be saved.\nShow information about full version?" infoId:InfoIDLongProgram block:^{
                    [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
                    }];
            }
            else if ([self isExample])
            {
                if (self.infoId != InfoIDExample)
                {
                    [self showInfo:@"Changes in example programs will not be saved.\nMake a copy?" infoId:InfoIDExample block:^{
                        [weakSelf onDuplicateTapped];
                        }];
                }
            }
            else if (newNumLines <= EditorDemoMaxLines || self.infoId == InfoIDPaste)
            {
                [self hideInfo];
            }
        }
        */
        numLines = newNumLines
        
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
        
        let helpContent = AppController.shared().helpContent!
        let results = helpContent.chapters(forSearchText: selectedText)

        if results.count == 1 {
            let chapter = results.first!
            AppController.shared().tabBarController.showHelp(forChapter: chapter.htmlChapter)
        
        } else if results.count > 1 {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for chapter in results {
                alert.addAction(UIAlertAction(title: chapter.title, style: .default, handler: { (action) in
                    AppController.shared().tabBarController.showHelp(forChapter: chapter.htmlChapter)
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
            showAlert(withTitle: "\(selectedText) is not a keyword", message: nil, block: nil)
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

/*
    

     - (void)didUpgrade:(NSNotification *)notification
     {
     if (self.infoId && self.infoId != InfoIDExample)
     {
     [self hideInfo];
     }
     
     }


    
     

    - (void)projectSettingsDidChange
    {
    //    self.navigationItem.title = self.project.name;
    }
    
    - (void)showPost:(LCCPost *)post
    {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    CommPostViewController *vc = (CommPostViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommPostView"];
    [vc setPost:post mode:CommPostModePost];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
    }
    

    - (void)onRecordVideoTapped:(id)sender
    {
    if (![RPScreenRecorder class])
    {
    [self showAlertWithTitle:@"Recording is not available" message:@"Please update your device to iOS 9 or higher!" block:nil];
    }
    else if (![RPScreenRecorder sharedRecorder].available)
    {
    [self showAlertWithTitle:@"Recording is not available" message:@"Your device doesn't support screen recording or the recorder is currently not usable." block:nil];
    }
    else
    {
    __weak EditorViewController *weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Video Recording"
    message:@"Please make videos in landscape orientation and in fullscreen mode whenever possible."
    preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Record Screen & Microphone" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //            [weakSelf runProgramWithRecordingMode:RecordingModeScreenAndMic];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Record Screen Only" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //            [weakSelf runProgramWithRecordingMode:RecordingModeScreen];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    }
    }
    
    - (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
    {
    dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissViewControllerAnimated:YES completion:nil];
    [AppController sharedController].replayPreviewViewController = nil;
    });
    }
    
    #pragma mark - Search and Replace
    

    
     

    
    #pragma mark - Info bar
    
    - (void)showInfo:(NSString *)text infoId:(NSString *)infoId block:(InfoBlock)block
    {
    self.infoBlock = block;
    self.infoId = infoId;
    
    if (self.infoViewConstraint.constant != 0.0)
    {
    self.infoLabel.text = text;
    [self.view layoutIfNeeded];
    self.infoView.hidden = NO;
    self.infoViewConstraint.constant = 0.0;
    
    [UIView animateWithDuration:0.3 animations:^{
    [self.view layoutIfNeeded];
    }];
    }
    else
    {
    [UIView transitionWithView:self.infoView duration:0.3 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
    self.infoLabel.text = text;
    } completion:nil];
    }
    }
    
    - (void)hideInfo
    {
    self.infoBlock = nil;
    self.infoId = nil;
    
    if (self.infoViewConstraint.constant == 0.0)
    {
    [self.view layoutIfNeeded];
    self.infoViewConstraint.constant = -self.infoView.bounds.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
    [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    if (self.infoViewConstraint.constant != 0.0)
    {
    self.infoView.hidden = YES;
    }
    }];
    }
    }
    
    - (IBAction)onInfoTapped:(id)sender
    {
    if (self.infoBlock)
    {
    self.infoBlock();
    }
    }
    
    #pragma mark - Compile and run
    /*
     - (void)runProgramWithRecordingMode:(RecordingMode)recordingMode
     {
     NSError *error;
     
     Runnable *runnable = [Compiler compileSourceCode:sourceCode error:&error];
     if (runnable)
     {
     runnable.recordingMode = recordingMode;
     [self run:runnable];
     }
     else if (error)
     {
     NSUInteger errorPosition = error.programPosition;
     NSString *line = [sourceCode substringWithLineAtIndex:errorPosition];
     EditorViewController __weak *weakSelf = self;
     
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:error.localizedDescription message:line preferredStyle:UIAlertControllerStyleAlert];
     [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
     [alert addAction:[UIAlertAction actionWithTitle:@"Go to Error" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
     NSRange range = NSMakeRange(errorPosition, 0);
     weakSelf.sourceCodeTextView.selectedRange = range;
     [weakSelf.sourceCodeTextView becomeFirstResponder];
     }]];
     [self presentViewController:alert animated:YES completion:nil];
     }
     }
     
     
     - (void)run:(Runnable *)runnable
     {
     RunnerViewController *vc = (RunnerViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"Runner"];
     vc.project = self.project;
     vc.runnable = runnable;
     vc.wasEditedSinceLastRun = self.wasEditedSinceLastRun;
     vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
     [self presentViewController:vc animated:YES completion:nil];
     
     self.wasEditedSinceLastRun = NO;
     }
     */
    - (BOOL)isExample
    {
    return self.project.isDefault;
    }
*/
}
