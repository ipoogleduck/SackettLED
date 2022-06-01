//
//  TetrisVC.swift
//  SacketLED
//
//  Created by Oliver Elliott on 10/27/21.
//

import UIKit
import CoreBluetooth
import GameKit
import Firebase
import StoreKit

enum ConnectionTest {
    case testing
    case waiting
    case validating
    case notTesting
}

class TetrisVC: UIViewController, FJButton3DDelegate, GameDelegate {
    
    @IBOutlet var moveCloserView: UIVisualEffectView!
    @IBOutlet var moveCloserLabel: UILabel!
    @IBOutlet weak var leftArrow: FJButton3D!
    @IBOutlet weak var rightArrow: FJButton3D!
    @IBOutlet weak var rotateLeft: FJButton3D!
    @IBOutlet weak var rotateRight: FJButton3D!
    @IBOutlet weak var downArrow: FJButton3D!
    @IBOutlet weak var gameOverView: UIVisualEffectView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var bestScoreLabel: UILabel!
    @IBOutlet weak var statsView: FJButton3D!
    @IBOutlet weak var retryView: FJButton3D!
    @IBOutlet weak var inLineView: UIView!
    @IBOutlet weak var behindLabel: UILabel!
    @IBOutlet weak var inLineTextView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomRetryView: NSLayoutConstraint!
    
    var centralManager: CBCentralManager!
    var nanoPeripheral: CBPeripheral?
    var FFE1Characteristic: CBCharacteristic!
    
    var keepDisplayAwakeTimer: Timer?

    var game: Gameboard?
    
    var lineListner: ListenerRegistration?
    
    var canScanForDisplay = false
    var isConnectedToDisplay = false
    var tryConnectDisplayCount = 0
    var placeInLine: Int?
    
    var connectionTester = ConnectionTest.notTesting
    
    var staringLevel: Level!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttons = [leftArrow, rightArrow, rotateLeft, rotateRight, downArrow, statsView, retryView]
        for button in buttons {
            applyShadow(to: button!)
            button?.delegate = self
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        addSelfToLine()
        addLineListner()
        
        activityIndicator.startAnimating()
        
        NotificationCenter.default.addObserver(self, selector: #selector(fullyDisconnect), name: .fullyDisconnectDisplay, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addSelfToLine), name: .addBackToLine, object: nil)
        
        keepDisplayAwakeTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(keepDisplayAwake), userInfo: nil, repeats: true)
        
        if view.frame.height <= 670 {
            bottomRetryView.constant = 50
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGame()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lineListner?.remove()
        fullyDisconnect()
        game?.delegate = nil
        canScanForDisplay = false
        game = nil
        keepDisplayAwakeTimer?.invalidate()
    }
    
    func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
    }
    
    func startGame() {
        game?.delegate = nil
        game = Gameboard(level: staringLevel)
        game?.delegate = self
        updateLevel(with: staringLevel)
        updateScore(with: "0")
        game?.startGame()
    }
    
    func didTap(onButton3D button3d: FJButton3D) {
        if button3d == rotateLeft {
            rotateLeftButton()
        } else if button3d == rotateRight {
            rotateRightButton()
        } else if button3d == statsView {
            if let gcDefaultLeaderBoard = gcDefaultLeaderBoard {
                let GameCenterVC = GKGameCenterViewController(leaderboardID: gcDefaultLeaderBoard, playerScope: .global, timeScope: .allTime)
                GameCenterVC.gameCenterDelegate = self
                present(GameCenterVC, animated: true, completion: nil)
            }
        } else if button3d == retryView {
            gameOverView.alpha = 0
            if !(game?.isRunning ?? false) {
                startGame()
            }
        }
    }
    
    func didStartTap(onButton3D button3d: FJButton3D) {
        if button3d == downArrow {
            game?.startShapeSoftDrop()
        } else if button3d == leftArrow {
            game?.startMoveTimer(for: true)
        } else if button3d == rightArrow {
            game?.startMoveTimer(for: false)
        }
    }
    
    func didEndTap(onButton3D button3d: FJButton3D) {
        if button3d == downArrow {
            game?.endShapeSoftDrop()
        } else if button3d == leftArrow || button3d == rightArrow {
            game?.endMoveTimer()
        }
    }
    
    func sendDataToDisplay(_ text: String, toLongDisplay: Bool) {
        let newMaxCharSend = toLongDisplay ? maxCharSend-2 : maxCharSend //-1 so that Ø char can be added to front
        let rawText = text == "" ? " " : text
        let text = "$\(rawText)^"
        let totalSends = Int((Double(text.count)/Double(maxCharSend)).rounded(.up))
        for i in 0 ..< totalSends {
            let startIndex = text.index(text.startIndex, offsetBy: (i*newMaxCharSend))
            var endOffset = newMaxCharSend-1
            if i == totalSends-1 {
                endOffset = (text.count % newMaxCharSend)-1
            }
            if endOffset == -1 {
                endOffset = newMaxCharSend-1
            }
            let endIndex = text.index(startIndex, offsetBy: endOffset)
            var stringToSend = toLongDisplay ? "&" : ""
            stringToSend.append(String(text[startIndex ... endIndex]))
            if toLongDisplay {
                stringToSend.append(contentsOf: "%")
            }
            print("String to send: \(stringToSend)")
            sendRawData(stringToSend)
        }
        print("Sent \"\(text)\" to LED display")
        
    }
    
    func sendRawData(_ text: String) {
        let value: [UInt8] = Array(text.utf8)
        let data = Data(value)
        nanoPeripheral?.writeValue(data, for: FFE1Characteristic, type: .withResponse)
    }
    
    func rotateLeftButton() {
        game?.rotateShapeLeft()
    }
    
    func rotateRightButton() {
        game?.rotateShapeRight()
    }
    
    func updatePixels(with pixels: [Pixel], clearable: Bool) {
        if !pixels.isEmpty {
            let string = "C\(pixels[0].color?.rawValue ?? 9)\(mapPixelsToCordinateString(pixels))\(clearable ? "zb" : "eB")"
            sendDataToDisplay(string, toLongDisplay: false)
        }
    }
    
    func matrixIsEmpty(_ matrix: [[BlockColor?]]) -> Bool {
        return matrix.allSatisfy({ $0.allSatisfy({ $0 == nil }) })
    }
    
    func displayRefresh(_ display: [[BlockColor?]]) {
        var string = "f000000D"
        
        if !matrixIsEmpty(display) {
            string.append("M")
            for column in display {
                var tempString = ""
                for i in 0 ..< column.count {
                    if let color = column[column.count-i-1] {
                        string.append(tempString + String(color.rawValue))
                        tempString = ""
                    } else {
                        tempString.append("9")
                    }
                }
                string.append("e")
            }
        }
        string.append("B")
        
        sendDataToDisplay(string, toLongDisplay: false)
    }
    
    func mapPixelsToCordinateString(_ pixels: [Pixel]) -> String {
        var string = ""
        for pixel in pixels {
            let y = pixel.position.y < 10 ? "0\(pixel.position.y)" : String(pixel.position.y)
            string.append(contentsOf: "\(pixel.position.x)\(y)")
        }
        return string
    }
    
    func updateNextShape(with shape: Shape) {
        var string = ""
        for column in shape.type.twoByFour() {
            for color in column {
                string.append(contentsOf: String(color?.rawValue ?? 9))
            }
        }
        sendDataToDisplay("N\(string)", toLongDisplay: true)
    }
    
    func updateLevel(with newLevel: Level) {
        sendDataToDisplay("L\(newLevel.rawValue)e", toLongDisplay: true)
    }
    
    func updateScore(with score: String) {
        //Send score to small display
        sendDataToDisplay("S\(score)e", toLongDisplay: true)
    }
    
    func stopGame() {
        sendDataToDisplay("f000000B", toLongDisplay: false)
        sendDataToDisplay("f000000", toLongDisplay: true)
        if game?.isRunning ?? false {
            game?.stopGame()
        }
        game = nil
    }
    
    func showGameOverView() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.gameOverView.alpha = 1
        }, completion: nil)
    }
    
    func gameEnd(score: Int, scoreString: String, level: Level, clears: Int, fullGame: Bool) {
        let topScore = UserDefaults.getString(key: .topScore)
        var PR = false
        if let topScore = topScore, let topScoreInt = Int(topScore), topScoreInt > score {
            bestScoreLabel.text = topScore
        } else {
            UserDefaults.save(scoreString, key: .topScore)
            bestScoreLabel.text = scoreString
            userRef()?.setData(["topScore": score], merge: true)
            PR = true
        }
        scoreLabel.text = scoreString
        showGameOverView()
        if let gcDefaultLeaderBoard = gcDefaultLeaderBoard {
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [gcDefaultLeaderBoard], completionHandler: {error in})
        }
        userRef()?.setData(["lastScore": score], merge: true)
        if fullGame {
            SKStoreReviewController.requestReview()
            if isConnectedToDisplay {
                sendRawData("*")
                if PR {
                    sendDataToDisplay("t2c0000x151515New Personal High Score: \(score)|sr", toLongDisplay: true)
                }
            }
        }
    }
    
    func lineDocument() -> DocumentReference {
        return Firestore.firestore().collection("Defaults").document("line")
    }
    
    func placeInLine(tokens: [String]) -> Int? {
        for i in 0 ..< tokens.count {
            if tokens[i] == FCMToken {
                return i
            }
        }
        return nil
    }
    
    func updateInLineView(show: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0.7, options: .curveEaseInOut, animations: {
            self.inLineView.alpha = show ? 1 : 0
        })
    }
    
    func addLineListner() {
        lineListner = lineDocument().addSnapshotListener {(document, error) in
            if let document = document, document.exists {
                print("Got document!")
                let data = document.data()
                
                let line = data?["line"] as? [String] ?? []
                
                if let placeInLine = self.placeInLine(tokens: line) {
                    print("Place in line: \(placeInLine)")
                    self.behindLabel.text = "Behind \(placeInLine) \(placeInLine == 1 ? "person" : "people")"
                    self.placeInLine = placeInLine
                    if placeInLine == 0 {
                        self.inLineTextView.isHidden = true
                    } else {
                        self.inLineTextView.isHidden = false
                        self.updateInLineView(show: true)
                        self.disconnectNano()
                        if self.game?.isRunning ?? false {
                            self.game?.stopGame()
                        }
                        self.runConnectionTest()
                    }
                    if placeInLine == 0 && self.canScanForDisplay && !self.isConnectedToDisplay {
                        self.tryConnectDisplay()
                    } else {
                        self.tryConnectDisplayCount += 1
                    }
                } else {
                    self.placeInLine = nil
                    if ((self.game?.isRunning ?? false) && !leavingApp) {
                        self.addSelfToLine() //Adds user back to line if they have disconnected from display and another user took their spot
                    }
                }
                
                
            } else if let error = error {
                print(error)
            }
        }
    }
    
    func runConnectionTest() {
        if self.connectionTester == .notTesting && self.canScanForDisplay {
            self.connectionTester = .testing
            self.scanForDisplay()
            print("Testing to see if kick is possible")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                if self.connectionTester == .testing { //Faliure to connect
                    self.connectionTester = .notTesting
                    self.centralManager.stopScan()
                    self.inLineTextView.isHidden = false
                    print("Unsuccessfull test")
                }
            }
        }
    }
    
    func tryConnectDisplay() {
        tryConnectDisplayCount += 1
        let count = tryConnectDisplayCount
        if placeInLine == 0 {
            connectionTester = .notTesting
            //Can connect to bluetooth here
            if self.canScanForDisplay {
                self.scanForDisplay()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if count == self.tryConnectDisplayCount {
                        self.updateInLineView(show: false)
                    }
                }
            }
        } else {
            addSelfToLine()
        }
    }
    
    @objc func addSelfToLine() {
        lineDocument().updateData([
            "line": FieldValue.arrayUnion([FCMToken!])
        ])
    }
    
    func removeSelfFromLine() {
        lineDocument().updateData([
            "line": FieldValue.arrayRemove([FCMToken!])
        ])
    }
    
    func kickFirstFromLine() {
        lineDocument().getDocument() {(document, error) in
            if let document = document, document.exists {
                print("Got document!")
                let data = document.data()
                
                var line = data?["line"] as? [String] ?? []
                
                if line.first != FCMToken && !line.isEmpty {
                    line.removeFirst()
                }
                
                self.lineDocument().updateData(["line": line])
                
                print("First in line kicked")
                
            } else if let error = error {
                print(error)
            }
        }
    }
    
    @objc func fullyDisconnect() {
        //Disconnect bluetooth
        disconnectNano()
        //Remove from line in firebase
        removeSelfFromLine()
    }
    
    @objc func keepDisplayAwake() {
        if !(game?.isRunning ?? false) && isConnectedToDisplay {
            print("Keeping display awake...")
            sendRawData("a") //To keep display awake
        }
    }
    
    @IBAction func exitButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    deinit {
        print("Deinit TetrisVC")
    }
    
}

extension TetrisVC: GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
