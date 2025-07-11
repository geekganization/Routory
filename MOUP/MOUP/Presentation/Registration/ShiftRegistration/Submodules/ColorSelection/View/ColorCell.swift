//
//  ColorCell.swift
//  Routory
//
//  Created by tlswo on 6/10/25.
//

import UIKit
import SnapKit
import Then

final class ColorCell: UITableViewCell {

    // MARK: - UI Components

    private let colorDot = UIView().then {
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
    }

    private let nameLabel = UILabel().then {
        $0.font = .fieldsRegular(16)
        $0.textColor = .gray900
    }

    private let checkImage = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark")
        $0.tintColor = .primary500
        $0.isHidden = true
    }

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        selectionStyle = .none

        contentView.addSubview(colorDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkImage)

        colorDot.snp.makeConstraints {
            $0.left.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(12)
        }

        nameLabel.snp.makeConstraints {
            $0.left.equalTo(colorDot.snp.right).offset(12)
            $0.centerY.equalToSuperview()
        }

        checkImage.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }

    // MARK: - Configuration

    func configure(name: String, color: UIColor, isSelected: Bool) {
        nameLabel.text = name
        colorDot.backgroundColor = color
        checkImage.isHidden = !isSelected
    }
}
