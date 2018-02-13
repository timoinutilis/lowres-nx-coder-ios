//
//  LowResNXViewController.swift
//  LowRes NX iOS
//
//  Created by Timo Kloss on 1/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit
import GameController

protocol LowResNXViewControllerDelegate: class {
    func nxSourceCodeForVirtualDisk() -> String
    func nxDidSaveVirtualDisk(sourceCode: String)
}

class LowResNXViewController: UIViewController, UIKeyInput, CoreWrapperDelegate {
    
    @IBOutlet private weak var exitButton: UIButton!
    @IBOutlet private weak var nxView: LowResNXView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet var gamepadConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var p1Dpad: Dpad!
    @IBOutlet weak var p1ButtonA: UIButton!
    @IBOutlet weak var p1ButtonB: UIButton!
    @IBOutlet weak var p1ButtonA2: UIButton!
    @IBOutlet weak var p1ButtonB2: UIButton!
    @IBOutlet weak var p2Dpad: Dpad!
    @IBOutlet weak var p2ButtonA: UIButton!
    @IBOutlet weak var p2ButtonB: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    weak var delegate: LowResNXViewControllerDelegate?
    var document: ProjectDocument?
    var diskDocument: ProjectDocument?
    var coreWrapper: CoreWrapper?
    var isDebugEnabled = false
    
    private var displayLink: CADisplayLink?
    private var compilerError: NSError?
    private var hasAppeared: Bool = false
    private var recognizer: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let document = document else {
            return
        }
        
        if let coreWrapper = coreWrapper {
            // program already compiled
            core_willRunProgram(&coreWrapper.core, Int(CFAbsoluteTimeGetCurrent() - AppController.shared().bootTime))
            core_setDebug(&coreWrapper.core, isDebugEnabled)
            
        } else {
            // program not yet compiled, open document and compile...
            coreWrapper = CoreWrapper()
            
            if document.documentState == .closed {
                document.open(completionHandler: { [weak self] (success) in
                    guard let strongSelf = self else {
                        return
                    }
                    var error: NSError?
                    if success, let sourceCode = document.sourceCode {
                        error = strongSelf.compileAndStartProgram(sourceCode: sourceCode)
                    } else {
                        error = NSError(domain: "LowResNXCoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could Not Open File"])
                    }
                    if let error = error {
                        if strongSelf.hasAppeared {
                            strongSelf.showError(error)
                        } else {
                            strongSelf.compilerError = error
                        }
                    }
                })
            } else if document.documentState == .normal {
                if let sourceCode = document.sourceCode {
                    compilerError = compileAndStartProgram(sourceCode: sourceCode)
                }
            }
        }
        
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        nxView.coreWrapper = coreWrapper
        
        coreWrapper.delegate = self
        configureGameControllers()
        
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.isEnabled = false
        view.addGestureRecognizer(recognizer)
        self.recognizer = recognizer
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        self.displayLink = displayLink
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect), name: .GCControllerDidDisconnect, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var traitCollection: UITraitCollection {
        let size = view.bounds.size
        var traits: [UITraitCollection]
        if size.width > size.height {
            traits = [UITraitCollection(horizontalSizeClass: .regular), UITraitCollection(verticalSizeClass: .compact)]
        } else {
            traits =  [UITraitCollection(horizontalSizeClass: .compact), UITraitCollection(verticalSizeClass: .regular)]
        }
        return UITraitCollection(traitsFrom: traits)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        
        displayLink?.add(to: .current, forMode: .defaultRunLoopMode)
        
        if let error = compilerError {
            showError(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        displayLink?.invalidate()
        
        diskDocument?.close(completionHandler: nil)
        diskDocument = nil
    }
    
    override var prefersStatusBarHidden: Bool {
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.delegate?.window {
                if window?.safeAreaInsets.top != 0 {
                    return false
                }
            }
        }
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let screenWidth = containerView.bounds.size.width
        let screenHeight = containerView.bounds.size.height
        var maxWidthFactor: CGFloat
        var maxHeightFactor: CGFloat
        
        // pixel exact scaling
        let scale: CGFloat = view.window?.screen.scale ?? 1.0
        maxWidthFactor = floor(screenWidth * scale / CGFloat(SCREEN_WIDTH)) / scale
        maxHeightFactor = floor(screenHeight * scale / CGFloat(SCREEN_HEIGHT)) / scale
        
        widthConstraint.constant = (maxWidthFactor < maxHeightFactor) ? maxWidthFactor * CGFloat(SCREEN_WIDTH) : maxHeightFactor * CGFloat(SCREEN_WIDTH)
    }
    
    func compileAndStartProgram(sourceCode: String) -> LowResNXError? {
        guard let coreWrapper = coreWrapper else {
            return nil
        }
        
        let cString = sourceCode.cString(using: .ascii)
        let error = itp_compileProgram(&coreWrapper.core, cString)
        if error.code != ErrorNone {
            return LowResNXError(error: error, sourceCode: sourceCode)
        } else {
            core_willRunProgram(&coreWrapper.core, Int(CFAbsoluteTimeGetCurrent() - AppController.shared().bootTime))
            core_setDebug(&coreWrapper.core, isDebugEnabled)
        }
        return nil
    }
    
    @objc func update(displaylink: CADisplayLink) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        updateGameControllers()
        updateOnscreenGamepads()
        
        let oldNumPlayers = core_getNumGamepads(&coreWrapper.core)
        core_update(&coreWrapper.core, &coreWrapper.input)
        let newNumPlayers = core_getNumGamepads(&coreWrapper.core)
        
        if newNumPlayers != oldNumPlayers {
            configureGameControllers()
        }
        nxView.render()
    }
    
    func configureGameControllers() {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        let numPlayers = Int(core_getNumGamepads(&coreWrapper.core))
        let gameControllers = GCController.controllers()
        
        var count = 0
        for gameController in gameControllers {
            gameController.playerIndex = GCControllerPlayerIndex(rawValue: count)!
            gameController.controllerPausedHandler = { [weak self] (controller) in
                if let coreWrapper = self?.coreWrapper {
                    coreWrapper.input.pause = true
                }
            }
            count += 1
        }
        
        let numOnscreenGamepads = max(0, numPlayers - count)
        
        p1Dpad.isHidden = numOnscreenGamepads < 1
        p1ButtonA.isHidden = numOnscreenGamepads != 1
        p1ButtonB.isHidden = numOnscreenGamepads != 1
        p1ButtonA2.isHidden = numOnscreenGamepads < 2
        p1ButtonB2.isHidden = numOnscreenGamepads < 2
        p2Dpad.isHidden = numOnscreenGamepads < 2
        p2ButtonA.isHidden = numOnscreenGamepads < 2
        p2ButtonB.isHidden = numOnscreenGamepads < 2
        pauseButton.isHidden = numOnscreenGamepads == 0
        
        for constraint in gamepadConstraints {
            constraint.priority = UILayoutPriority(rawValue: numOnscreenGamepads > 0 ? 999 : 1)
        }
    }
    
    func updateGameControllers() {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        for gameController in GCController.controllers() {
            if let gamepad = gameController.gamepad, gameController.playerIndex != .indexUnset {
                var up = gamepad.dpad.up.isPressed
                var down = gamepad.dpad.down.isPressed
                var left = gamepad.dpad.left.isPressed
                var right = gamepad.dpad.right.isPressed
                if let stick = gameController.extendedGamepad?.leftThumbstick {
                    up = up || stick.up.isPressed
                    down = down || stick.down.isPressed
                    left = left || stick.left.isPressed
                    right = right || stick.right.isPressed
                }
                let buttonA = gamepad.buttonA.isPressed || gamepad.buttonX.isPressed
                let buttonB = gamepad.buttonB.isPressed || gamepad.buttonY.isPressed
                
                let player = gameController.playerIndex.rawValue
                core_setInputGamepad(&coreWrapper.input, CInt(player), up, down, left, right, buttonA, buttonB)
            }
        }
    }
    
    func updateOnscreenGamepads() {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        let numGameControllers = GCController.controllers().count
        let numPlayers = Int(core_getNumGamepads(&coreWrapper.core))
        let numOnscreenGamepads = numPlayers - numGameControllers
        
        if numOnscreenGamepads >= 1 {
            core_setInputGamepad(&coreWrapper.input, CInt(numGameControllers),
                                 p1Dpad.isDirUp, p1Dpad.isDirDown, p1Dpad.isDirLeft, p1Dpad.isDirRight,
                                 p1ButtonA.isHighlighted || p1ButtonA2.isHighlighted,
                                 p1ButtonB.isHighlighted || p1ButtonB2.isHighlighted)
        }
        
        if numOnscreenGamepads >= 2 {
            core_setInputGamepad(&coreWrapper.input, CInt(numGameControllers + 1),
                                 p2Dpad.isDirUp, p2Dpad.isDirDown, p2Dpad.isDirLeft, p2Dpad.isDirRight,
                                 p2ButtonA.isHighlighted,
                                 p2ButtonB.isHighlighted)
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            becomeFirstResponder()
        }
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        coreWrapper.input.pause = true
    }
    
    override var canBecomeFirstResponder: Bool {
        guard let coreWrapper = coreWrapper else {
            return false
        }
        
        return core_getKeyboardEnabled(&coreWrapper.core)
    }
    
    private func showError(_ error: NSError) {
        var title: String?
        var message: String?
        if let nxError = error as? LowResNXError {
            title = nxError.message
            message = nxError.line
        } else {
            title = error.localizedDescription
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let frameValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let frame = frameValue.cgRectValue
            keyboardConstraint.constant = view.bounds.size.height - frame.origin.y
            UIView.animate(withDuration: 0.3, animations: { 
                self.view.layoutIfNeeded()
            })
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        keyboardConstraint.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func controllerDidConnect(_ notification: NSNotification) {
        configureGameControllers()
    }

    @objc func controllerDidDisconnect(_ notification: NSNotification) {
        configureGameControllers()
    }
    
    @IBAction func onExitTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Core Wrapper Delegate
    
    func coreInterpreterDidFail(coreError: CoreError) {
        let interpreterError = LowResNXError(error: coreError, sourceCode: document!.sourceCode!)
        showError(interpreterError)
    }
    
    func coreDiskDriveWillAccess(diskDataManager: UnsafeMutablePointer<DataManager>?) -> Bool {
        if let delegate = delegate {
            // tool editing current program
            let diskSourceCode = delegate.nxSourceCodeForVirtualDisk()
            let cDiskSourceCode = diskSourceCode.cString(using: .ascii)
            data_import(diskDataManager, cDiskSourceCode, true)
        } else {
            // tool editing shared disk file
            if let diskDocument = diskDocument {
                let cDiskSourceCode = (diskDocument.sourceCode ?? "").cString(using: .ascii)
                data_import(diskDataManager, cDiskSourceCode, true)
            } else {
                ProjectManager.shared.getDiskDocument(completion: { (document, error) in
                    if let document = document {
                        self.diskDocument = document
                        let cDiskSourceCode = (document.sourceCode ?? "").cString(using: .ascii)
                        data_import(diskDataManager, cDiskSourceCode, true)
                        self.showAlert(withTitle: "Using “Disk.nx” as Virtual Disk", message: nil, block: {
                            core_diskLoaded(&self.coreWrapper!.core)
                        })
                    } else {
                        self.showAlert(withTitle: "Could Not Access Virtual Disk", message: error?.localizedDescription, block: {
                            self.presentingViewController?.dismiss(animated: true, completion: nil)
                        })
                    }
                })
                return false
            }
        }
        return true
    }
    
    func coreDiskDriveDidSave(diskDataManager: UnsafeMutablePointer<DataManager>?) {
        let output = data_export(diskDataManager)
        if let output = output, let diskSourceCode = String(cString: output, encoding: .ascii) {
            if let delegate = delegate {
                // tool editing current program
                delegate.nxDidSaveVirtualDisk(sourceCode: diskSourceCode)
            } else {
                // tool editing shared disk file
                if let diskDocument = diskDocument {
                    diskDocument.sourceCode = diskSourceCode
                    diskDocument.updateChangeCount(.done)
                } else {
                    print("No virtual disk available.")
                }
            }
        }
        free(output)
    }
    
    func coreControlsDidChange(controlsInfo: ControlsInfo) {
        DispatchQueue.main.async {
            if controlsInfo.isKeyboardEnabled {
                self.recognizer?.isEnabled = true
                self.becomeFirstResponder()
            } else {
                self.recognizer?.isEnabled = false
                self.resignFirstResponder()
            }
        }
    }
    
    // MARK: - UIKeyInput
    
    var autocorrectionType: UITextAutocorrectionType = .no
    var spellCheckingType: UITextSpellCheckingType = .no
    var keyboardAppearance: UIKeyboardAppearance = .dark
    
    var hasText: Bool {
        return true
    }
    
    func insertText(_ text: String) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        if text == "\n" {
            coreWrapper.input.key = 10
        } else if let key = text.uppercased().unicodeScalars.first?.value {
            if key < 127 {
                coreWrapper.input.key = Int8(key)
            }
        }
    }
    
    func deleteBackward() {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        coreWrapper.input.key = 8
    }
    
    // this is from UITextInput, needed because of crash on iPhone 6 keyboard (left/right arrows)
    var selectedTextRange: UITextRange? {
        return nil
    }
    
}

