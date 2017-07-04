//
//  ConfigRootViewController.swift
//  RadioZou
//
//  Created by Takahiro Niijima on 2017/06/15.
//  Copyright © 2017年 Takahiro Niijima. All rights reserved.
//

import UIKit
import RealmSwift
import WSCoachMarksView
import DZNEmptyDataSet

class ConfigRootViewController: UITableViewController, DZNEmptyDataSetSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        let btnAppend = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(self.tapBtnAppend(sender:)))

        self.navigationItem.setRightBarButton(btnAppend, animated: false)
        
        let btnClose = UIBarButtonItem(title: "閉じる", style: UIBarButtonItemStyle.plain,
                                       target: self,
                                       action: #selector(self.tapBtnCancel(sender:)))
        self.navigationItem.setLeftBarButton(btnClose, animated: false)
        
        self.title = "インスタンス一覧"
        
        // --- データが空のときに表示するDZNEｍptyDataSetSourceを使うための処理
        self.tableView.tableFooterView = UIView()
        self.tableView.emptyDataSetSource = self;
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.tableView.reloadData()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // セクションのRowの数
        let realm = try! Realm()
        let instances =  realm.objects(MastodonInstance.self)
        
        return instances.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellInstance", for: indexPath)

        let realm = try! Realm()
        let instances =  realm.objects(MastodonInstance.self)
        let instanceForCell = instances[indexPath.row]
        
        cell.textLabel?.text = instanceForCell.address
        cell.imageView?.image = UIImage.init(data:instanceForCell.avaterImage!)
        

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // --- 確認後削除
            self.deleteRow(indexPath: indexPath)
        } else if editingStyle == .insert {
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルの選択
        return
        
    }
    
    // MARK: - DZNEmptyDataSet
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "NoInstance")
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 画面遷移時の処理
        if (segue.identifier == "showDetail") {
            let vc: InstanceDetailViewController = segue.destination as! InstanceDetailViewController
            if (sender == nil) {
                // senderがnilの場合、新しいデータを作る
                vc.isNewItem = true
            } else {
                
            }
        }
    }
    
    // MARK: - UIBarButton
    internal func tapBtnAppend(sender: UIBarButtonItem) {
        // 追加ボタン
        // --- senderを含めずにsegueを起動
        self.performSegue(withIdentifier: "showDetail", sender: nil)
    }
    
    internal func tapBtnCancel(sender: UIBarButtonItem) {
        // キャンセルボタン
        // --- 画面をただ戻す
        self.dismiss(animated: true, completion: nil)
    }
    
    internal func deleteRow(indexPath:IndexPath) {
        // 削除確認後、消す
        let alert = UIAlertController(title: "確認",
        message: "インスタンスの登録を削除します。よろしいですか",
        preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "削除", style: UIAlertActionStyle.destructive,
                                      handler:{ (action: UIAlertAction!) -> Void in
                                        // --- 対象
                                        let realm = try! Realm()
                                        let instances =  realm.objects(MastodonInstance.self)
                                        let instanceForCell = instances[indexPath.row]
                                        
                                        // --- 対象がCurrentだったらnilにする
                                        if (TimelineManager.shared.currentInstance == instanceForCell) {
                                            TimelineManager.shared.currentInstance = nil
                                            TimelineManager.shared.currentToot = nil
                                            let ud: UserDefaults = UserDefaults.standard
                                            ud.set("", forKey: "uuid")
                                            ud.synchronize()
                                        }
                                        
                                        // --- Realmから削除
                                        try! realm.write {
                                            realm.delete(instanceForCell)
                                        }
                                        // --- tableViewからも消す
                                        self.tableView.deleteRows(at: [indexPath], with: .fade)
        }))
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }

}
