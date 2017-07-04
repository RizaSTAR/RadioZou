//
//  InstanceDetailViewController.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/15.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

class InstanceDetailViewController: UIViewController, MstdnAuthViewDelegate {

    var isNewItem = false
    var target: MastodonInstance? = nil

    @IBOutlet weak var tfInstanceName: UITextField!
    @IBOutlet weak var ivAvater: UIImageView!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let myNotification = NSNotification.Name("failGetClientId")
        
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(type(of:self).failGetClientId(notification:)),
                           name: myNotification,
                           object: nil)

        if (isNewItem) {
            // 新規インスタンスの場合
            target = MastodonInstance()
        } else {
            // 新規でない場合
            btnDone.isHidden = true
            tfInstanceName.isEnabled = false;   // 編集不可
        }
        
        initOutlet()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Init
    func initOutlet() {
        // Outletの初期化
        tfInstanceName.text = target?.address;
        if (target?.avaterImage != nil) {
            let image: UIImage = UIImage(data: (target?.avaterImage)! as Data)!
            ivAvater.image = image
        }
        // FOR DEBUG
//        tfInstanceName.text = "gensokyo.cloud"
    }
    
    // MARK: - Action Method
    @IBAction func tapBtnDone(_ sender: Any) {
        // 新規作成の作成ボタン
        if (tfInstanceName.text != "") {
            SVProgressHUD.show()
            target?.address = tfInstanceName.text!;
//            performSegue(withIdentifier: "Auth", sender: target);
            MstdnAccessManager.sharedManager.getAccessTokenFromInstance(instance:target, delegate:self)
        }
        
    }
    
    @IBAction func tapBtnCancel(_ sender: Any) {
        // 新規作成時のキャンセル、既存インスタンスの削除
        if (isNewItem) {
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    // MARK: - Delegate
    func setAccessToken(accessToken: String!, dataImage: Data!, name: String!, userId: NSNumber!) {
        // Accessトークンを得ることが出来た
        target?.accessId = accessToken
        target?.avaterImage = dataImage
        target?.uuid = UUID.init().uuidString
        
        // --- Realmで永続化する
        let realm = try! Realm()
        try! realm.write() {
            realm.add(target!)
        }
        
        // --- 画面を戻す
//        dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func getAccount() -> MastodonInstance {
        // アカウントを返す
        return target!
    }
    
    
    // MARK: - Notification
    func failGetClientId(notification: Notification) {
        let alert = UIAlertController(title: "エラー",
        message: (notification.userInfo?["error"] as! String) , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
