//
//  StartTetrisVC.swift
//  SacketLED
//
//  Created by Oliver Elliott on 4/28/22.
//

import UIKit
import AVFoundation
import GameKit
import ALRT
import Firebase

var gcEnabled: Bool? // Check if the user has Game Center enabled
var gcDefaultLeaderBoard: String? // Check the default leaderboardID
var gcID: String?

struct AlertDocuments {
    var documents: [QueryDocumentSnapshot]
    var forPresentingTetrisVC: Bool
}

class StartTestrisVC: UIViewController, FJButton3DDelegate {
    
    @IBOutlet weak var tetrisBackground: UIImageView!
    @IBOutlet weak var logoHoldingView: UIView!
    @IBOutlet weak var tetrisImage: UIImageView!
    @IBOutlet weak var blackTetrisImage: UIImageView!
    @IBOutlet weak var blankTetrisImage: UIImageView!
    @IBOutlet weak var videoHoldingView: UIView!
    @IBOutlet weak var topVideoConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftVideoConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoHeight: NSLayoutConstraint!
    @IBOutlet weak var startButton: FJButton3D!
    @IBOutlet weak var practiceButton: FJButton3D!
    @IBOutlet weak var settingsButton: FJButton3D!
    @IBOutlet var levelView: UIView!
    @IBOutlet weak var levelSelectCV: UICollectionView!
    @IBOutlet weak var overLevelSelectTitle: NSLayoutConstraint!
    @IBOutlet weak var underLevelSelectTitle: NSLayoutConstraint!
    
    var player: AVAudioPlayer?
    var videoPlayer: AVPlayer?
    
    var firstOpen = true
    var lastOpen: Date?
    
    var practiceMode = false //Selected by user
    
    
    var alertToShowOnTetrisVC: AlertDocuments?
    var dontOpenTetrisVC = false
    var viewedAlertIDs: [String] = []
    
    var notificationsRef: CollectionReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if view.frame.height <= 670 {
            overLevelSelectTitle.constant = 40
            underLevelSelectTitle.constant = 40
        }
        
        startButton.delegate = self
        practiceButton.delegate = self
        settingsButton.delegate = self
        
        levelSelectCV.delegate = self
        levelSelectCV.dataSource = self
        
        tetrisImage.alpha = 0
        blankTetrisImage.alpha = 0
        blackTetrisImage.isHidden = true
        
        startButton.alpha = 0
        practiceButton.alpha = 0
        settingsButton.alpha = 0
        tetrisBackground.alpha = 0
        
        if let strDate = UserDefaults.getString(key: .lastOpen) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            lastOpen = dateFormatter.date(from: strDate)
        }
        
        //Save date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        UserDefaults.save(dateFormatter.string(from: Date()), key: .lastOpen)
        
        authenticateGamecenterPlayer()
        
        viewedAlertIDs = UserDefaults.getArray(key: .savedAlertIDs) as? [String] ?? []
        addSnapshotListner()
        
        getScores()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstOpen {
            queueSound(.tetrisEpic)
            if let lastOpen = lastOpen, Calendar.current.isDate(lastOpen, inSameDayAs: Date()) {
                UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
                    self.tetrisBackground.alpha = 0.3
                })
                player?.currentTime = 11.2
                player?.play()
                startFinalAnimation()
            } else {
                player?.play()
                startFullAnimation()
            }
            firstOpen = false
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
    func queueSound(_ sound: Sound) {
        guard let path = Bundle.main.path(forResource: sound.rawValue, ofType:"mp3") else {
            return }
        let url = URL(fileURLWithPath: path)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startFullAnimation() {
        logoHoldingView.transform = CGAffineTransform(translationX: 350, y: 0).scaledBy(x: 9, y: 9).rotated(by: -.pi/2)
        blackTetrisImage.isHidden = false
        placeVideoView()
        playVideo()
        UIView.animate(withDuration: 6, delay: 0, options: .curveEaseInOut, animations: {
            self.logoHoldingView.transform = CGAffineTransform(translationX: 230, y: 0).scaledBy(x: 6, y: 6).rotated(by: -.pi/2)
        })
        UIView.animate(withDuration: 3, delay: 8, options: .curveEaseInOut, animations: {
            self.blankTetrisImage.alpha = 1
        }, completion: nil)
        UIView.animate(withDuration: 5, delay: 6, options: .curveEaseInOut, animations: {
            self.tetrisBackground.alpha = 0.3
        })
        UIView.animate(withDuration: 6, delay: 5, options: .curveEaseInOut, animations: {
            self.logoHoldingView.transform = .identity
        }, completion: {_ in
            self.startFinalAnimation()
        })
    }
    
    func startFinalAnimation() {
        removeVideo()
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
            self.tetrisImage.alpha = 1
        })
        UIView.animate(withDuration: 0.5, delay: 0.7, options: .curveEaseInOut, animations: {
            self.startButton.alpha = 1
        }, completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.7+0.3, options: .curveEaseInOut, animations: {
            self.practiceButton.alpha = 1
        }, completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.7+0.6, options: .curveEaseInOut, animations: {
            self.settingsButton.alpha = 1
        }, completion: nil)
    }
    
    func placeVideoView() {
        let heightRatio = 0.375
        let leftOut = 0.1631
        let topOut = 0.125
        videoHeight.constant = tetrisImage.frame.height*heightRatio
        leftVideoConstraint.constant = tetrisImage.frame.width*leftOut
        topVideoConstraint.constant = tetrisImage.frame.height*topOut
    }
    
    func playVideo() {
        let videoString: String? = Bundle.main.path(forResource: "tetrisIntroGame", ofType: "mov")
        guard let unwrappedVideoPath = videoString else {fatalError("No video found")}
        
        // convert the path string to a url
        let videoUrl = URL(fileURLWithPath: unwrappedVideoPath)
        
        videoHoldingView.layer.sublayers = nil
        
        // initialize the video player with the url
        self.videoPlayer = AVPlayer(url: videoUrl)
        
        // create a video layer for the player
        let layer = AVPlayerLayer(player: videoPlayer)
        
        // make the video fill the layer as much as possible while keeping its aspect size
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        // make the layer the same size as the container view
        
        let heightRatio = 0.375
        let leftOut = 0.1631
        let topOut = 0.125
        
        let height = tetrisImage.frame.height*heightRatio
        let width = height*2
        
        layer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        videoHoldingView.layer.addSublayer(layer)
        
        videoPlayer?.seek(to: CMTime.zero)
        videoPlayer?.play()
    }
    
    func removeVideo() {
        videoHoldingView.layer.sublayers?.removeAll()
    }
    
    func showTetrisVC(with level: Level) {
        guard let tetrisVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "TetrisVC") as? TetrisVC else {
            fatalError("Unable to Instantiate View Controller")
        }
        tetrisVC.staringLevel = level
        tetrisVC.modalPresentationStyle = .fullScreen
        if !dontOpenTetrisVC {
            present(tetrisVC, animated: true)
        }
        if let alertToShowOnTetrisVC = alertToShowOnTetrisVC {
            loadDocuments(with: alertToShowOnTetrisVC)
        }
    }
    
    func showTetrisSampleVC(with level: Level) {
        guard let tetrisSampleVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "TetrisSampleVC") as? TetrisSampleVC else {
            fatalError("Unable to Instantiate View Controller")
        }
        tetrisSampleVC.staringLevel = level
        tetrisSampleVC.modalPresentationStyle = .fullScreen
        present(tetrisSampleVC, animated: true)
    }
    
    func didTap(onButton3D button3d: FJButton3D) {
        if button3d == startButton {
            practiceMode = false
            updateScreen(toMain: false)
            //Request notification permissions if not already granted
            let current = UNUserNotificationCenter.current()
            current.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print("Permission granted: \(granted)")
            }
        } else if button3d == practiceButton {
            practiceMode = true
            updateScreen(toMain: false)
        } else if button3d == settingsButton {
//            if let gcEnabled = gcEnabled, !gcEnabled {
                if let gcDefaultLeaderBoard = gcDefaultLeaderBoard {
                    let GameCenterVC = GKGameCenterViewController(leaderboardID: gcDefaultLeaderBoard, playerScope: .global, timeScope: .allTime)
                    GameCenterVC.gameCenterDelegate = self
                    present(GameCenterVC, animated: true, completion: nil)
//                }
            } else {
                ALRT.create(.alert, title: "Enable GameCenter", message: "Please enable GameCenter in your settings app in order to view and contribute to leaderboard").addOK().show()
            }
            //performSegue(withIdentifier: "toTextSendVC", sender: self)
        } else {
            //For level selection
            if button3d.tag <= 9 {
                player?.stop()
                let level = Level(rawValue: button3d.tag)!
                if practiceMode {
                    showTetrisSampleVC(with: level)
                } else {
                    showTetrisVC(with: level)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateScreen(toMain: true)
                }
            } else {
                updateScreen(toMain: true)
            }
        }
    }
    
    func animateMain(show: Bool) {
        let alpha: CGFloat = show ? 1 : 0
        logoHoldingView.alpha = alpha
        startButton.alpha = alpha
        practiceButton.alpha = alpha
        settingsButton.alpha = alpha
    }
    
    func updateScreen(toMain: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            if toMain {
                self.levelView.alpha = 0
            } else {
                self.animateMain(show: false)
            }
        }, completion: {_ in
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                if toMain {
                    self.animateMain(show: true)
                } else {
                    self.levelView.alpha = 1
                }
            })
        })
    }
    
}


extension StartTestrisVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 11
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = indexPath.item <= 9 ? "LevelSelectCell" : "LevelSelectCellLarge"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! LevelSelectCell
        
        if indexPath.item <= 9 {
            cell.buttonView.titleLabel.text = String(indexPath.item)
        } else {
            cell.buttonView.titleLabel.text = "Cancel"
            cell.buttonWidth.constant = cell.frame.width-10
        }
        
        
        cell.buttonView.tag = indexPath.item
        cell.buttonView.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthOfCells = (collectionView.frame.width-40)/3
        if indexPath.item <= 9 {
            return CGSize(width: widthOfCells, height: 100)
        }
        return CGSize(width: (widthOfCells*2)+20, height: 100)
    }
    
}

class LevelSelectCell: UICollectionViewCell {
    
    @IBOutlet weak var buttonView: FJButton3D!
    @IBOutlet weak var buttonWidth: NSLayoutConstraint!
    
}

extension StartTestrisVC: GKGameCenterControllerDelegate {
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
    
    
    func authenticateGamecenterPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if ((ViewController) != nil) {
                // Show game center login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            }
            else if (localPlayer.isAuthenticated) {
                
                // Player is already authenticated and logged in
                gcEnabled = true
                
                gcID = localPlayer.teamPlayerID
                
                UserDefaults.save(gcID, key: .gameCenterID)
                
                if let FCMToken = FCMToken {
                    userRef()?.setData(["FCMToken": FCMToken], merge: true)
                }

                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil {
                        print(error!)
                    }
                    else {
                        gcDefaultLeaderBoard = leaderboardIdentifer!
                    }
                 })
            }
            else {
                // Game center is not enabled on the user's device
                gcEnabled = false
                print("Local player could not be authenticated!")
                print(error!)
            }
        }
    }
    
}

extension StartTestrisVC {
    
    func getScores() {
        userRef()?.getDocument(completion: { querySnapshot, error in
            guard let data = querySnapshot?.data() else { return }
            if let topScore = data["topScore"] as? Int {
                let localTopScore = UserDefaults.getInt(key: .topScore)
                if topScore > localTopScore {
                    UserDefaults.save(topScore, key: .topScore)
                }
            }
        })
    }
    
    func addSnapshotListner() {
        notificationsRef = Firestore.firestore().collection("Notifications")
        notificationsRef.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            let fromCache = querySnapshot?.metadata.isFromCache ?? false
            if fromCache && Reachability.isConnectedToNetwork() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.loadDocuments(with: AlertDocuments(documents: documents, forPresentingTetrisVC: false))
                }
            } else {
                self.loadDocuments(with: AlertDocuments(documents: documents, forPresentingTetrisVC: false))
            }
        }
    }
    
    func loadDocuments(with alerts: AlertDocuments) {
        for document in alerts.documents {
            let data = document.data()
            let showToVersion = data["showToVersion"] as? String
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            
            if let appVersion = appVersion, let showToVersion = showToVersion, appVersion.sameOrLowerVersionComparedTo(showToVersion) {
                
                let showToAll = data["showToAll"] as? Bool ?? false
                let fcmTokens = data["showToFCM"] as? [String] ?? []
                
                if let onlyShowOnce = data["onlyShowOnce"] as? Bool, !onlyShowOnce {
                    var ids = UserDefaults.getArray(key: .savedAlertIDs) as? [String] ?? []
                    if ids.contains(document.documentID) {
                        viewedAlertIDs.removeAll(where: { $0 == document.documentID })
                        ids.removeAll(where: { $0 == document.documentID })
                        UserDefaults.save(ids, key: .savedAlertIDs)
                    }
                }
                
                if (showToAll || fcmTokens.contains(FCMToken ?? "NOFCM")) && !self.viewedAlertIDs.contains(document.documentID) {
                    
                    let showOnlyOnTetrisVC = data["showOnlyOnTetrisVC"] as? Bool ?? false
                    let crashOnDismiss = data["crashOnDismiss"] as? Bool ?? false
                    
                    if showOnlyOnTetrisVC && !alerts.forPresentingTetrisVC {
                        self.alertToShowOnTetrisVC = AlertDocuments(documents: [document], forPresentingTetrisVC: true)
                        self.dontOpenTetrisVC = crashOnDismiss
                        return
                    }
                    
                    let title = data["title"] as? String
                    let description = data["description"] as? String
                    
                    let alert = ALRT.create(.alert, title: title, message: description)
                    
                    if let dismissButton = data["dismissButton"] as? Bool, dismissButton {
                        alert.addAction("Dismiss", style: .default, preferred: false, handler: { action, textFields in
                            if crashOnDismiss && !alerts.forPresentingTetrisVC {
                                fatalError()
                            }
                        })
                    }
                    if let otherButton = data["otherButton"] as? [String: Any] {
                        let title = otherButton["title"] as? String
                        let link = otherButton["link"] as? String
                        alert.addAction(title, style: .default, preferred: false, handler: { action, textFields in
                            if let link = link, let url = URL(string: link) {
                                UIApplication.shared.open(url)
                            }
                            if crashOnDismiss && !alerts.forPresentingTetrisVC {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    fatalError()
                                }
                            }
                        })
                    }
                    alert.show()
                    
                    if !(showOnlyOnTetrisVC && crashOnDismiss) {
                        self.viewedAlertIDs.append(document.documentID)
                        
                        if let onlyShowOnce = data["onlyShowOnce"] as? Bool, onlyShowOnce {
                            var ids = UserDefaults.getArray(key: .savedAlertIDs) as? [String] ?? []
                            ids.append(document.documentID)
                            UserDefaults.save(ids, key: .savedAlertIDs)
                        }
                    }
                    
                }
                
            }
        }
    }
    
}

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        return self.compare(otherVersion, options: .numeric)
    }
    
    func sameOrLowerVersionComparedTo(_ otherVersion: String) -> Bool {
        return self.versionCompare(otherVersion) == .orderedAscending || self.versionCompare(otherVersion) == .orderedSame
    }
}

func userRef() -> DocumentReference? {
    if let gcID = gcID {
        return Firestore.firestore().collection("Users").document(gcID)
    }
    return nil
}
