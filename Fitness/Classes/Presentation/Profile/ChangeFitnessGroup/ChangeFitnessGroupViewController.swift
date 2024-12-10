//
//  ChangeFitnessGroupViewController.swift
//  Fitness
//
//  Created by Андрей Чернышев on 02.12.2024.
//

import UIKit
import RxSwift
import RxCocoa

final class ChangeFitnessGroupViewController: UIViewController {
    private lazy var mainView = ChangeFitnessGroupView(vc: self)
    
    private lazy var viewModel = ChangeFitnessGroupViewModel()
    
    private lazy var disposeBag = DisposeBag()
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.tryAgain = { [weak self] error -> Observable<Void> in
            guard let self = self else {
                return .never()
            }
            
            return self.open(error: error)
        }
        
        let output = viewModel.configure(input: ChangeFitnessGroupViewModel.Input(
            didCollectedFitnessGroup: mainView.didCollectedFitnessGroup,
            didCollectedSkillLevel: mainView.didCollectedSkillLevel,
            didCollectedWeekSchedule: mainView.didCollectedWeekSchedule,
            didCollectedGoals: mainView.didCollectedGoals,
            didCollectedFocusZones: mainView.didCollectedFocusZones,
            didSaveProfile: mainView.didComplete,
            didClose: mainView.didClose
        ))
        
        output.route
            .drive(Binder(self) { base, route in
                base.route(route)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Public
extension ChangeFitnessGroupViewController {
    static func make(fitnessGroup: FitnessGroup) -> ChangeFitnessGroupViewController {
        let vc = ChangeFitnessGroupViewController()
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
}

// MARK: Private
private extension ChangeFitnessGroupViewController {
    func open(error: Error) -> Observable<Void> {
        Observable<Void>
            .create { [weak self] observe in
                guard let self = self else {
                    return Disposables.create()
                }
                
                let vc = TryAgainViewController.make(error: error) {
                    observe.onNext(())
                }
                self.present(vc, animated: true)
                
                return Disposables.create()
            }
    }
    
    func route(_ route: ChangeFitnessGroupViewModel.Route) {
        switch route {
        case .close:
            dismiss(animated: true)
        }
    }
}
