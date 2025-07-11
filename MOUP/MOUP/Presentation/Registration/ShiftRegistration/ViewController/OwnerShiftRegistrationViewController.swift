//
//  OwnerShiftRegistrationViewController.swift
//  Routory
//
//  Created by tlswo on 6/12/25.
//

import UIKit
import SnapKit
import RxSwift
import FirebaseAuth

final class OwnerShiftRegistrationViewController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var delegate: RegistrationVCDelegate?
    
    private var isEdit: Bool
        
    private let isRegisterMode: Bool
    
    private let eventId: String
    
    private let editWorkplaceId: String
    
    private let editRoutineIDs: [String]

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let headerSegment = UISegmentedControl(items: ["사장님", "알바생"]).then {
        $0.selectedSegmentIndex = 0
        $0.backgroundColor = UIColor.gray300

        $0.setTitleTextAttributes([
            .foregroundColor: UIColor.gray500,
            .font: UIFont.bodyMedium(16)
        ], for: .normal)

        $0.setTitleTextAttributes([
            .foregroundColor: UIColor.primary500,
            .font: UIFont.bodyMedium(16)
        ], for: .selected)
        
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.borderWidth = 1.0
    }

    private var registrationMode: ShiftRegistrationMode = .owner
    private let contentView: ShiftRegistrationContentView
    private var delegateHandler: ShiftRegistrationDelegateHandler?
    private var actionHandler: RegistrationActionHandler?
    private var keyboardHandler: KeyboardInsetHandler?

    fileprivate lazy var navigationBar = BaseNavigationBar(title: "근무 등록")
    private let disposeBag = DisposeBag()

    private let viewModel = WorkplaceListViewModel(
        workplaceUseCase: WorkplaceUseCase(
            repository: WorkplaceRepository(service: WorkplaceService())
        )
    )

    private let registrationViewModel = ShiftRegistrationViewModel(
        calendarUseCase: CalendarUseCase(
            repository: CalendarRepository(calendarService: CalendarService())
        )
    )

    private let submitTrigger = PublishSubject<(String, CalendarEvent)>()
    
    private let editViewModel = ShiftEditViewModel(
        calendarUseCase: CalendarUseCase(
            repository: CalendarRepository(calendarService: CalendarService())
        )
    )

    private let editTrigger = PublishSubject<(String, String, CalendarEvent)>()
    
    init(
        isRegisterMode: Bool,
        isEdit: Bool,
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
        self.isEdit = isEdit
        self.editWorkplaceId = editWorkplaceId
        self.editRoutineIDs = editRoutineIDs
        self.contentView = ShiftRegistrationContentView(
            isRead: isEdit,
            workPlaceTitle: workPlaceTitle,
            workerTitle: workerTitle,
            routineTitle: routineTitle,
            dateValue: dateValue,
            repeatValue: repeatValue,
            startTime: startTime,
            endTime: endTime,
            restTime: restTime,
            memoPlaceholder: memoPlaceholder,
            registerBtnTitle: isEdit ? "적용하기" : "등록하기"
        )
        self.eventId = eventId
        super.init(nibName: nil, bundle: nil)
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

        viewModel.fetchWorkplaces { [weak self] in
            guard let self else { return }

            self.setupUI()
            self.setupNavigationBar()
            self.layout()
            self.setupSegment()
            self.setupKeyboardHandler()
            self.bindViewModel()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParent {
            delegate?.registrationVCIsMovingFromParent(dateValue: contentView.getWorkDateView.getDateValue)
        }
    }

    private func bindViewModel() {
        let input = ShiftRegistrationViewModel.Input(submitTrigger: submitTrigger)
        let output = registrationViewModel.transform(input: input)

        output.submissionResult
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    print("근무 등록 성공")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("근무 등록 실패: \(error)")
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
                    print("근무 수정 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupKeyboardHandler() {
        keyboardHandler = KeyboardInsetHandler(
            scrollView: scrollView,
            containerView: view,
            targetView: contentView.memoBoxView
        )
        keyboardHandler?.startObserving()
    }

    private func setupSegment() {
        headerSegment.selectedSegmentIndex = 0
        headerSegment.addTarget(self, action: #selector(didChangeSegment(_:)), for: .valueChanged)
        didChangeSegment(headerSegment)
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

    private func setupUI() {
        view.backgroundColor = .white

        scrollView.keyboardDismissMode = .interactive
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.addArrangedSubview(headerSegment)
        stackView.addArrangedSubview(contentView)
        stackView.setCustomSpacing(24, after: headerSegment)

        contentView.simpleRowView.isHidden = true

        delegateHandler = ShiftRegistrationDelegateHandler(
            contentView: contentView,
            navigationController: navigationController,
            viewModel: viewModel
        )
        actionHandler = RegistrationActionHandler(
            contentView: contentView,
            navigationController: navigationController
        )

        contentView.simpleRowView.delegate = delegateHandler
        contentView.routineView.delegate = delegateHandler
        contentView.workDateView.delegate = delegateHandler
        contentView.workTimeView.delegate = delegateHandler
        contentView.workerSelectionView.delegate = delegateHandler

        if isEdit {
            contentView.registerButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
        } else {
            contentView.registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        }
        
        contentView.registerButton.addTarget(actionHandler, action: #selector(RegistrationActionHandler.buttonTouchDown(_:)), for: .touchDown)
        contentView.registerButton.addTarget(actionHandler, action: #selector(RegistrationActionHandler.buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
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

        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            $0.width.equalTo(scrollView.frameLayoutGuide).inset(16)
        }

        headerSegment.snp.makeConstraints {
            $0.height.equalTo(48)
        }
    }
    
    @objc private func didTapEdit() {
        let eventDate = contentView.workDateView.getdateRowData()
        let startTime = contentView.workTimeView.getstartRowData()
        let endTime = contentView.workTimeView.getendRowData()
        let breakTime = contentView.workTimeView.getrestRowData()
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
        
        switch registrationMode {
        case .owner:
            let workPlace = contentView.simpleRowView.getData()

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

            print("owner: ",editWorkplaceId, event, eventId)
            editTrigger.onNext((editWorkplaceId, eventId, event))


        case .employee:
            let workPlaceID = contentView.simpleRowView.getID()
            let workPlace = contentView.simpleRowView.getData()
            let workers = contentView.workerSelectionView.getSelectedWorkerData()
            let routineIDs = contentView.routineView.getSelectedRoutineIDs()
            
            workers.forEach { worker in
                let event = CalendarEvent(
                    title: workPlace,
                    eventDate: eventDate,
                    startTime: startTime,
                    endTime: endTime,
                    createdBy: worker.id,
                    year: dateComponents.year,
                    month: dateComponents.month,
                    day: dateComponents.day,
                    routineIds: routineIDs,
                    repeatDays: repeatDays,
                    memo: memo
                )
                
                print("employee: ",workPlaceID, event, eventId)
                editTrigger.onNext((workPlaceID, eventId, event))

            }
        }
    }
    
    @objc private func didTapRegister() {
        let workPlaceID = contentView.simpleRowView.getID()
        let eventDate = contentView.workDateView.getdateRowData()
        let startTime = contentView.workTimeView.getstartRowData()
        let endTime = contentView.workTimeView.getendRowData()
        let breakTime = contentView.workTimeView.getrestRowData()
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

        switch registrationMode {
        case .owner:
            let workPlace = contentView.simpleRowView.getData()
            let routineIDs = contentView.routineView.getSelectedRoutineIDs()

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


        case .employee:
            let workPlaceID = contentView.simpleRowView.getID()
            let workPlace = contentView.simpleRowView.getData()
            let workers = contentView.workerSelectionView.getSelectedWorkerData()
            let routineIDs = contentView.routineView.getSelectedRoutineIDs()
            
            workers.forEach { worker in
                let event = CalendarEvent(
                    title: workPlace,
                    eventDate: eventDate,
                    startTime: startTime,
                    endTime: endTime,
                    createdBy: worker.id,
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
    }

    @objc private func didChangeSegment(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            registrationMode = .owner
            contentView.simpleRowView.isHidden = false
            contentView.workerSelectionView.isHidden = true
            contentView.routineView.isHidden = false
        case 1:
            registrationMode = .employee
            contentView.simpleRowView.isHidden = false
            contentView.workerSelectionView.isHidden = false
            contentView.routineView.isHidden = true
        default:
            break
        }
    }
}
