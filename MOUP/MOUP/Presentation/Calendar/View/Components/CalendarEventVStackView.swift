//
//  CalendarEventVStackView.swift
//  Routory
//
//  Created by 서동환 on 6/13/25.
//

import UIKit

import SnapKit
import Then

final class CalendarEventVStackView: UIStackView {
    
    // MARK: - UI Components
    
    private let workHourOrNameLabel = UILabel().then {
        $0.font = .bodyMedium(12)
        $0.textAlignment = .left
    }
    
    private let dailyWageLabel = UILabel().then {
        $0.font = .bodyMedium(12)
        $0.textAlignment = .left
    }
    
    // MARK: - Getter
    
    var getDailyWageLabel: UILabel { dailyWageLabel }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    @available(*, unavailable, message: "storyboard is not supported.")
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    // MARK: - Methods
    
    func update(workHour: Double, workerName: String, wageType: String?, dailyWage: Int, calendarMode: CalendarMode, color: LabelColorString) {
        let workHourStr = String(format: "%.1f", workHour)
        if calendarMode == .shared {
            workHourOrNameLabel.text = workerName
        } else if workHourStr.last == "0" {
            workHourOrNameLabel.text = "\(workHourStr.dropLast(2))시간"
        } else {
            workHourOrNameLabel.text = "\(workHourStr)시간"
        }
        
        if calendarMode == .shared {
            dailyWageLabel.isHidden = true
        } else {
            if wageType == "시급" {
                // 시급
                dailyWageLabel.text = NumberFormatter.decimalFormatter.string(for: Int(dailyWage))
                dailyWageLabel.isHidden = false
            } else if wageType == "고정" {
                // 고정급
                dailyWageLabel.text = "고정급"
                dailyWageLabel.isHidden = false
            } else {
                // 사장님 개인 캘린더
                dailyWageLabel.text = "사장"
                dailyWageLabel.isHidden = true
            }
        }
        
        self.backgroundColor = color.backgroundColor
        workHourOrNameLabel.textColor = color.textColor
        dailyWageLabel.textColor = color.textColor
    }
}

// MARK: - UI Methods

private extension CalendarEventVStackView {
    func configure() {
        setHierarchy()
        setStyles()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addArrangedSubviews(workHourOrNameLabel,
                                 dailyWageLabel)
    }
    
    func setStyles() {
        self.axis = .vertical
        self.spacing = 0
        self.layoutMargins = .init(top: 0, left: 2, bottom: 0, right: 0)
        self.isLayoutMarginsRelativeArrangement = true
        self.layer.cornerRadius = 4
    }
    
    func setConstraints() {
        workHourOrNameLabel.snp.makeConstraints {
            $0.height.equalTo(17)
        }
        
        dailyWageLabel.snp.makeConstraints {
            $0.height.equalTo(17)
        }
    }
}
