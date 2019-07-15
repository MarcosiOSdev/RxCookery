//
//  ViewController.swift
//  RxCookery
//
//  Created by Marcos Felipe Souza on 12/07/19.
//  Copyright © 2019 Marcos Felipe Souza. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import RxGesture

import RealmSwift
import RxCocoa
import RxRealm
import RxSwift


class MyObject: Object {
    @objc dynamic var time: TimeInterval = Date().timeIntervalSinceReferenceDate
}

struct MortyModel {
    var image: UIImage
    var title: String
}

class ViewController: UIViewController {
    
    @IBOutlet weak var addDataButton: UIButton!
    @IBOutlet weak var deleteLastDataButton: UIButton!
    @IBOutlet weak var deleteAllDatasButton: UIButton!
    @IBOutlet weak var greenView: UIView!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var morties = Variable<[MortyModel]>([])
    var bag = DisposeBag()
    
    
    //CocoaAction == Action<Void, Void>
    let obsAction: CocoaAction = Action {
        print("obsAction")
        return Observable.empty()
    }
    
    //Sample as use Action
    let loginAction: Action<(String, String), Bool> = Action { credentials in
        let (login, password) = credentials
        // loginRequest returns an Observable<Bool>
        //return networkLayer.loginRequest(login, password)
        return Observable<Bool>.of(true)
    }
    
    func setupImage() {
        
        self.morties.value = [
            MortyModel(image: UIImage(named: "cry_morty")!, title: "Morty crying"),
            MortyModel(image: UIImage(named: "muscular_rick")!, title: "Rick big cientist"),
            MortyModel(image: UIImage(named: "protected_morty")!, title: "Morty is a shield")
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindToTableView()
        setupImage()
        
        self.actionButton.rx.action = self.obsAction
        setupGesture()
        setupRealm()
    }
    
    func setupRealm() {
        let realm = try! Realm()
        let result = realm.objects(MyObject.self)
        
        let listMyObjects = BehaviorSubject<[MyObject]>(value: [])
        
        Observable.collection(from: result, synchronousStart: false)
            .subscribe(onNext: { items in
                print("Query returned \(items.count) items")
        }).disposed(by: bag)
        
        Observable.changeset(from: result)
            .subscribe(onNext: { results, changes in
                
                if let changes = changes {
                    // it's an update
                    print("deleted: \(changes.deleted)")
                    print("inserted: \(changes.inserted)")
                    print("updated: \(changes.updated)")
                }
                print(results)
                listMyObjects.onNext(results.toArray())
        }).disposed(by: bag)
        
        
        
        
        //Cenario onde deve ir sempre na API para atualizar as mensagens
//        Observable
//            .timer(0, period: 60, scheduler: MainScheduler.instance)
//            .flatMap { _ -> Observable<[Message]> in
//                let messages = realm.objects(Messages.self).sorted(byProperty:
//                    "dateReceived")
//                if let lastMessage = messages.last {
//                    return MailAPI.newMessagesSince(lastMessage.dateReceived)
//                }
//                return MailAPI.newMessagesSince(Date.distantPast)
//            }
//            .subscribe(realm.rx.add())
//            .addDisposableTo(disposeBag)
        
        let addValues = PublishSubject<MyObject>()
        
        addDataButton.rx.tap.subscribe(onNext: { _ in
            addValues.onNext(MyObject())
        }).disposed(by: bag)
    
        
        addValues
            .subscribe(realm.rx.add())
            .disposed(by: bag)
        
        self.deleteAllDatasButton.rx.tap.subscribe(onNext: { _ in
            listMyObjects.subscribe(realm.rx.delete()).dispose()
        }).disposed(by: bag)
        
        self.deleteLastDataButton.rx
            .tap
            .subscribe(onNext: { _ in
                listMyObjects
                    .filter{ $0.count > 0 }
                    .map{ $0.last! }
                    .subscribe(realm.rx.delete())
                    .dispose()
        }).disposed(by: bag)
        
    }
    
    func setupGesture() {
        self.greenView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                print("view is tapped")
            }).disposed(by: bag)
        
        //multiple gesture
        self.greenView.rx
            .anyGesture(.tap(), .longPress(), .pan())
            .when(.recognized)
            .subscribe(onNext: { gesture in
                
                if let _ = gesture as? UITapGestureRecognizer {
                    print("TAP gesture")
                }
                if let _ = gesture as? UILongPressGestureRecognizer {
                    print("Long Press gesture")
                }
                if let _ = gesture as? UIPanGestureRecognizer {
                    print("PAN gesture")
                }
                
            }).disposed(by: bag)
        
        self.greenView.rx
            .screenEdgePanGesture(edges: [.top, .bottom])
            .when(.recognized)
            .subscribe(onNext: { recognizer in
                // gesture was recognized
                print("Edge Gesture")
            }).disposed(by: bag)
        
        greenView.rx.tapGesture()
            .when(.recognized)
            .asLocation(in: .window)
            .subscribe(onNext: { location in
                // you now directly get the tap location in the window
                print("tap on \(location)")
            }).disposed(by: bag)
        
        greenView.rx.panGesture()
            .asTranslation(in: .superview)
            .subscribe(onNext: { translation, velocity in
                print("Translation=\(translation), velocity=\(velocity)")
//                self.greenView.frame = CGRect(x: translation.x,
//                                              y: translation.y,
//                                              width: self.greenView.frame.width,
//                                              height: self.greenView.frame.height)
            }).disposed(by: bag)
        
        greenView.rx.rotationGesture()
            .asRotation()
            .subscribe(onNext: { rotation, velocity in
                print("Rotation=\(rotation), velocity=\(velocity)")
            }).disposed(by: bag)
        
        //TRansformGesture are pan/pinch/rotate
        view.rx.transformGestures()
            .asTransform()
            .subscribe({ transform in
                self.view.transform = transform.element!.transform
        }).disposed(by: bag)
        
        let panGesture = view.rx.panGesture()
            .share(replay: 1)
        
        panGesture
            .when(.changed)
            .asTranslation()
            .subscribe(onNext: { [unowned self] translation, _ in
                self.greenView.transform = CGAffineTransform(translationX: translation.x,
                                                   y: translation.y)
            }).disposed(by: bag)
        
        panGesture
            .when(.ended)
            .subscribe(onNext: { _ in
                print("Done panning")
            }).disposed(by: bag)
        
    }
    
    func bindToTableView() {
        self.morties.asObservable().bind(to: tableView.rx.items) {
            (tableView: UITableView, index: Int, element: MortyModel) in
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell.textLabel?.text = element.title
            cell.imageView?.image = element.image
            return cell
        }.disposed(by: bag)
        
        
        self.tableView.rx
            .modelSelected(MortyModel.self)
            .subscribe(onNext: { element in
                print("\(element) was selected ")
                
        }).disposed(by: bag)
//        • modelSelected(), modelDeselected(), itemSelected(), itemDeselected() fire on item selection
//        • accessoryButtonTapped() fire on accessory button tap
//        • itemInserted(), itemDeleted(), itemMoved() fire on events callbacks in table edit mode
//        • willDisplayCell(), didEndDisplayingCell()
        
        
        //Caso queira pegar um action dentro da cell , como um botao :
        
//        observable.bindTo(tableView.rx.items) {
//            (tableView: UITableView, index: Int, element: MyModel) in
//            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell",
//                                                     for: indexPath)
//            cell.button.rx.action = CocoaAction { [weak self] in
//                // do something specific to this cell here
//                return .empty()
//            }
//            return cell }
//            .addDisposableTo(disposeBag)
        
    }
    
    
}

