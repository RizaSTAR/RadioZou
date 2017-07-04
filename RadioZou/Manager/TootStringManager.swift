//
//  TootStringManager.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/29.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit

class TootStringManager: NSObject {
    class func stringByStripping(HTML: String) -> String {
        var string = HTML
        var r : Range<String.Index>?
        r = string.range(of:"<(BR|br)[^>]+>", options: .regularExpression)
        while (r != nil) {
            string = string.replacingCharacters(in: r!, with: "\n")
            r = string.range(of:"<(BR|br)[^>]+>", options: .regularExpression)
        }
        
        r = string.range(of:"<[^>]+>", options: .regularExpression)
        while (r != nil) {
            string = string.replacingCharacters(in: r!, with: "")
            r = string.range(of:"<[^>]+>", options: .regularExpression)
        }
        
        return string
        
    }
    
    class func stringByStripping(URL: String) -> String {
    
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let links = detector.matches(in: URL, range: NSMakeRange(0, URL.characters.count))
        let flatMap = links.flatMap { $0.url }
        
        var string = URL
        
        for (link) in flatMap {
            string = string.replacingOccurrences(of: link.absoluteString, with: "")
        }
        
        return string
    }
}
