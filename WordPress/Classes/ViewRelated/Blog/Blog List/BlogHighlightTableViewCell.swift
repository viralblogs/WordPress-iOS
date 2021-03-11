import UIKit
import Combine

@objc class BlogHighlightTableViewCell: UITableViewCell {

    var cancellable: Cancellable?

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    var highlights: [BlogHighlight] = [] {
        didSet {
            guard oldValue != highlights else {
                return
            }

            collectionView.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()

        // Configure collection view
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(BlogHighlightCollectionViewCell.defaultNib,
                                forCellWithReuseIdentifier: BlogHighlightCollectionViewCell.defaultReuseID)

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }

    func configure(blog: Blog) {
        let displayURL = blog.displayURL as String? ?? ""
        if let name = blog.settings?.name?.nonEmptyString() {
            titleLabel.text = name
            subtitleLabel.text = displayURL
        } else {
            titleLabel.text = displayURL
            subtitleLabel.text = nil
        }

        iconImageView.downloadSiteIcon(for: blog)
    }

    private func applyStyles() {
        titleLabel.textColor = .text
        titleLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)

        subtitleLabel.textColor = .textSubtle
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)

        collectionView.backgroundColor = .listForeground
    }

    private struct Constants {
        static let reuseIdentifier = BlogHighlightCollectionViewCell.defaultReuseID
    }
}

extension BlogHighlightTableViewCell: NibReusable {

    @objc static var defaultReuseID: String {
        return String(describing: self)
    }

    @objc static var defaultNibName: String {
        return String(describing: self)
    }

    @objc static var defaultBundle: Bundle {
        return Bundle.main
    }

    @objc static var defaultNib: UINib {
        return UINib(nibName: defaultNibName, bundle: defaultBundle)
    }

}

// MARK: - Collection View: Datasource & Delegate

extension BlogHighlightTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier,
                                                            for: indexPath) as? BlogHighlightCollectionViewCell else {
            fatalError("Expected a ReaderInterestsCollectionViewCell for identifier: \(Constants.reuseIdentifier)")
        }

        let icon = highlights[indexPath.row].icon
        cell.imageView.image = icon

        let title = highlights[indexPath.row].title
        cell.label.text = title
        cell.label.accessibilityTraits = .button

        cell.label.font = WPStyleGuide.fontForTextStyle(.footnote)
        cell.label.textColor = .text
        cell.layer.backgroundColor = UIColor.listBackground.cgColor

        return cell
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            collectionView.reloadData()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return highlights.count
    }
}
