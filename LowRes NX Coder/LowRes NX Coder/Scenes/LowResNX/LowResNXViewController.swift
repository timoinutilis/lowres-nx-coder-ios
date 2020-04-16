//
//  LowResNXViewController.swift
//  LowRes NX iOS
//
//  Created by Timo Kloss on 1/9/17.
//  Copyright © 2017-2019 Inutilis Software. All rights reserved.
//

import UIKit
import GameController
import ReplayKit

#if targetEnvironment(simulator)
let SUPPORTS_GAME_CONTROLLERS = false
#else
let SUPPORTS_GAME_CONTROLLERS = true
#endif

protocol LowResNXViewControllerDelegate: class {
    func didChangeDebugMode(enabled: Bool)
    func didEndWithError(_ error: LowResNXError)
}

protocol LowResNXViewControllerToolDelegate: class {
    func nxSourceCodeForVirtualDisk() -> String
    func nxDidSaveVirtualDisk(sourceCode: String)
}

struct WebSource {
    let name: String
    let programUrl: URL
    let imageUrl: URL?
    let topicId: String?
}

class LowResNXViewController: UIViewController, UIKeyInput, CoreWrapperDelegate, RPPreviewViewControllerDelegate {
    
    let screenshotScaleFactor: CGFloat = 4.0
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var nxView: LowResNXView!
    
    @IBOutlet weak var p1Dpad: Dpad!
    @IBOutlet weak var p1ButtonA: ActionButton!
    @IBOutlet weak var p1ButtonB: ActionButton!
    @IBOutlet weak var p2Dpad: Dpad!
    @IBOutlet weak var p2ButtonA: ActionButton!
    @IBOutlet weak var p2ButtonB: ActionButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    weak var delegate: LowResNXViewControllerDelegate?
    weak var toolDelegate: LowResNXViewControllerToolDelegate?
    var webSource: WebSource?
    var document: ProjectDocument?
    var diskDocument: ProjectDocument?
    var coreWrapper: CoreWrapper?
    var imageData: Data?
    
    var isDebugEnabled = false {
        didSet {
            if let coreWrapper = coreWrapper {
                core_setDebug(&coreWrapper.core, isDebugEnabled)
            }
        }
    }
    
    var isSafeScaleEnabled = false {
        didSet {
            configureGameControllers()
        }
    }
    
    private var controlsInfo: ControlsInfo = ControlsInfo()
    private var displayLink: CADisplayLink?
    private var errorToShow: Error?
    private var recognizer: UITapGestureRecognizer?
    private var startDate: Date!
    private var audioPlayer: LowResNXAudioPlayer!
    private var numOnscreenGamepads = 0
    private var keyboardTop: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDate = Date()
        
        isSafeScaleEnabled = AppController.shared.isSafeScaleEnabled
        
        p1ButtonA.action = .a
        p1ButtonB.action = .b
        p2ButtonA.action = .a
        p2ButtonB.action = .b
        
        if let coreWrapper = coreWrapper {
            // program already compiled
            core_willRunProgram(&coreWrapper.core, Int(CFAbsoluteTimeGetCurrent() - AppController.shared.bootTime))
            core_setDebug(&coreWrapper.core, isDebugEnabled)
            
        } else if let webSource = webSource {
            // load program from web
            coreWrapper = CoreWrapper()
            
            let group = DispatchGroup()
            var sourceCode: String?
            var groupError: Error?
            
            group.enter()
            DispatchQueue.global().async {
                do {
                    sourceCode = try String(contentsOf: webSource.programUrl, encoding: .utf8)
                } catch {
                    groupError = error
                }
                group.leave()
            }
            
            if let imageUrl = webSource.imageUrl {
                group.enter()
                DispatchQueue.global().async {
                    self.imageData = try? Data(contentsOf: imageUrl)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if let sourceCode = sourceCode {
                    if let topicId = webSource.topicId {
                        self.countPlay(topicId: topicId)
                    }
                    let error = self.compileAndStartProgram(sourceCode: sourceCode)
                    if let error = error {
                        self.showError(error)
                    }
                } else if let error = groupError {
                    self.showError(error)
                }
            }
            
        } else {
            // program not yet compiled, open document and compile...
            coreWrapper = CoreWrapper()
            
            guard let document = document else {
                fatalError("CoreWrapper or Document required")
            }
            
            if document.documentState == .closed {
                document.open(completionHandler: { [weak self] (success) in
                    guard let strongSelf = self else {
                        return
                    }
                    var error: NSError?
                    if success, let sourceCode = document.sourceCode {
                        error = strongSelf.compileAndStartProgram(sourceCode: sourceCode)
                    } else {
                        error = NSError(domain: "LowResNXCoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not Open File"])
                    }
                    if let error = error {
                        strongSelf.showError(error)
                    }
                })
            } else if document.documentState == .normal {
                if let sourceCode = document.sourceCode {
                    errorToShow = compileAndStartProgram(sourceCode: sourceCode)
                }
            }
        }
        
        guard let coreWrapper = coreWrapper else {
            assertionFailure()
            return
        }
        
        nxView.coreWrapper = coreWrapper
        audioPlayer = LowResNXAudioPlayer(coreWrapper: coreWrapper)
        
        coreWrapper.delegate = self
        configureGameControllers()
        
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.isEnabled = false
        view.addGestureRecognizer(recognizer)
        self.recognizer = recognizer
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        if #available(iOS 10.0, *) {
            displayLink.preferredFramesPerSecond = 60
        } else {
            displayLink.frameInterval = 1
        }
        self.displayLink = displayLink
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect), name: .GCControllerDidDisconnect, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayLink?.add(to: .current, forMode: .default)
        checkShowError()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        
        displayLink?.invalidate()
        
        audioPlayer.stop()
        
        diskDocument?.close(completionHandler: nil)
        diskDocument = nil
        
        if let coreWrapper = coreWrapper {
            core_willSuspendProgram(&coreWrapper.core)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
//        if #available(iOS 11.0, *) {
//            if let window = UIApplication.shared.delegate?.window {
//                if window?.safeAreaInsets.top != 0 {
//                    return false
//                }
//            }
//        }
        return true
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let top: CGFloat
        let left: CGFloat
        let right: CGFloat
        let bottom: CGFloat
        
        if #available(iOS 11.0, *) {
            top = view.safeAreaInsets.top
            left = view.safeAreaInsets.left
            right = view.bounds.width - view.safeAreaInsets.right
            bottom = view.bounds.height - view.safeAreaInsets.bottom
        } else {
            top = 0
            left = 0
            right = view.bounds.width
            bottom = view.bounds.height
        }
        
        let width: CGFloat = right - left
        let height: CGFloat = bottom - top
        
        exitButton.frame = CGRect(x: left, y: top, width: 44, height: 44)
        menuButton.frame = CGRect(x: right - 44, y: top, width: 44, height: 44)
        pauseButton.frame = CGRect(x: (left + right - 44) * 0.5, y: bottom - 44, width: 44, height: 44)
        
        var containerRect: CGRect
        
        let isBig = !(numOnscreenGamepads >= 2 && (view.bounds.height <= 320 || view.bounds.width <= 320))
        p1Dpad.isBig = isBig
        p2Dpad.isBig = isBig
        p1ButtonA.isBig = isBig
        p1ButtonB.isBig = isBig
        p2ButtonA.isBig = isBig
        p2ButtonB.isBig = isBig
        
        let padSize: CGFloat = isBig ? 132 : 88
        let buttonSize: CGFloat = isBig ? 66 : 44
        
        if height > width {
            // portrait
            containerRect = CGRect(x: left, y: top + 44, width: width, height: width * 4.0 / 5.0)
            
            let buttonsTop = containerRect.maxY + 16
            
            p1Dpad.frame = CGRect(x: left + 16, y: buttonsTop, width: padSize, height: padSize)
            
            if numOnscreenGamepads == 1 {
                p1ButtonA.frame = CGRect(x: right - 16 - 2 * buttonSize, y: buttonsTop + buttonSize, width: buttonSize, height: buttonSize)
                p1ButtonB.frame = CGRect(x: right - 16 - buttonSize, y: buttonsTop, width: buttonSize, height: buttonSize)
            } else if numOnscreenGamepads == 2 {
                p2Dpad.frame = CGRect(x: right - 16 - padSize, y: buttonsTop, width: padSize, height: padSize)
                p1ButtonA.frame = CGRect(x: left + 16 + buttonSize, y: bottom - 16 - buttonSize, width: buttonSize, height: buttonSize)
                p1ButtonB.frame = CGRect(x: left + 16, y: bottom - 16 - 2 * buttonSize, width: buttonSize, height: buttonSize)
                p2ButtonA.frame = CGRect(x: right - 16 - 2 * buttonSize, y: bottom - 16 - buttonSize, width: buttonSize, height: buttonSize)
                p2ButtonB.frame = CGRect(x: right - 16 - buttonSize, y: bottom - 16 - 2 * buttonSize, width: buttonSize, height: buttonSize)
            }
        } else {
            // landscape
            if isSafeScaleEnabled && numOnscreenGamepads >= 1 {
                let safeMargin = 16 + padSize
                containerRect = CGRect(x: left + safeMargin, y: top, width: width - 2 * safeMargin, height: height)
            } else {
                containerRect = CGRect(x: left, y: top, width: width, height: height)
            }
            
            if let keyboardTop = keyboardTop, containerRect.maxY > keyboardTop {
                containerRect.size.height = keyboardTop - containerRect.minY
            }
            
            let buttonAY = bottom - 16 - buttonSize
            let buttonBY = bottom - 16 - 2 * buttonSize
            
            if numOnscreenGamepads == 1 {
                p1Dpad.frame = CGRect(x: left + 16, y: bottom - 16 - padSize, width: padSize, height: padSize)
                p1ButtonA.frame = CGRect(x: right - 16 - 2 * buttonSize, y: buttonAY, width: buttonSize, height: buttonSize)
                p1ButtonB.frame = CGRect(x: right - 16 - buttonSize, y: buttonBY, width: buttonSize, height: buttonSize)
            } else if numOnscreenGamepads == 2 {
                let dpadY = bottom - 16 - padSize - 32 - 2 * buttonSize
                p1Dpad.frame = CGRect(x: left + 16, y: dpadY, width: padSize, height: padSize)
                p2Dpad.frame = CGRect(x: right - 16 - padSize, y: dpadY, width: padSize, height: padSize)
                p1ButtonA.frame = CGRect(x: left + 16 + buttonSize, y: buttonAY, width: buttonSize, height: buttonSize)
                p1ButtonB.frame = CGRect(x: left + 16, y: buttonBY, width: buttonSize, height: buttonSize)
                p2ButtonA.frame = CGRect(x: right - 16 - 2 * buttonSize, y: buttonAY, width: buttonSize, height: buttonSize)
                p2ButtonB.frame = CGRect(x: right - 16 - buttonSize, y: buttonBY, width: buttonSize, height: buttonSize)
            }
        }
        
        let screenWidth = containerRect.size.width
        let screenHeight = containerRect.size.height
        var maxWidthFactor: CGFloat
        var maxHeightFactor: CGFloat
        
        if isSafeScaleEnabled {
            // pixel exact scaling
            let scale: CGFloat = view.window?.screen.scale ?? 1.0
            maxWidthFactor = floor(screenWidth * scale / CGFloat(SCREEN_WIDTH)) / scale
            maxHeightFactor = floor(screenHeight * scale / CGFloat(SCREEN_HEIGHT)) / scale
        } else {
            // normal scaling
            maxWidthFactor = screenWidth / CGFloat(SCREEN_WIDTH)
            maxHeightFactor = screenHeight / CGFloat(SCREEN_HEIGHT)
        }
        
        let nxWidth = (maxWidthFactor < maxHeightFactor) ? maxWidthFactor * CGFloat(SCREEN_WIDTH) : maxHeightFactor * CGFloat(SCREEN_WIDTH)
        let nxHeight = nxWidth * 4.0 / 5.0
        
        nxView.frame = CGRect(
            x: floor(containerRect.origin.x + (containerRect.size.width - nxWidth) * 0.5),
            y: floor(containerRect.origin.y + (containerRect.size.height - nxHeight) * 0.5),
            width: nxWidth,
            height: nxHeight
        )
    }
    
    func compileAndStartProgram(sourceCode: String) -> LowResNXError? {
        guard let coreWrapper = coreWrapper else {
            assertionFailure()
            return nil
        }
        
        let error = coreWrapper.compileProgram(sourceCode: sourceCode)
        if error == nil {
            core_willRunProgram(&coreWrapper.core, Int(CFAbsoluteTimeGetCurrent() - AppController.shared.bootTime))
            core_setDebug(&coreWrapper.core, isDebugEnabled)
        }
        return error
    }
    
    func captureProgramIcon() {
        guard let document = document else {
            assertionFailure()
            return
        }
        if let cgImage = nxView.layer.contents as! CGImage? {
            let uiImage = UIImage(cgImage: cgImage)
            ProjectManager.shared.saveProjectIcon(programUrl: document.fileURL, image: uiImage)
        }
    }
    
    func shareScreenshot() {
        if let cgImage = nxView.layer.contents as! CGImage? {
            let uiImage = UIImage(cgImage: cgImage)
            
            // rescale
            let size = CGSize(width: CGFloat(SCREEN_WIDTH) * screenshotScaleFactor, height: CGFloat(SCREEN_HEIGHT) * screenshotScaleFactor)
            UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
            let context = UIGraphicsGetCurrentContext()
            context?.interpolationQuality = .none
            uiImage.draw(in: CGRect(origin: CGPoint(), size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            // share
            let activityVC = UIActivityViewController(activityItems: [scaledImage], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = menuButton
            activityVC.popoverPresentationController?.sourceRect = menuButton.bounds
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func recordVideo() {
        guard RPScreenRecorder.shared().isAvailable else {
            showAlert(withTitle: "Video Recording Currently Not Available", message: nil, block: nil)
            return
        }
        RPScreenRecorder.shared().startRecording(withMicrophoneEnabled: false) { (error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(withTitle: "Cannot Record Video", message: error.localizedDescription, block: nil)
                }
            }
        }
    }
    
    func stopVideoRecording() {
        RPScreenRecorder.shared().stopRecording { (vc, error) in
            if let vc = vc {
                vc.previewControllerDelegate = self
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            } else {
                self.showAlert(withTitle: "Could Not Record Video", message: error?.localizedDescription, block: {
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
    
    func saveProgramFromWeb() {
        guard
            let webSource = webSource,
            let sourceCode = coreWrapper?.sourceCode,
            let programData = sourceCode.data(using: .utf8)
            else {
                assertionFailure()
                return
        }
        BlockerView.show()
        ProjectManager.shared.addProject(originalName: webSource.name, programData: programData, imageData: imageData) { (error) in
            BlockerView.dismiss()
            self.exit()
        }
    }
    
    func countPlay(topicId: String) {
        var urlRequest = URLRequest(url: URL(string: "\(ShareViewController.baseUrl)ajax/count_play.php")!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "topic_id=\(topicId)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            print("count play \(topicId):", error ?? "ok")
        }
        task.resume()
    }
    
    @objc func update(displaylink: CADisplayLink) {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        // pause when any alerts are visible
        if presentedViewController != nil {
            return
        }
        
        updateGameControllers()
        updateOnscreenGamepads()
        
        core_update(&coreWrapper.core, &coreWrapper.input)
        
        if core_shouldRender(&coreWrapper.core) {
            nxView.render()
        }
    }
    
    func configureGameControllers() {
        let numPlayers = Int(controlsInfo.numGamepadsEnabled)
        var numGameControllers = 0
        
        if SUPPORTS_GAME_CONTROLLERS {
            let gameControllers = GCController.controllers()
            for gameController in gameControllers {
                gameController.playerIndex = GCControllerPlayerIndex(rawValue: numGameControllers)!
                gameController.controllerPausedHandler = { [weak self] (controller) in
                    if let coreWrapper = self?.coreWrapper {
                        coreWrapper.input.pause = true
                    }
                }
                numGameControllers += 1
            }
        }
        
        numOnscreenGamepads = max(0, numPlayers - numGameControllers)
        
        p1Dpad.isHidden = numOnscreenGamepads < 1
        p1ButtonA.isHidden = numOnscreenGamepads < 1
        p1ButtonB.isHidden = numOnscreenGamepads < 1
        p2Dpad.isHidden = numOnscreenGamepads < 2
        p2ButtonA.isHidden = numOnscreenGamepads < 2
        p2ButtonB.isHidden = numOnscreenGamepads < 2
        pauseButton.isHidden = numOnscreenGamepads == 0
        
        view.setNeedsLayout()
    }
    
    func updateGameControllers() {
        guard let coreWrapper = coreWrapper, SUPPORTS_GAME_CONTROLLERS else {
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
                core_setInputGamepad(&coreWrapper.input, Int32(player), up, down, left, right, buttonA, buttonB)
            }
        }
    }
    
    func updateOnscreenGamepads() {
        guard let coreWrapper = coreWrapper else {
            return
        }
        
        let numGameControllers = SUPPORTS_GAME_CONTROLLERS ? GCController.controllers().count : 0
        let numPlayers = Int(controlsInfo.numGamepadsEnabled)
        let numOnscreenGamepads = numPlayers - numGameControllers
        
        if numOnscreenGamepads >= 1 {
            core_setInputGamepad(&coreWrapper.input, Int32(numGameControllers),
                                 p1Dpad.isDirUp, p1Dpad.isDirDown, p1Dpad.isDirLeft, p1Dpad.isDirRight,
                                 p1ButtonA.isHighlighted,
                                 p1ButtonB.isHighlighted)
        }
        
        if numOnscreenGamepads >= 2 {
            core_setInputGamepad(&coreWrapper.input, Int32(numGameControllers + 1),
                                 p2Dpad.isDirUp, p2Dpad.isDirDown, p2Dpad.isDirLeft, p2Dpad.isDirRight,
                                 p2ButtonA.isHighlighted,
                                 p2ButtonB.isHighlighted)
        }
    }
    
    func exit() {
        if RPScreenRecorder.shared().isRecording {
            stopVideoRecording()
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
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
        return controlsInfo.keyboardMode == KeyboardModeOn
    }
    
    private func showError(_ error: Error) {
        errorToShow = error
        checkShowError()
    }
    
    private func checkShowError() {
        guard let error = errorToShow else { return }
        errorToShow = nil
        
        if let nxError = error as? LowResNXError {
            // NX Error
            let alert = UIAlertController(title: nxError.message, message: nxError.line, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                self.exit()
            }))
            if delegate != nil {
                alert.addAction(UIAlertAction(title: "Go to Error", style: .default, handler: { (action) in
                    self.delegate?.didEndWithError(nxError)
                    self.exit()
                }))
            }
            present(alert, animated: true, completion: nil)
            
        } else {
            // System Error
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.exit()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let frame = frameValue.cgRectValue
            keyboardTop = frame.origin.y
            view.setNeedsLayout()
            UIView.animate(withDuration: 0.3, animations: { 
                self.view.layoutIfNeeded()
            })
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        keyboardTop = nil
        view.setNeedsLayout()
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
        let timeSinceStart = Date().timeIntervalSince(startDate)
        
        if timeSinceStart >= 60 && controlsInfo.isTouchEnabled {
            let alert = UIAlertController(title: "Do you really want to exit this program?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Exit", style: .default, handler: { [unowned self] (action) in
                self.exit()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            exit()
        }
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if isSafeScaleEnabled {
            alert.addAction(UIAlertAction(title: "Zoom In", style: .default, handler: { [unowned self] (action) in
                self.isSafeScaleEnabled = false
                AppController.shared.isSafeScaleEnabled = false
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Zoom Out (Pixel Perfect)", style: .default, handler: { [unowned self] (action) in
                self.isSafeScaleEnabled = true
                AppController.shared.isSafeScaleEnabled = true
            }))
        }
        
        if document != nil {
            alert.addAction(UIAlertAction(title: "Capture Program Icon", style: .default, handler: { [unowned self] (action) in
                self.captureProgramIcon()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Share Screenshot", style: .default, handler: { [unowned self] (action) in
            self.shareScreenshot()
        }))
        
        
        if !RPScreenRecorder.shared().isRecording {
            alert.addAction(UIAlertAction(title: "Record Video", style: .default, handler: { [unowned self] (action) in
                self.recordVideo()
            }))
        }
        
        if webSource != nil {
            alert.addAction(UIAlertAction(title: "Save to My Programs", style: .default, handler: { [unowned self] (action) in
                self.saveProgramFromWeb()
            }))
        }
        
        if isDebugEnabled {
            alert.addAction(UIAlertAction(title: "Disable Debug Mode", style: .default, handler: { [unowned self] (action) in
                self.isDebugEnabled = false
                self.delegate?.didChangeDebugMode(enabled: false)
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Enable Debug Mode", style: .default, handler: { [unowned self] (action) in
                self.isDebugEnabled = true
                self.delegate?.didChangeDebugMode(enabled: true)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let pop = alert.popoverPresentationController {
            let button = sender as! UIView
            pop.sourceView = button
            pop.sourceRect = button.bounds
        }
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Core Wrapper Delegate
    
    func coreInterpreterDidFail(coreError: CoreError) {
        guard let coreWrapper = coreWrapper else {
            assertionFailure()
            return
        }
        let interpreterError = LowResNXError(error: coreError, sourceCode: coreWrapper.sourceCode!)
        showError(interpreterError)
    }
    
    func coreDiskDriveWillAccess(diskDataManager: UnsafeMutablePointer<DataManager>?) -> Bool {
        if let delegate = toolDelegate {
            // tool editing current program
            let diskSourceCode = delegate.nxSourceCodeForVirtualDisk()
            let cDiskSourceCode = diskSourceCode.cString(using: .utf8)
            data_import(diskDataManager, cDiskSourceCode, true)
        } else {
            // tool editing shared disk file
            if let diskDocument = diskDocument {
                let cDiskSourceCode = (diskDocument.sourceCode ?? "").cString(using: .utf8)
                data_import(diskDataManager, cDiskSourceCode, true)
            } else {
                ProjectManager.shared.getDiskDocument(completion: { (document, error) in
                    if let document = document {
                        self.diskDocument = document
                        let cDiskSourceCode = (document.sourceCode ?? "").cString(using: .utf8)
                        data_import(diskDataManager, cDiskSourceCode, true)
                        self.showAlert(withTitle: "Using “Disk.nx” as Virtual Disk", message: nil, block: {
                            core_diskLoaded(&self.coreWrapper!.core)
                        })
                    } else {
                        self.showAlert(withTitle: "Could not Access Virtual Disk", message: error?.localizedDescription, block: {
                            self.exit()
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
        if let output = output, let diskSourceCode = String(cString: output, encoding: .utf8) {
            if let delegate = toolDelegate {
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
            self.controlsInfo = controlsInfo
            if controlsInfo.keyboardMode == KeyboardModeOn {
                self.recognizer?.isEnabled = true
                self.becomeFirstResponder()
            } else {
                self.recognizer?.isEnabled = false
                self.resignFirstResponder()
            }
            if controlsInfo.isAudioEnabled {
                self.audioPlayer.start()
            }
            self.configureGameControllers()
        }
    }
    
    func persistentRamWillAccess(destination: UnsafeMutablePointer<UInt8>?, size: Int32) {
        guard let document = document else { return }
        guard let destination = destination else {
            assertionFailure()
            return
        }
        
        if let data = ProjectManager.shared.loadPersistentRam(programUrl: document.fileURL) {
            data.copyBytes(to: destination, count: min(data.count, Int(size)))
        }
    }
    
    func persistentRamDidChange(_ data: Data) {
        guard let document = document else { return }
        ProjectManager.shared.savePersistentRam(programUrl: document.fileURL, data: data)
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
            coreWrapper.input.key = CoreInputKeyReturn
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
        
        coreWrapper.input.key = CoreInputKeyBackspace
    }
    
    // this is from UITextInput, needed because of crash on iPhone 6 keyboard (left/right arrows)
    var selectedTextRange: UITextRange? {
        return nil
    }
    
    var keyboardType: UIKeyboardType = .asciiCapable
    
    // MARK: - RPPreviewViewControllerDelegate
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

