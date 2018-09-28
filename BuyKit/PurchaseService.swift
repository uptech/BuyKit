import StoreKit

open class PurchaseService: NSObject {
    public static let shared = PurchaseService()
    private var _canMakePayments: Bool?
    private var restoreCompletedHandler: (() -> Void)?

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    public func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    @discardableResult
    public func canMakePayments() -> Bool {
        if let makePayments = _canMakePayments {
            return makePayments
        } else {
            let makePayments = SKPaymentQueue.canMakePayments()
            self._canMakePayments = makePayments
            return makePayments
        }
    }

    public func restorePurchases(completedHandler: (() -> Void)?) {
        self.restoreCompletedHandler = completedHandler
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension PurchaseService: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

        for transaction in transactions {
            print(" - transaction.transactionState: \(transaction.transactionState)")
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred: // when parental controls require parent to approve
                print("Deferred transaction")
                break
            case .purchasing:
                print("Purchasing transaction")
                break
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        ReceiptRepository.shared.recordPurchase(skProductId: transaction.payment.productIdentifier)

        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

        ReceiptRepository.shared.recordPurchase(skProductId: transaction.payment.productIdentifier)

        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {

            print("Transaction Error: \(localizedDescription)")
        }

        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.restoreCompletedHandler?()
    }
}

