import SwiftUI
import UIKit

/// Makes RegisterDomainSuggestionsViewController available to SwiftUI
final class DomainSuggestionViewControllerWrapper: UIViewControllerRepresentable {

    private let blog: Blog

    private weak var domainSuggestionViewController: RegisterDomainSuggestionsViewController?

    init(blog: Blog) {
        self.blog = blog
    }

    func makeUIViewController(context: Context) -> RegisterDomainSuggestionsViewController {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        let viewController = RegisterDomainSuggestionsViewController
                .instance(site: JetpackSiteRef(blog: blog)!, domainPurchasedCallback: { domain in
                    blogService.syncBlogAndAllMetadata(self.blog) { }
                    WPAnalytics.track(.domainCreditRedemptionSuccess)
                    self.presentDomainCreditRedemptionSuccess(domain: domain)
                })
        domainSuggestionViewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: RegisterDomainSuggestionsViewController, context: Context) { }

    private func presentDomainCreditRedemptionSuccess(domain: String) {
        guard let presentingController = domainSuggestionViewController else {
            return
        }
        let controller = DomainCreditRedemptionSuccessViewController(domain: domain, delegate: self)
        presentingController.present(controller, animated: true)
    }
}

/// Handles the action after the domain registration confirmation is dismissed - go back to Domains Dashboard
extension DomainSuggestionViewControllerWrapper: DomainCreditRedemptionSuccessViewControllerDelegate {

    func continueButtonPressed() {

        domainSuggestionViewController?.dismiss(animated: true) { [weak self] in
            if let popController = self?.domainSuggestionViewController?.navigationController?.viewControllers.first(where: {
                                                                                $0 is UIHostingController<DomainsDashboardView>
            }) ?? self?.domainSuggestionViewController?.navigationController?.topViewController {
                self?.domainSuggestionViewController?.navigationController?.popToViewController(popController, animated: true)
            }
        }
    }
}
