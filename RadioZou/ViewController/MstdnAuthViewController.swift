//
//  MstdnAuthViewController.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/16.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol MstdnAuthViewDelegate {
    func setAccessToken(accessToken:String! , dataImage:Data!, name:String!, userId:NSNumber!) -> Void
    func getAccount() -> MastodonInstance
}

class MstdnAuthViewController: UIViewController, UIWebViewDelegate {

    
    @IBOutlet weak var webView: UIWebView!
    var url : URL!
    var delegate : MstdnAuthViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "認証"

        let myNotification = NSNotification.Name("successGetImage")

        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(type(of:self).successGetImage(notification:)),
                               name: myNotification,
                             object: nil)

        self.navigationItem.hidesBackButton = true
        
        // --- 代わりの戻るボタンを作る
        let button : UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage.init(named: "BackArrow"), for: UIControlState.normal)
        button.setTitle("戻る", for: UIControlState.normal)
        button.frame = CGRect(x:0, y:0, width:64, height:30)
        button.addTarget(self, action: #selector(self.tapBtnBack(sender:)), for:UIControlEvents.touchUpInside)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        
        let backButton: UIBarButtonItem = UIBarButtonItem.init(customView: button)
        backButton.action = #selector(self.tapBtnBack(sender:))

        self.navigationItem.leftBarButtonItem = backButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (url != nil) {
            webView.loadRequest(URLRequest(url: url))
        }
    }
    
    func tapBtnBack(sender: UIBarButtonItem) {
        // 戻るボタンを押した
        if (self.webView.canGoBack) {
            // --- webViewが戻れるなら戻る
            self.webView.goBack()
        } else {
            // --- 戻せない場合は画面（ViewController）を戻す
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (SVProgressHUD.isVisible()) {
            SVProgressHUD.dismiss()
        }
    }
    
    // MARK: - UIWebViewDelegate
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // webviewロード時のチェック
        let URLComponent: NSURLComponents = NSURLComponents(string: (url?.absoluteString)!)!
        let strHost: String! = URLComponent.host!
        let strPath: String! = URLComponent.path!
        let strUrl = "https://" + strHost + strPath + "/" 
        if (request.url?.absoluteString.hasPrefix(strUrl))! {
            // --- リダイレクトを検出
            NSLog("--- リダイレクトを検出")
            let code: String = (request.url?.lastPathComponent)!
            NSLog("--- code is [%@]", code)
            
            DispatchQueue.main.async {
                // --- メインスレッドでトークンを得る作業を始める
                MstdnAccessManager.sharedManager.getAccessTokenWithAccount(instance: (self.delegate?.getAccount())!,
                                                                           aCode: code,
                                                                           callBack:{(token: String) -> Void in
                                                                                // tokenを得た
                                                                                MstdnAccessManager.sharedManager.getCurrentUserDataWith(instance: (self.delegate?.getAccount())!, accessToken: token)
                                                                            }
                                                                            )
            }
            return false;
        } else {
            // --- リダイレクトではない
            SVProgressHUD.show()
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if (SVProgressHUD.isVisible()) {
            SVProgressHUD.dismiss()
        }
    }
    
    // MARK: - notification
    
    func successGetImage(notification: NSNotification) {
        // 画像の取得に成功した
        let dic: Dictionary<String, Any> = notification.userInfo as! Dictionary<String, Any>
        let dataNoImage = UIImagePNGRepresentation(UIImage(named: "NoImage")!)!
        self.delegate?.setAccessToken(accessToken: dic["access_token"] as! String,
                                      dataImage: (dic["image"] != nil) ? dic["image"] as! Data : dataNoImage,
                                       name: dic["name"] as! String,
                                        userId: dic["id"] as! NSNumber)
    }
    
}
