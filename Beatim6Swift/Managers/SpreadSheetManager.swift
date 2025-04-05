//
//  SpreadSheetManager.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/04/05.
//

import Foundation
import Alamofire
import SwiftyJSON

struct ResponseResult: Decodable {
    let status: String
    let message: String?
}

class SpreadSheetManager: ObservableObject {

    //NOTE:AppScriptの内容の修正を行った際は、再度デプロイしてURLを更新してください。
    let url = "https://script.google.com/macros/s/AKfycbzNgG3j9C5M1e9O9T3joAOVd2FCdGyk-TcifrYHxw0If8rkGrB6s4dnK-akkTM8W_0N6A/exec"

//ID,曲名,SPM,rightStepSound,LeftStepSound
    func post(
        id: String,
        music: String,
        spm: Double,
        rightStepSound: String,
        leftStepSound: String
    ) {
        
        //POSTするデータの生成
        var data: Dictionary<String, Any> = [:]
        data["id"] = id
        
        //現在時刻
        let dt = Date()
        let dateFormatter = DateFormatter()
        // DateFormatter を使用して書式とロケールを指定する
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
        data["timeStamp"] = dateFormatter.string(from: dt)
        
        data["music"] = music
        data["spm"] = spm
        data["rightStepSound"] = rightStepSound
        data["leftStepSound"] = leftStepSound
        
        //POST処理
        AF.request(url,
                   method: .post,
                   parameters: data,
                   encoding: JSONEncoding.default,
                   headers: nil
        ).responseDecodable(of: ResponseResult.self) { response in
            switch response.result {
            case .success(let result):
                if result.status == "success" {
                    print("✅ 成功しました")
                } else {
                    print("⚠️ エラー:", result.message ?? "不明なエラー")
                }

            case .failure(let error):
                print("❌ 通信エラー:", error)
            }
        }
    }
}
