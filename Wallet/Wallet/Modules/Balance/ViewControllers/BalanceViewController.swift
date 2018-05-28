//
//  BalanceViewController.swift
//  Wallet
//
//  Created by Maynard on 2018/5/7.
//  Copyright © 2018年 New Horizon Labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BalanceViewController: UIViewController {

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var receiveButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var navBalanceLabel: UILabel!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var headerView: UIView!
    var headerViewHeight: CGFloat = 0.0
    override var hideNavigationBar: Bool {
        return true
    }
    
    let disposeBag = DisposeBag()
    
    var data: Variable<[AccountAsset]> = Variable([])
    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureUI()
        //配置tableview
        tableView.register(R.nib.accountAssetTableViewCell)
        tableView.delegate = self
        data.asObservable().bind(to: tableView.rx.items(cellIdentifier: R.nib.accountAssetTableViewCell.identifier, cellType: AccountAssetTableViewCell.self)) { _, model, cell in
            cell.configure(model: model)
            }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(AccountAsset.self).subscribe(onNext: {[weak self] (model) in
            self?.showToekn(asset: model)
        }).disposed(by: disposeBag)
        
        
        ServiceHelper.shared.account
        .asObservable()
            .subscribe(onNext: {[weak self] (account) in
                if let account = account {
                    self?.update(model: account)
                }
            })
        .disposed(by: disposeBag)
    }
    
    
    func showToekn(asset: AccountAsset) {
        let vc = R.storyboard.balance.otherTokenViewController()!
        vc.asset = asset
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //获取用户数据并刷新页面
        ServiceHelper.shared.getAccount()
    }
    
    func configureUI() {
        title = R.string.tron.balanceNavTitle()
        navBalanceLabel.text = R.string.tron.balanceNavTitle()
        sendButton.setTitle(R.string.tron.balanceButtonSend(), for: .normal)
        receiveButton.setTitle(R.string.tron.balanceButtonReceive(), for: .normal)
        sendButton.setBackgroundColor(UIColor.mainNormalColor, forState: .normal)
        receiveButton.setBackgroundColor(UIColor.mainNormalColor, forState: .normal)
        
        tableView.separatorColor = UIColor.lineColor
    }
    
    func update(model: TronAccount) {
        self.data.value = model.assetArray
        self.balanceLabel.text = (Double(model.balance)/1000000.0).numberFormat()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if headerViewHeight == 0 {
            
        }
        headerViewHeight = kScreenWidth * 210.0/375.0
        self.updateHeaderViewHeight()
    }
    
    func updateHeaderViewHeight() {
        view.layoutIfNeeded()
        var frame = headerView.frame
        frame.size.height = backgroundImageView.frame.maxY
        headerView.frame = frame
        tableView.tableHeaderView = headerView
        let contentOffsetY = tableView.contentOffset.y
        if (contentOffsetY > 0) {
            
        } else {
            let frame = CGRect(x: contentOffsetY, y: contentOffsetY, width: view.frame.size.width + (-contentOffsetY) * 2, height: headerViewHeight + (-contentOffsetY))
            backgroundImageView.frame = frame
            gradientView.frame = frame
        }
    }

}
extension BalanceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        print(contentOffsetY)
        if (contentOffsetY > 0) {
            
        } else {
            let frame = CGRect(x: contentOffsetY, y: contentOffsetY, width: view.frame.size.width + (-contentOffsetY) * 2, height: headerViewHeight + (-contentOffsetY))
            backgroundImageView.frame = frame
            gradientView.frame = frame
            headerView.clipsToBounds = false
        }
    }
}
