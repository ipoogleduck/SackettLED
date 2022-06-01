//
//  Sounds.swift
//  SacketLED
//
//  Created by Oliver Elliott on 4/28/22.
//

import Foundation
import AVFoundation

enum Sound: String {
    case move = "move"
    case rotate = "rotate"
    case clear = "clear"
    case tetris = "tetris"
    case fall = "fall"
    case levelUp = "levelUp"
    case gameOver = "gameOver"
    
    case soundtrack1 = "soundtrack1"
    case soundtrack2 = "soundtrack2"
    case soundtrack3 = "soundtrack3"
    case soundtrack4 = "soundtrack4"
    
    case tetrisEpic = "tetrisEpic"
    
    case buttonPress = "buttonRelease"
    
    
    func fastSoundtrack() -> String? {
        if self == .soundtrack2 || self == .soundtrack3 || self == .soundtrack4 {
            return "\(self.rawValue)Fast"
        }
        return nil
    }
    
    static func randomSong() -> Sound {
        let songs: [Sound] = [.soundtrack1, .soundtrack2, .soundtrack3, .soundtrack4]
        return songs.randomElement()!
    }
    
}

//For sound effects
class SoundEffect: NSObject, AVAudioPlayerDelegate {

    static let sharedInstance = SoundEffect()

    private override init() { }

    var players: [URL: AVAudioPlayer] = [:]
    var duplicatePlayers: [AVAudioPlayer] = []

    func playSound(_ soundFileName: Sound) {

        guard let bundle = Bundle.main.path(forResource: soundFileName.rawValue, ofType: "mp3") else { return }
        let soundFileNameURL = URL(fileURLWithPath: bundle)

        if let player = players[soundFileNameURL] { //player for sound has been found

            if !player.isPlaying { //player is not in use, so use that one
                player.prepareToPlay()
                player.play()
            } else { // player is in use, create a new, duplicate, player and use that instead

                do {
                    let duplicatePlayer = try AVAudioPlayer(contentsOf: soundFileNameURL)

                    duplicatePlayer.delegate = self
                    //assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing

                    duplicatePlayers.append(duplicatePlayer)
                    //add duplicate to array so it doesn't get removed from memory before finishing

                    duplicatePlayer.prepareToPlay()
                    duplicatePlayer.play()
                } catch let error {
                    print(error.localizedDescription)
                }

            }
        } else { //player has not been found, create a new player with the URL if possible
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileNameURL)
                players[soundFileNameURL] = player
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }


    func playSounds(soundFileNames: [Sound]) {
        for soundFileName in soundFileNames {
            playSound(soundFileName)
        }
    }

//    func playSounds(soundFileNames: [String], withDelay: Double) { //withDelay is in seconds
//        for (index, soundFileName) in soundFileNames.enumerated() {
//            let delay = withDelay * Double(index)
//            let _ = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(playSoundNotification(_:)), userInfo: ["fileName": soundFileName], repeats: false)
//        }
//    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let index = duplicatePlayers.index(of: player) {
            duplicatePlayers.remove(at: index)
        }
    }

}
