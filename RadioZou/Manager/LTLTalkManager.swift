//
//  LTLTalkManager.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/29.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyJSON
import RealmSwift

class LTLTalkManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = LTLTalkManager()

    let speechSynthesizer :AVSpeechSynthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    func talkWith(utterance: AVSpeechUtterance) {
        speechSynthesizer.speak(utterance)
    }
    
    func pauseSpeak() {
        // 一時停止
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func resumeSpeak() {
        speechSynthesizer.continueSpeaking()
    }
    
    func isPaused() -> Bool {
        return speechSynthesizer.isPaused
    }
    
    func isSpeaking() -> Bool {
        return speechSynthesizer.isSpeaking
    }
    
    func startTalk() {
        // トークを始める
        if (TimelineManager.shared.currentToot == nil) {
            return;
        }
        
        if (self.speechSynthesizer.isSpeaking) {
            // −−− 発声中なら即座に止める
            self.speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        var tootText = ""
        let currentToot = TimelineManager.shared.currentToot!;
        if(currentToot["spoiler_text"]?.stringValue != "") {
            tootText = (currentToot["spoiler_text"]?.stringValue)!
        } else {
            tootText = (currentToot["content"]?.stringValue)!
        }

        tootText = TootStringManager.stringByStripping(URL: TootStringManager.stringByStripping(HTML: tootText))
        
        let utterance: AVSpeechUtterance = AVSpeechUtterance(string: tootText)
        let voiceJapan: AVSpeechSynthesisVoice = AVSpeechSynthesisVoice(language: "ja-JP")!
        utterance.voice = voiceJapan
        
        self.talkWith(utterance: utterance)
    }
    
    func talkNextToot() {
        let dicCurrentToot: Dictionary<String, JSON>? = TimelineManager.shared.currentToot
    
        if (TimelineManager.shared.nextToot()! != dicCurrentToot!) {
            // --- 次に喋るべきTootを見つける
            self.startTalk()
            
            let realm = try! Realm()
            try! realm.write {
                TimelineManager.shared.currentInstance?.lastTalkTootId = (TimelineManager.shared.currentToot?["id"]?.stringValue)!
            }

            let name = NSNotification.Name(rawValue: "renewToot")
            NotificationCenter.default.post(name: name,
                                            object: nil)
        } else {
            NSLog("トゥート終了 ---------- ");
        }
    }
    
    // MARK: - DELEGATE
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.talkNextToot()
    }
    
    
}
