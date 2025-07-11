//
//  WorkShiftRegistrationViewController.swift
//  Routory
//
//  Created by tlswo on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import FirebaseAuth

final class WorkShiftRegistrationViewController: UIViewController, UIGestureRecognizerDelegate {

    weak var delegate: RegistrationVCDelegate?
    
    private let isRegisterMode: Bool
    
    private var isEdit: Bool
    
    private let eventId: String
    
    private let editWorkplaceId: String
    
    private let editRoutineIDs: [String]

    private let scrollView = UIScrollView()
    private let contentView: ShiftRegistrationContentView
    private var delegateHandler: ShiftRegistrationDelegateHandler?
    private var actionHandler: RegistrationActionHandler?
    private var keyboardHandler: KeyboardInsetHandler?

    fileprivate lazy var navigationBar = BaseNavigationBar(title: "근무 등록")
    private let disposeBag = DisposeBag()

    private let workplaceListViewModel = WorkplaceListViewModel(
        workplaceUseCase: WorkplaceUseCase(
            repository: WorkplaceRepository(service: WorkplaceService())
        )
    )

    private let registrationViewModel = ShiftRegistrationViewModel(calendarUseCase: CalendarUseCase(repository: CalendarRepository(calendarService: CalendarService())))

    private let submitTrigger = PublishSubject<(String, CalendarEvent)>()
    
    private let editViewModel = ShiftEditViewModel(
        calendarUseCase: CalendarUseCase(
            repository: CalendarRepository(calendarService: CalendarService())
        )
    )

    private let editTrigger = PublishSubject<(String, String, CalendarEvent)>()
    
    init(
        isRegisterMode: Bool,
        isRead: Bool,
        eventId: String,
        editWorkplaceId: String,
        workPlaceTitle: String,
        workerTitle: String,
        routineTitle: String,
        editRoutineIDs: [String],
        dateValue: String,
        repeatValue: String,
        startTime: String,
        endTime: String,
        restTime: String,
        memoPlaceholder: String
    ) {
        self.isRegisterMode = isRegisterMode
        self.isEdit = isRead
        self.eventId = eventId
        self.editWorkplaceId = editWorkplaceId
        self.editRoutineIDs = editRoutineIDs
        self.contentView = ShiftRegistrationContentView(
            isRead: isRead,
            workPlaceTitle: workPlaceTitle,
            workerTitle: workerTitle,
            routineTitle: routineTitle,
            dateValue: dateValue,
            repeatValue: repeatValue,
            startTime: startTime,
            endTime: endTime,
            restTime: restTime,
            memoPlaceholder: memoPlaceholder,
            registerBtnTitle: isRead ? "적용하기" : "등록하기"
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        workplaceListViewModel.fetchWorkplaces { [weak self] in
            guard let self else { return }

            self.setupUI()
            self.setupNavigationBar()
            self.layout()
            self.bindViewModel()

            self.keyboardHandler = KeyboardInsetHandler(
                scrollView: self.scrollView,
                containerView: self.view,
                targetView: self.contentView.memoBoxView
            )
            self.keyboardHandler?.startObserving()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent {
            delegate?.registrationVCIsMovingFromParent(dateValue: contentView.getWorkDateView.getDateValue)
        }
    }
    
    private func updateRightBarButtonTitle() {
        if isRegisterMode {
            navigationBar.configureRightButton(icon: nil, title: nil, isHidden: true)
            return
        }
        
        let title = isEdit ? "수정" : ""
        navigationBar.configureRightButton(icon: nil, title: title)
    }
    
    private func toggleReadMode() {
        isEdit.toggle()
        contentView.setReadMode(isEdit)
        updateRightBarButtonTitle()
    }

    private func bindViewModel() {
        let input = ShiftRegistrationViewModel.Input(submitTrigger: submitTrigger)
        let output = registrationViewModel.transform(input: input)

        output.submissionResult
            .subscribe(onNext: { (result: Result<Void, Error>) in
                switch result {
                case .success:
                    print("근무 등록 성공")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("근무 등록 실패:", error)
                }
            })
            .disposed(by: disposeBag)
        
        let editInput = ShiftEditViewModel.Input(submitTrigger: editTrigger)
        let editOutput = editViewModel.transform(input: editInput)

        editOutput.submissionResult
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    print("근무 수정 성공")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("근무 수정 실패:", error)
                }
            })
            .disposed(by: disposeBag)
    }

    deinit {
        keyboardHandler?.stopObserving()
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        delegateHandler = ShiftRegistrationDelegateHandler(
            contentView: contentView,
            navigationController: navigationController,
            viewModel: workplaceListViewModel
        )
        actionHandler = RegistrationActionHandler(
            contentView: contentView,
            navigationController: navigationController
        )

        contentView.simpleRowView.delegate = delegateHandler
        contentView.routineView.delegate = delegateHandler
        contentView.workDateView.delegate = delegateHandler
        contentView.workTimeView.delegate = delegateHandler

        contentView.workerSelectionView.isHidden = true

        if isEdit {
            contentView.registerButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
        } else {
            contentView.registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        }
        contentView.registerButton.addTarget(actionHandler, action: #selector(RegistrationActionHandler.buttonTouchDown(_:)), for: .touchDown)
        contentView.registerButton.addTarget(actionHandler, action: #selector(RegistrationActionHandler.buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    private func setupNavigationBar() {
        navigationBar.rx.backBtnTapped
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        navigationBar.rx.rightBtnTapped
            .subscribe(onNext: { [weak self] in
                self?.toggleReadMode()
                self?.navigationBar.configureRightButton(icon: nil, title: nil, isHidden: true)
            })
            .disposed(by: disposeBag)
        
        updateRightBarButtonTitle()
    }

    private func layout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.height.equalTo(50)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            $0.width.equalTo(scrollView.frameLayoutGuide).inset(16)
        }
    }
    
    @objc func didTapEdit() {
        let workPlace = contentView.simpleRowView.getData()
        let eventDate = contentView.workDateView.getdateRowData()
        let startTime = contentView.workTimeView.getstartRowData()
        let endTime = contentView.workTimeView.getendRowData()
        let repeatDays = contentView.workDateView.getRepeatData()
        let memo = contentView.memoBoxView.getData()

        guard let dateComponents = parseDateComponents(from: eventDate) else {
            print("날짜 파싱 실패: \(eventDate)")
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
              print("유저 ID를 찾을 수 없습니다.")
              return
        }

        let event = CalendarEvent(
            title: workPlace,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            createdBy: userId,
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            routineIds: editRoutineIDs,
            repeatDays: repeatDays,
            memo: memo
        )
        
        editTrigger.onNext((editWorkplaceId, eventId, event))
    }

    @objc func didTapRegister() {
        let workPlaceID = contentView.simpleRowView.getID()
        let workPlace = contentView.simpleRowView.getData()
        let eventDate = contentView.workDateView.getdateRowData()
        let startTime = contentView.workTimeView.getstartRowData()
        let endTime = contentView.workTimeView.getendRowData()
        let routineIDs = contentView.routineView.getSelectedRoutineIDs()
        let repeatDays = contentView.workDateView.getRepeatData()
        let memo = contentView.memoBoxView.getData()

        guard let dateComponents = parseDateComponents(from: eventDate) else {
            print("날짜 파싱 실패: \(eventDate)")
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
              print("유저 ID를 찾을 수 없습니다.")
              return
        }

        let event = CalendarEvent(
            title: workPlace,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            createdBy: userId,
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            routineIds: routineIDs,
            repeatDays: repeatDays,
            memo: memo
        )

        submitTrigger.onNext((workPlaceID, event))
    }
}
