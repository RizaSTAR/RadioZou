//
//  MstdnAccessManager.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/16.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import RealmSwift
import AFNetworking
import SwiftyJSON
import SVProgressHUD

class MstdnAccessManager: NSObject {

    static let sharedManager = MstdnAccessManager()
    private override init() {
        
    }
    
    func getAccessTokenFromInstance(instance: MastodonInstance?, delegate: MstdnAuthViewDelegate!) -> Void{
        // 指定されたインスタンスのAccessトークンを取りに行く
        // トークンを取るためにはclient_secret client_idをもらわないといけない
        // OAuthが無ければ取りに行く
        // あるなら、単純にAPIを回してAccessTokenを取れる
        // 権限はreadでOK
        
        let json: Dictionary = [
            "client_name" : "Zou",
            "redirect_uris" : "urn:ietf:wg:oauth:2.0:oob",
            "scopes" : "read",
        ]
        
        let url: String = String(format:"https://%@/api/v1/apps", instance!.address)
        let manager = AFHTTPSessionManager()
        manager.post(url,
                     parameters: json,
                     success: {(task: URLSessionDataTask, responceObject: Any) -> Void in
                        // --- client_id, client_secretを取得できた
                        SVProgressHUD.dismiss()
                        let responceDic = responceObject as! Dictionary<String, Any>
                        instance?.client_id = responceDic["client_id"] as! String
                        instance?.client_secret = responceDic["client_secret"] as! String
                        // --- MstdnAuthViewControllerを表示する
                        self.showAuthViewController(instance: instance!, delegate: delegate)
            },
                     failure: {(task: URLSessionDataTask?, error: Error) -> Void in
                        // --- エラー
                        SVProgressHUD.dismiss()
                        NSLog("アプリケーション認証のPOSTに失敗")
                        
                        // --- アラート表示の実施。errorのローカライズメッセージをそのままuserInfoとして送る
                        let name = NSNotification.Name(rawValue: "failGetClientId")
                        NotificationCenter.default.post(name: name,
                                                        object: nil,
                                                        userInfo: ["error" : error.localizedDescription])

                        
            }
        )
        
    }
    
    func showAuthViewController(instance: MastodonInstance, delegate: MstdnAuthViewDelegate!) -> Void {
        // MstdnAuthViewControllerを表示する
        // OAuthでブラウザを使ってOAuthを取りに行く
        
        let strUrl = String(format: "https://%@/oauth/authorize?client_id=%@&redirect_uri=%@&response_type=code&scope=read",
                            arguments: [instance.address, instance.client_id, "urn:ietf:wg:oauth:2.0:oob"])

        let url = URL(string: strUrl)
        
        var baseView = UIApplication.shared.keyWindow?.rootViewController
        while (baseView?.presentedViewController != nil && !((baseView?.presentedViewController?.isBeingDismissed)!)) {
            baseView = baseView?.presentedViewController
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc: MstdnAuthViewController = storyboard.instantiateViewController(withIdentifier: "AuthVC") as! MstdnAuthViewController
        
        vc.url = url
        vc.delegate = delegate
        
        DispatchQueue.main.async {
            NSLog("baseView:%@", baseView ?? "NO VALUE")
            NSLog("navigationController:%@", baseView?.navigationController ?? "NO VALUE")
            if (baseView is UINavigationController) {
                (baseView as! UINavigationController).pushViewController(vc, animated: true)
            }
        }
    }
    
    func getAccessTokenWithAccount(instance: MastodonInstance, aCode: String, callBack:@escaping (String) -> Void) {
        // Accessトークンを取得しに走る
        let url = String(format: "https://%@/oauth/token", instance.address)
        let json: Dictionary = [
            "grant_type" : "authorization_code",
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
            "client_id" : instance.client_id,
            "client_secret" : instance.client_secret,
            "code" : aCode,
        ]
        
        let manager: AFHTTPSessionManager = AFHTTPSessionManager()
        manager.post(url,
                     parameters: json,
                     success: {(task: URLSessionDataTask, responseObject: Any) -> Void in
                     // --- token取得成功
                        callBack((responseObject as! Dictionary<String, Any>)["access_token"] as! String)
            },
                     failure: {(operation, error: Error) -> Void in
                     // --- token取得失敗
                        NSLog("fail --- %@", error.localizedDescription)
            }
        )
    }
    
    func getCurrentUserDataWith(instance: MastodonInstance, accessToken: String) {
        // 得られたAccessトークンからユーザー情報を得る
        
        let url = String(format: "https://%@/api/v1/accounts/verify_credentials", arguments:[instance.address])
        NSLog("url : %@", url)
        let manager = AFHTTPSessionManager()
        let strHeader = "Bearer " + accessToken
        manager.requestSerializer.setValue(strHeader, forHTTPHeaderField: "Authorization")
        manager.get(url,
                    parameters: [],
                    success: {(task: URLSessionDataTask, responseObject: Any) -> Void in
                        // --- アバターの画像を得られた
                        let responseDic = JSON(responseObject)
                        let url = URL(string: responseDic["avatar"].string!)
                        var dataImage: Data
                        do {
                            dataImage = try Data(contentsOf:url!)
                        } catch {
                            dataImage = UIImagePNGRepresentation(UIImage(named: "NoImage")!)!
                        }
                        
                        // --- アバター以外のもの
                        let strName: String! = (responseDic["display_name"].string == "") ? responseDic["username"].string : responseDic["display_name"].string
                        let name = NSNotification.Name(rawValue: "successGetImage")
                        NotificationCenter.default.post(name: name,
                         object: nil,
                          userInfo: [
                            "access_token" : accessToken,
                            "image" : dataImage,
                            "name" : strName,
                            "id" : responseDic["id"].number ?? 0
                          ])
                        
                        
        },
                    failure: {(task: URLSessionDataTask?, error: Error) -> Void in
                    // --- アバターの画像を得られれなかった場合
                    // TODO: 代わりの画像をあてがう
                    NSLog("Error[%@]",error.localizedDescription)
                        
        })
        
    }

    
}
