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

class EditorViewController: UIViewController, UITextViewDelegate, EditorTextViewDelegate, SearchToolbarDelegate, ProjectDocumentDelegate {
    
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
    
    /*
     @property BOOL wasEditedSinceOpened;
     @property BOOL wasEditedSinceLastRun;
     @property BOOL shouldUpdateSideBar;
     @property (strong) InfoBlock infoBlock;
     @property NSString *infoId;

 */
    
    var document: ProjectDocument?
    
    var keyboardRect = CGRect()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let startItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onRunTapped))
        let searchItem = UIBarButtonItem(image: UIImage(named:"search"), style: .plain, target: self, action: #selector(onSearchTapped))
        let feedbackItem = UIBarButtonItem(image: UIImage(named:"feedback"), style: .plain, target: self, action: #selector(onFeedbackTapped))
        let projectItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onProjectTapped))
        
        navigationItem.rightBarButtonItems = [startItem, searchItem, feedbackItem, projectItem]
        
        view.backgroundColor = AppStyle.editorColor()
        sourceCodeTextView.backgroundColor = AppStyle.editorColor()
        sourceCodeTextView.textColor = AppStyle.tintColor()
        sourceCodeTextView.tintColor = AppStyle.brightColor()
        sourceCodeTextView.indicatorStyle = .white

        navigationItem.title = document?.localizedName
        
        sourceCodeTextView.layoutManager.allowsNonContiguousLayout = false
        sourceCodeTextView.delegate = self
        sourceCodeTextView.editorDelegate = self

        sourceCodeTextView.keyboardAppearance = .dark
        sourceCodeTextView.keyboardToolbar.isTranslucent = true
        sourceCodeTextView.keyboardToolbar.barStyle = .black
        
        sourceCodeTextView.text = document?.sourceCode ?? ""
        
        searchToolbar.searchDelegate = self

        infoView.backgroundColor = AppStyle.warningColor()
        infoLabel.textColor = AppStyle.brightColor()

        indexSideBar.textView = sourceCodeTextView

        keyboardRect = CGRect()

//
//
//        //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveData:) name:ModelManagerWillSaveDataNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpgrade:) name:UpgradeNotification object:nil];
        
        document?.delegate = self
        
        activityIndicatorView.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let document = document {
            if document.documentState == .closed {
                activityIndicatorView.startAnimating()
                document.open(completionHandler: { (success) in
                    self.activityIndicatorView.stopAnimating()
                    if !success {
                        //error
                    }
                })
            }
        }
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateDocument()
        document?.close(completionHandler: nil)
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
        if let document = document {
            /*
             && ![self isExample]
             && ([AppController sharedController].isFullVersion || self.sourceCodeTextView.text.countLines <= EditorDemoMaxLines)
             */
            if sourceCodeTextView.text != document.sourceCode {
                document.sourceCode = sourceCodeTextView.text.uppercased()
                document.updateChangeCount(.done)
            }
        }
    }
    
    
    @objc func onRunTapped(_ sender: Any) {
        updateDocument()
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
    
    @objc func onProjectTapped(_ sender: Any) {
        /*
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak EditorViewController *weakSelf = self;
        
        UIAlertAction *shareCommAction = [UIAlertAction actionWithTitle:@"Share with Community" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onShareTapped:sender community:YES];
            }];
        [alert addAction:shareCommAction];
        
        UIAlertAction *shareMenuAction = [UIAlertAction actionWithTitle:@"Share Source Code" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onShareTapped:sender community:NO];
            }];
        [alert addAction:shareMenuAction];
        
        UIAlertAction *videoMenuAction = [UIAlertAction actionWithTitle:@"Record Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onRecordVideoTapped:sender];
            }];
        [alert addAction:videoMenuAction];
        
        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Rename / Settings..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onSettingsTapped];
            }];
        [alert addAction:settingsAction];
        
        UIAlertAction *duplicateAction = [UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onDuplicateTapped];
            }];
        [alert addAction:duplicateAction];
        
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [weakSelf onDeleteTapped];
            }];
        [alert addAction:deleteAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        
        alert.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:alert animated:YES completion:nil];*/
    }
    
    func onDeleteTapped() {
        /*
     if (self.project.isDefault.boolValue)
     {
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example programs cannot be deleted." message:nil preferredStyle:UIAlertControllerStyleAlert];
     [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
     [self presentViewController:alert animated:YES completion:nil];
     }
     else if (self.sourceCodeTextView.text.length == 0)
     {
     [self deleteProject];
     }
     else
     {
     EditorViewController __weak *weakSelf = self;
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you really want to delete this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
     
     [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
     [weakSelf deleteProject];
     }]];
     
     [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
     
     [self presentViewController:alert animated:YES completion:nil];
     }*/
    }
    
    func deleteProject() {
        /*
     [[ModelManager sharedManager] deleteProject:self.project];
     self.project = nil;
    [self.navigationController popViewControllerAnimated:YES];*/
    }
    
    func onDuplicateTapped() {
        /*
     EditorViewController __weak *weakSelf = self;
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Do you want to make a copy of this program?" message:nil preferredStyle:UIAlertControllerStyleAlert];
     
     [alert addAction:[UIAlertAction actionWithTitle:@"Duplicate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
     [[ModelManager sharedManager] duplicateProject:weakSelf.project sourceCode:weakSelf.sourceCodeTextView.text];
     [[ModelManager sharedManager] saveContext];
     if (weakSelf.project.isDefault.boolValue)
     {
     // default projects are duplicated to the root folder
     [weakSelf.navigationController popToRootViewControllerAnimated:YES];
     }
     else
     {
     // others just go to the current folder
     [weakSelf.navigationController popViewControllerAnimated:YES];
     }
     }]];
     
     [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
     
     [self presentViewController:alert animated:YES completion:nil];*/
    }
    
    func onSettingsTapped() {
    /*
     if (self.project.isDefault.boolValue)
     {
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Settings of example programs cannot be changed." message:nil preferredStyle:UIAlertControllerStyleAlert];
     [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
     [self presentViewController:alert animated:YES completion:nil];
     }
     else
     {
     ProjectSettingsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ProjectSettingsView"];
     vc.delegate = self;
     vc.project = self.project;
     UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
     nav.modalPresentationStyle = vc.modalPresentationStyle;
     nav.modalTransitionStyle = vc.modalTransitionStyle;
     [self presentViewController:nav animated:YES completion:nil];
     }*/
    }
    
    @objc func onFeedbackTapped(_ sender: Any) {
    /*    if (!self.project.postId)
     {
     [self showAlertWithTitle:@"Feedback is available for downloaded or shared programs only" message:nil block:nil];
     }
     else
     {
     LCCPost *post = [[LCCPost alloc] initWithObjectId:self.project.postId];
     [self showPost:post];
     }*/
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
        print(numLines)
        
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
        /*
        if (   [text rangeOfString:@":"].location != NSNotFound
            || (range.length > 0 && [oldText rangeOfString:@":"].location != NSNotFound) )
        {
            self.shouldUpdateSideBar = YES;
        }*/
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // indent
        if let spaces = spacesToInsert {
            spacesToInsert = nil
            textView.insertText(spaces)
        }
        
         /*
        // side bar
        if (self.shouldUpdateSideBar)
        {
            // immediate update
            self.shouldUpdateSideBar = NO;
            [self.indexSideBar update];
        }
        else
        {
            // update later
            self.indexSideBar.shouldUpdateOnTouch = YES;
        }*/
    }
    
    //MARK: - EditorTextViewDelegate
    
    func editorTextView(_ editorTextView: EditorTextView!, didSelectHelpWith range: NSRange) {
/*        NSInteger nextIndex = range.location + range.length;
        if (nextIndex < editorTextView.text.length && [editorTextView.text characterAtIndex:nextIndex] == '$')
        {
            // include "$"
            range.length++;
        }
        NSString *text = [editorTextView.text substringWithRange:range];
        HelpContent *helpContent = [AppController sharedController].helpContent;
        NSArray *results = [helpContent chaptersForSearchText:text];
        if (results.count == 1)
        {
            HelpChapter *chapter = results.firstObject;
            [[AppController sharedController].tabBarController showHelpForChapter:chapter.htmlChapter];
        }
        else if (results.count > 1)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            for (HelpChapter *chapter in results)
            {
                [alert addAction:[UIAlertAction actionWithTitle:chapter.title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[AppController sharedController].tabBarController showHelpForChapter:chapter.htmlChapter];
                    }]];
            }
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            UIPopoverPresentationController *ppc = alert.popoverPresentationController;
            if (ppc)
            {
                ppc.sourceView = self.sourceCodeTextView;
                ppc.sourceRect = [self.sourceCodeTextView.layoutManager boundingRectForGlyphRange:range inTextContainer:self.sourceCodeTextView.textContainer];
                ppc.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
            }
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            NSString *title = [NSString stringWithFormat:@"%@ is not a keyword", text];
            [self showAlertWithTitle:title message:nil block:nil];
        }*/
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
            sourceCodeTextView.selectedRange = NSMakeRange(selectedRange.location + replaceText.characters.count, 0)
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
    
    - (void)onShareTapped:(id)sender community:(BOOL)community
    {
    if (self.sourceCodeTextView.text.length == 0)
    {
    [self showAlertWithTitle:@"This program is empty" message:@"Please write something!" block:nil];
    }
    else if (![AppController sharedController].isFullVersion && self.sourceCodeTextView.text.countLines > EditorDemoMaxLines)
    {
    EditorViewController __weak *weakSelf = self;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please upgrade to full version!"
    message:[NSString stringWithFormat:@"The free version can only share programs with up to %d lines.", EditorDemoMaxLines]
    preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"More Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [weakSelf performSegueWithIdentifier:@"Upgrade" sender:weakSelf];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
    [self saveProject];
    
    if (community)
    {
    //            UIViewController *vc = [ShareViewController createShareWithProject:self.project];
    //            [self presentViewController:vc animated:YES completion:nil];
    }
    else
    {/*
     ActivityItemSource *item = [[ActivityItemSource alloc] init];
     item.project = self.project;
     
     UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:nil];
     
     activityVC.popoverPresentationController.barButtonItem = sender;
     [self presentViewController:activityVC animated:YES completion:nil];*/
    }
    }
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
     NSString *sourceCode = self.sourceCodeTextView.text.uppercaseString;
     NSString *transferSourceCode = [EditorTextView transferText];
     
     NSArray *transferDataNodes;
     
     if (transferSourceCode.length > 0)
     {
     Runnable *runnable = [Compiler compileSourceCode:transferSourceCode error:nil];
     if (runnable)
     {
     transferDataNodes = runnable.dataNodes;
     }
     }
     
     NSError *error;
     
     Runnable *runnable = [Compiler compileSourceCode:sourceCode error:&error];
     if (runnable)
     {
     runnable.transferDataNodes = transferDataNodes;
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
