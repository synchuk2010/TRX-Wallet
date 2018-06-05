//
//  VoteInputView.swift
//  Wallet
//
//  Created by Maynard on 2018/5/9.
//  Copyright © 2018年 New Horizon Labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VoteInputView: UIView, XibLoadable, Popable {
    
    @IBOutlet weak var accountTitleLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var numberTipLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    var model: Witness? {
        didSet {
            urlLabel.text = model?.url
        }
    }
    
    var successBlock:((Int64) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        baseConfigure()
    }
    
    func baseConfigure() {
        accountTitleLabel.text = R.string.tron.votePopViewAccountLabelTitle()
        numberTipLabel.text = R.string.tron.votePopViewInputTitle()
        confirmButton.setTitle(R.string.tron.votePopViewComfirmButtonTitle(), for: .normal)
        
        confirmButton.addTarget(self, action: #selector(confirmButtonClick), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
        
        balanceLabel.text = ServiceHelper.shared.balance + " TRX"
        
        (textField.rx.text).orEmpty.asObservable()
            .map { return $0.count > 0 }
            .bind(to: numberTipLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    @objc func closeButtonClick() {
        popDismiss()
    }
    
    @objc func confirmButtonClick() {
        guard let model = model, let account = ServiceHelper.shared.account.value, let text = textField.text, let number = Int64(text) else {
            return
        }
        self.textField.resignFirstResponder()
        
        self.vote(model: model, account: account, number: number)
        
    }
    
    func vote(model: Witness, account: TronAccount, number: Int64) {
        //投票数据
        let vote = VoteWitnessContract_Vote()
        vote.voteAddress = model.address
        vote.voteCount = number
        
        var voteContractArray: [VoteWitnessContract_Vote] = ServiceHelper.shared.voteArray.filter({ (vote) -> Bool in
            return model.address.addressString != vote.voteAddress.addressString
        }).map { (object) -> VoteWitnessContract_Vote in
            let vote = VoteWitnessContract_Vote()
            vote.voteAddress = object.voteAddress
            vote.voteCount = object.voteCount
            return vote
        }
        
        voteContractArray.append(vote)
        
        //用户数据
        let contract = VoteWitnessContract()
        contract.ownerAddress = account.address
        contract.votesArray = NSMutableArray(array: voteContractArray)
        
        if let vc = self.viewController() {
            vc.displayLoading()
        }
        
        ServiceHelper.shared.service.voteWitnessAccount(withRequest: contract) { (transaction, error) in
            if let action = transaction {
                ServiceHelper.shared.broadcastTransaction(action, completion: { (result, error) in
                    if let response = result {
                        let result = response.result
                        let message = String.init(data: response.message, encoding: .utf8)
                        if result {
                            HUD.showText(text: R.string.tron.hudSuccess())
                            ServiceHelper.shared.voteChange.onNext(())
                            self.successBlock?(number)
                            self.popDismiss()
                        } else {
                            HUD.showError(error: response.errorMessage)
                        }
                        
                    }
                    if let vc = self.viewController() {
                        vc.hideLoading()
                    }
                })
            } else if let error = error {
                if let vc = self.viewController() {
                    vc.hideLoading()
                }
                HUD.showError(error: (error.localizedDescription))
            }
        }
    }


}
