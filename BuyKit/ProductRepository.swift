import StoreKit

public typealias ProductIdentifier = String

/**
 Protocol describing interface of an observer of the product repository
 */
public protocol ProductRepositoryObserver {
    func updated(products: [SKProduct])
    func loadFailed(error: Error)
}

/**
 Wrapper around StoreKit SKProductSRequests that manages in memory cache

 This is intended to be your primary interface when wanting to interact with
 StoreKit products that are defined in App Connect.
 */
open class ProductRepository: NSObject {
    /**
     Primary shared singleton interface for the product repository
     */
    static let shared = ProductRepository()

    private var productsRequest: SKProductsRequest?
    private var products: [SKProduct] = []
    private var observers: [WeakWrapper<ProductRepositoryObserver>] = []

    private override init() {
        super.init()
    }

    /**
     Load the product repository with valid products

     This method takes in a set of potential product ids and validates them
     against Apple's App Connect service. In the case of success the in memory
     cache of valid products is updated and the observers are notified that
     the repository has been `updated(:)`. In the case of failure the observers
     are notified that there was a `loadFailure(:)`.

     Note: The set of potential product ids should come from either a hard
     coded list in your app bundle if your products are all included in the
     app bundle, or from a JSON request to a server where you post the
     potential products so that you can update the available products without
     having to make a new release of the app.

     - parameter productIds: Set of potential product ids
     */
    public func load(productIds: Set<ProductIdentifier>) {
        productsRequest?.cancel() // if called again before completing previous request, cancel it

        productsRequest = SKProductsRequest(productIdentifiers: productIds)
        productsRequest!.delegate = self
        productsRequest!.start()
    }

    /**
     Get all the valid products the Product Repository currently knows about

     This returns all of the StoreKit products that the product repository
     currently has in it's in memory cache. So, if a `load` hasn't completed
     successfully you may be missing some products that you would normally
     expect

     - returns: An array of StoreKit Products
     */
    public func all() -> [SKProduct] {
        return products
    }

    /**
     Fetch a specific valid product given it's product id

     This attempts to fetch the StoreKit product matching the given product
     identifier from the the ProductRepositorie's in memory cache. So, if
     a successful load hasn't completed, it may not find the product you
     are looking for.

     - parameter productId: Identifier of the product you want to fetch

     - returns: If found in the in memory cache it returns the matching StoreKit product. Otherwise it returns nil
     */
    public func fetch(_ productId: ProductIdentifier) -> SKProduct? {
        for product in products {
            if product.productIdentifier == productId {
                return product
            }
        }

        return nil
    }

    /**
     Register an object as an observer of the product repository
     */
    public func addObserver(_ observer: ProductRepositoryObserver) {
        observers.append(WeakWrapper(observer))
    }
}

extension ProductRepository: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("DREW: Loaded list of products...")
        products = response.products

        self.observers.forEach({ $0.value?.updated(products: products) })
        clearRequest()

        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.localizedDescription) \(p.price.floatValue)")
        }
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("DREW: Failed to load list of products.")
        print("Error: \(error.localizedDescription)")

        observers.forEach({ $0.value?.loadFailed(error: error) })
        clearRequest()
    }

    private func clearRequest() {
        productsRequest = nil
    }
}

