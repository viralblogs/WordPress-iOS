import Foundation
import WordPressShared

struct CustomCellMarginBehavior {
    private let fixedWidth = CGFloat(600)

    func correctedFrame(_ frame: CGRect, for cell: UITableViewCell) -> CGRect {
        var frame = frame
        guard let width = cell.superview?.frame.width,
            WPDeviceIdentification.isiPad(),
            width > fixedWidth else {
                return frame
        }
        let x = (width - fixedWidth) / 2
        // If origin.x is not equal to x we add the value.
        // This is a semi-fix / work around for an issue positioning cells on
        // iOS 8 when editing a table view and the delete button is visible.
        if x != frame.origin.x {
            frame.origin.x += x
        } else {
            frame.origin.x = x
        }
        frame.size.width = fixedWidth
        return frame
    }

    func cellDidLayoutSubviews(_ cell: UITableViewCell) {
        // Need to set the origin again on iPad (for margins)
        guard let width = cell.superview?.frame.width,
            WPDeviceIdentification.isiPad(),
            width > fixedWidth else {
                return
        }
        cell.frame.origin.x = (width - fixedWidth) / 2
    }
}
