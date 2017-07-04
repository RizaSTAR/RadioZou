//
//  MastodonInstance.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/15.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import RealmSwift

// マストドンのインスタンス情報を収めるオブジェクト

class MastodonInstance: Object {

    dynamic var address = ""
    dynamic var accessId = ""
    dynamic var language = ""   // 未使用
    dynamic var lastTalkTootId = ""
    dynamic var avaterImage : Data? = nil
    dynamic var createdAt : Date? = nil
    dynamic var uuid = ""
    dynamic var order = -1
    dynamic var client_secret = ""
    dynamic var client_id = ""

}
