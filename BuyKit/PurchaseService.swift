import StoreKit

open class PurchaseService: NSObject {
    public static let shared = PurchaseService()
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    public func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension PurchaseService: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                break
            case .failed:
                break
            case .restored:
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        ReceiptRepository.shared.recordPurchase(skProductId: transaction.payment.productIdentifier)

        // TODO: Notify observers
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

        print("restore... \(productIdentifier)")
        ReceiptRepository.shared.recordPurchase(skProductId: transaction.payment.productIdentifier)

        // TODO: Notify observers
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")

        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {

            print("Transaction Error: \(localizedDescription)")
        }

        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

