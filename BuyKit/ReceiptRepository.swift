import Foundation

/**
 Manage storage and retreival of purchase records
 */
open class ReceiptRepository {
    /**
     Primary shared singleton interface for the receipt repository
     */
    public static let shared = ReceiptRepository()

    private let userDefaultsPurchasedProductIdsKey = "purchasedSkProductIds"
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []

    private init() {}

    /**
     Load the in memory cache of purchases from local storage

     This is generally performed at application launch in the AppDelegate.
     Note: If no local storage records are found it initializes the in memory
     cache of purchases to an empty set.
     */
    public func load() {
        if let productIdStrings = UserDefaults.standard.stringArray(forKey: userDefaultsPurchasedProductIdsKey) {
            purchasedProductIdentifiers = Set<ProductIdentifier>(productIdStrings)
        } else {
            purchasedProductIdentifiers = Set<ProductIdentifier>([])
        }
    }

    /**
     Check if a product has already been purchased

     - parameter skProductId: The StoreKit product identifier you want to check if was purchased

     - returns: Boolean value indicating if the product was already purchased
     */
    public func alreadyPurchased(skProductId: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(skProductId)
    }

    /**
     Record that a product was purchased

     - parameter skProductId: The StoreKit product identifier of the product that was purchased
     */
    public func recordPurchase(skProductId: ProductIdentifier) {
        purchasedProductIdentifiers.insert(skProductId)
        UserDefaults.standard.set(Array(purchasedProductIdentifiers), forKey: userDefaultsPurchasedProductIdsKey)
    }
}
