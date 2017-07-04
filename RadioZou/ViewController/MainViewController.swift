//
//  MainViewController.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/15.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON
import SVProgressHUD
import WSCoachMarksView

class MainViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, WSCoachMarksViewDelegate {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var ivTootAvater: UIImageView!
    @IBOutlet weak var lblTootName: UILabel!
    @IBOutlet weak var lblTootUserId: UILabel!
    @IBOutlet weak var lblTootTime: UILabel!
    @IBOutlet weak var tvTootMessage: UITextView!
    @IBOutlet weak var ivSpeaker: UIImageView!

    var timer : Timer!

//    var couach: WSCoachMarksView!
    var isRotateLoked = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let myNotification = NSNotification.Name("renewToot")
        
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(type(of:self).renewToot(notification:)),
                           name: myNotification,
                           object: nil)
        
        // --- スピーカーの背景をパターンにする（Sliceだとうまくいかない）
        self.ivSpeaker.backgroundColor = UIColor.init(patternImage: UIImage.init(named: "Speaker")!)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.pickerView.reloadComponent(0)

        // 選択されているuuidを選択する
        let userDefault: UserDefaults = UserDefaults.standard
        let uuid: String? = userDefault.string(forKey:"uuid")
        if ((uuid != nil) && (uuid != "")) {
            let realm = try! Realm()
            let instances = realm.objects(MastodonInstance.self)
            for (index, instance) in instances.enumerated() {
                if (instance["uuid"] as? String == uuid) {
                    self.pickerView.selectRow(index + 1, inComponent: 0, animated: true)
                    self.loadInstanceData(row: index + 1)
                    break;
                }
            }
        } else {
            // 液晶のコンテンツをhiddenにする
            self.show(toot: nil)
        }
        
        // --- コーチマーク
        let ud: UserDefaults = UserDefaults.standard
        if (!ud.bool(forKey: "first_couach_MainView")) {
            ud.set(true, forKey: "first_couach_MainView")
            ud.synchronize()
            // --- 初回のみコーチ
            let f = self.view.bounds
            let arrCouach = [
                [ "rect"    :  CGRect(x:f.width - 84 , y:f.height - 38 , width:64, height:30),
                  "caption" :  "まずはじめに、設定画面で聞きたいインスタンスを最初に設定しましょう",
                  "shape"   : "square",
                  ],
                ]
            let couach = WSCoachMarksView(frame: self.view.bounds)
            couach.coachMarks = arrCouach
            couach.maskColor = UIColor(white: 0.0, alpha: 0.65)
            couach.delegate = self
            self.view.addSubview(couach)
            isRotateLoked = true
            couach.start()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if(LTLTalkManager.shared.isSpeaking()) {
            LTLTalkManager.shared.pauseSpeak()
        }
        if (self.timer != nil)  {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    override var shouldAutorotate: Bool {
        return !isRotateLoked
    }
    
// MARK: - リロード
    func reloadTimeline(aTimer: Timer) {
        let realm = try! Realm()
        let instances = realm.objects(MastodonInstance.self)
        if (self.pickerView.selectedRow(inComponent: 0) == 0) { return }
        let instanceForCell = instances[self.pickerView.selectedRow(inComponent: 0) - 1]

        TimelineManager.shared.loadLocalTimelineWith(callBack: {(result: Bool, instance: MastodonInstance?, error: Error?) -> Void in
            if(result && !LTLTalkManager.shared.isSpeaking()) {
                // --- 選択されたインスタンスの読み上げポイントを確定する
                let oldLastToot = instanceForCell.lastTalkTootId
                let realm = try! Realm()
                try! realm.write {
                    instanceForCell.lastTalkTootId = (TimelineManager.shared.nextToot()?["id"]?.stringValue)!
                }
                // --- 当該トゥートの表示
                self.show(toot: TimelineManager.shared.currentToot!)
                
                // --- 読み上げの開始
                if (instanceForCell.lastTalkTootId != oldLastToot) {
                    LTLTalkManager.shared.startTalk()
                }
                
            } else if (error != nil) {
                // --- エラーがあった場合、アラートを表示して、タイマーを切る
                self.showErrorAlert(error: error!)
                aTimer.invalidate()
            }
        }, since_id: TimelineManager.shared.arrTimeLine().last?["id"]?.numberValue)
    }

// MARK:- アクションメソッド

    @IBAction func changeSwMute(_ sender: UISwitch) {
        // ミュート
        // --- 実装予定
    }
    
    @IBAction func tapBtnPrev(_ sender: UIButton) {
        // 一つ前のTootを読み込む
        let toot = TimelineManager.shared.prevToot()
        if (toot != nil){
            LTLTalkManager.shared.startTalk()
            self.show(toot: toot!)
        }
    }
    
    @IBAction func tapBtnNext(_ sender: UIButton) {
        // 一つ先のTootを読み込む
        let toot = TimelineManager.shared.nextToot()
        if (toot != nil) {
            LTLTalkManager.shared.startTalk()
            self.show(toot: toot!)
        }
    }
    
    @IBAction func tapBtnStopStart(_ sender: UIButton) {
        // Tootの読み込み停止／再開
        if (TimelineManager.shared.currentInstance == nil) {
            return
        }
        if (LTLTalkManager.shared.isPaused()) {
            LTLTalkManager.shared.resumeSpeak()
        } else if (LTLTalkManager.shared.isSpeaking()){
            LTLTalkManager.shared.pauseSpeak()
        }
    }
    
// MARK:- UIPickerView関連

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // コンポーネントの数
        return 1;
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // セルの数
        let realm = try! Realm()
        return realm.objects(MastodonInstance.self).count + 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        // セルの高さ
        return 32.0;
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // セルのビューを作る
        let realm = try! Realm()
        let instances = realm.objects(MastodonInstance.self)
        let newView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        
        let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height:30))
        newView.addSubview(iv)

        let label = UILabel(frame: CGRect(x: 30, y: 0, width: 170, height: 30))
        newView.addSubview(label)

        if ((instances.count == 0) || (row == 0)) {
            // --- インスタンスがない
            iv.image = UIImage(named: "NoImage")
            label.text = "ミュート"
        } else {
            let instanceForCell = instances[row - 1]
            iv.image = UIImage.init(data: instanceForCell.avaterImage!)
            label.text = instanceForCell.address
        }
        
        return newView;
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (row == 0) {
            // ミュートRowの場合
            LTLTalkManager.shared.pauseSpeak()
            let userDefault: UserDefaults = UserDefaults.standard
            userDefault.set("", forKey: "uuid")
            userDefault.synchronize()
            TimelineManager.shared.currentInstance = nil
            TimelineManager.shared.currentToot = nil
            show(toot: nil)
        } else {
            self.loadInstanceData(row: row)
        }
    }
    
    func loadInstanceData(row : Int) {
        // セルの選択
        // --- 選択されたセルに対応するインスタンス
        let realm = try! Realm()
        let instances = realm.objects(MastodonInstance.self)
        if ((instances.count == 0) || (row == 0)){ return }
        let instanceForCell = instances[row - 1]

        // --- 選択されたインスタンスをロード
        SVProgressHUD.show(withStatus: "ロード中")
        TimelineManager.shared.initWith(instance: instanceForCell)
        TimelineManager.shared.loadLocalTimelineWith(callBack: {(result: Bool, instance: MastodonInstance?, error: Error?) -> Void in
            SVProgressHUD.dismiss()
            if(result) {
                // --- 選択されたインスタンスの読み上げポイントを確定する
                let realm = try! Realm()
                try! realm.write {
                    instanceForCell.lastTalkTootId = (TimelineManager.shared.setCurrentToot(lastTootId: instanceForCell.lastTalkTootId)["id"]?.stringValue)!
                }
                
                let userDefault: UserDefaults = UserDefaults.standard
                userDefault.set(instanceForCell.uuid, forKey: "uuid")
                userDefault.synchronize()
                
                // --- 当該トゥートの表示
                self.show(toot: TimelineManager.shared.currentToot!)
                
                // --- 読み上げの開始
                LTLTalkManager.shared.startTalk()
                
                // --- タイマー
                if (self.timer == nil) {
                    self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(type(of: self).reloadTimeline(aTimer:)), userInfo: nil, repeats: true)

                }
            } else if (error != nil){
                // --- エラーがあった場合、ダイアログを表示する
                self.showErrorAlert(error: error!)
            }
        }, since_id: 0)
    }
    
    // MARK:- 表示
    
    func show(toot: Dictionary<String, JSON>?) {
        if (toot
         == nil) {
            // --- インスタンスがない場合はこれらの画面を消す
            self.ivTootAvater.isHidden = true
            self.lblTootName.isHidden = true
            self.lblTootUserId.isHidden = true
            self.lblTootTime.isHidden = true
            self.tvTootMessage.isHidden = true
            return
        } else {
            self.ivTootAvater.isHidden = false
            self.lblTootName.isHidden = false
            self.lblTootUserId.isHidden = false
            self.lblTootTime.isHidden = false
            self.tvTootMessage.isHidden = false
        }
        var tootToShow = ""
        if(toot?["spoiler_text"]?.stringValue != "") {
            tootToShow = (toot?["spoiler_text"]?.stringValue)!
        } else {
            tootToShow = (toot?["content"]?.stringValue)!
        }
        self.tvTootMessage.text = TootStringManager.stringByStripping(HTML: tootToShow)
        
        // --- アバターとユーザー名／ユーザーID
        let AvatarURL = toot?["account"]?.dictionary?["avatar"]?.stringValue

        NSLog("Avater URL : %@", AvatarURL!)
        if (AvatarURL != nil) {
            if (AvatarURL?.hasPrefix("/"))! {
                // --- ローカルNoImageを持ってる場合
                self.ivTootAvater.image = UIImage(named: "NoImage")
            } else {
                self.ivTootAvater.setImageWith((toot?["account"]?.dictionary?["avatar"]?.url)!)
            }
        } else {
            self.ivTootAvater.image = UIImage(named: "NoImage")
        }
        
        let display_name = toot?["account"]?.dictionary?["display_name"]?.stringValue
        
        if (display_name == "") {
            self.lblTootName.text = toot?["account"]?.dictionary?["username"]?.stringValue
        } else {
            self.lblTootName.text = display_name
        }
        
        self.lblTootUserId.text = "@" + (toot?["account"]?.dictionary?["username"]?.stringValue)!
        
        // 時間(created_at)を比較する
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.locale = Locale(identifier: "en_US_POSIX")
        let date: Date = df.date(from: (toot?["created_at"]?.stringValue)!)!
        /// この時点でdateではUTC

        let interval: TimeInterval = Date().timeIntervalSince(date)
                
        // --- ラベルを設定
        if (interval >= 24 * 3600) {
            self.lblTootTime.text = String(format: "%4.0f日前", (interval / (24 * 3600)))
        } else if (interval >= 3600) {
            self.lblTootTime.text = String(format: "%2.0f時間前", (interval / 3600))
        } else if (interval >= 60) {
            self.lblTootTime.text = String(format: "%2.0f分前", (interval / 60))
        } else {
            self.lblTootTime.text = String(format: "%2.0f秒前", interval / 1)
        }
    }
    
    // MARK: - 通知
    func renewToot(notification: Notification){
        self.show(toot: TimelineManager.shared.currentToot!)
    }
    
    // MARK: - ダイアログ
    func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "エラー",
                                      message: error.localizedDescription ,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - WSCoachMarksViewDelegate
    func coachMarksViewDidCleanup(_ coachMarksView: WSCoachMarksView!) {
        // コーチ終了時に回転ロックを外す
        isRotateLoked = false
    }

}

