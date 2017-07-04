//
//  TimelineManager.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/28.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import AFNetworking
import SwiftyJSON

class TimelineManager: NSObject {

    static let shared = TimelineManager ()
    
    var currentInstance: MastodonInstance? = nil
    var arrToot:[Dictionary<String, JSON>] = []
    var currentToot:Dictionary<String, JSON>? = nil
    
    private override init() {
        
    }
    
    func initWith(instance: MastodonInstance) {
        // 現在のインスタンスを設定
        if (currentInstance == instance) { return }
        currentInstance = instance
        arrToot.removeAll()
    }
    
    func loadLocalTimelineWith(callBack:@escaping (Bool, MastodonInstance?, Error?) -> Void, since_id:NSNumber?) {
        // LocalTimelineをロードする
        if (currentInstance == nil) {
            NSLog("読み込み対象のインスタンスが設定されていません --- ")
            return
        }
        let url = "https://" + (currentInstance?.address)! + "/api/v1/timelines/public"
        var json: Dictionary = [
            "local" : "true",
        ]
        if (since_id != nil && (since_id?.int32Value)! > 0) {
            json = [
                "local" : "true",
                "since_id" : "\(since_id!)",
            ]
        }
        
        let manager = AFHTTPSessionManager()
        let strHeader = "Bearer " + (currentInstance?.accessId)!
        manager.requestSerializer.setValue(strHeader, forHTTPHeaderField: "Authorization")
        manager.get(url,
                    parameters: json,
                    success: {(task: URLSessionDataTask, responseObject: Any) -> Void in
                        if (self.arrToot.count == 0) {
                            // 新規Toot
                            var newToot: [Dictionary<String, JSON>] = []
                            let responceArray = JSON(responseObject)
                            for(_, value) in responceArray {
                                let dic: Dictionary<String, JSON> = value.dictionary!
                                newToot.append(dic)
                            }
                            self.arrToot += newToot
                            self.currentToot = self.arrToot.last
                        } else {
                            // 新規でないToot
                            let mostRecent: Dictionary<String, JSON> = self.arrToot.first!
                            let responceArray = JSON(responseObject)
                            var newToot: [Dictionary<String, JSON>] = []
                            for(_, value) in responceArray {
                                if (mostRecent["id"] == value.dictionary?["id"]) {
                                    break;
                                }
                                let dic: Dictionary<String, JSON> = value.dictionary!
                                newToot.append(dic)
                            }
                            newToot += self.arrToot
                            self.arrToot = newToot
                        }
                        callBack(true, self.currentInstance!, nil)
        },
                    failure: {(task: URLSessionDataTask?, error: Error) -> Void in
                        // --- エラー
                        NSLog("Error[%@]",error.localizedDescription)
                        callBack(false, nil, error)
        })
    }
    
    func setCurrentToot(lastTootId: String) -> Dictionary<String, JSON> {
        // 表示／読み上げる対象のトゥートを決める
        for(value) in self.arrToot {
            if (value["id"]?.stringValue == lastTootId) {
                self.currentToot = value
                return value
            }
        }
        self.currentToot = self.arrToot.last!
        return self.arrToot.last!
    }
    
    func prevToot() -> Dictionary<String, JSON>? {
        // 前のトゥートに移動
        if (currentToot == nil) {
            return nil
        }
        let index = self.arrToot.index{ $0 == self.currentToot!}
        if (index == nil) {
            return self.currentToot!
        }


        if (index! < (self.arrToot.count - 1)) {
            self.currentToot = self.arrToot[index! + 1]
            return self.arrToot[index! + 1]
        } else {
            return self.currentToot!
        }
    }
    
    func nextToot() -> Dictionary<String, JSON>? {
        // 次のトゥートに移動
        if (currentToot == nil) {
            return nil
        }
        let index = self.arrToot.index{ $0 == self.currentToot!}
        if (index == nil) {
            return self.currentToot!
        }
        if (index! > 0) {
            self.currentToot = self.arrToot[index! - 1]
            return self.arrToot[index! - 1]
        } else {
            return self.currentToot!
        }
    }
    
    
    func arrTimeLine() -> Array<Dictionary<String, JSON>> {
        // arrTootを返す
        return self.arrToot
    }

}
