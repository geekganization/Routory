//
//  ColorSelectionViewController.swift
//  Routory
//
//  Created by tlswo on 6/10/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

// MARK: - Model

struct LabelColor {
    let name: String
    let color: UIColor
}

// MARK: - ViewController

final class ColorSelectionViewController: UIViewController,UIGestureRecognizerDelegate {

    // MARK: - Properties

    private let colors: [LabelColor] = [
        LabelColor(name: "빨간색", color: .systemRed),
        LabelColor(name: "주황색", color: .systemOrange),
        LabelColor(name: "노란색", color: .systemYellow),
        LabelColor(name: "초록색", color: .systemGreen),
        LabelColor(name: "파란색", color: .systemBlue),
        LabelColor(name: "보라색", color: .systemPurple),
        LabelColor(name: "남색", color: .systemIndigo)
    ]
    
    // *1
    fileprivate lazy var navigationBar = BaseNavigationBar(title: "색상 선택") //*2
    let disposeBag = DisposeBag()

    private var selectedIndex: Int = 0
    var onSelect: ((LabelColor) -> Void)?

    // MARK: - UI Components

    private let tableView = UITableView().then {
        $0.register(ColorCell.self, forCellReuseIdentifier: "ColorCell")
        $0.rowHeight = 48
        $0.tableFooterView = UIView()
    }

    private let applyButton = UIButton(type: .system).then {
        $0.setTitle("적용하기", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .buttonSemibold(18)
        $0.backgroundColor = .primary500
        $0.layer.cornerRadius = 12
    }

    // MARK: - Lifecycle
    
    //*3
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        //*4
        setupNavigationBar()
        layout()
    }

    // MARK: - Setup
    
    //*5
    private func setupNavigationBar() {
        navigationBar.rx.backBtnTapped
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func setup() {
        view.backgroundColor = .white
        //*6
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(applyButton)

        tableView.dataSource = self
        tableView.delegate = self

        applyButton.addTarget(self, action: #selector(didTapApply), for: .touchUpInside)
    }

    // MARK: - Layout

    private func layout() {
        //*7
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints {
            //*8
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        applyButton.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            $0.height.equalTo(52)
        }
    }

    // MARK: - Actions

    @objc private func didTapApply() {
        let selectedColor = colors[selectedIndex]
        onSelect?(selectedColor)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ColorSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath) as? ColorCell else {
            return UITableViewCell()
        }

        let color = colors[indexPath.row]
        cell.configure(name: color.name, color: color.color, isSelected: indexPath.row == selectedIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}
