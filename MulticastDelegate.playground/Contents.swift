import UIKit

class MulticastDelegate<T> {
    private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }

    func remove(_ delegateToRemove: T) {
        for delegate in delegates.allObjects.reversed() {
            if delegate === delegateToRemove as AnyObject {
                delegates.remove(delegate)
            }
        }
    }

    func invoke(_ invocation: (T) -> Void) {
        for delegate in delegates.allObjects.reversed() {
            invocation(delegate as! T)
        }
    }
}

protocol MyClassDelegate: class {
    func doFoo()
}

class MyClassMulticastDelegate: MulticastDelegate<MyClassDelegate>, MyClassDelegate {
    func doFoo() {
        invoke { $0.doFoo() }
    }
}

class MyClass {
    weak var delegate: MyClassDelegate?

    func foo() {
        delegate?.doFoo()
    }
}

class Logger: NSObject {}

extension Logger: MyClassDelegate {
    func doFoo() {
        print("Foo called")
    }
}

class AnalyticsEngine: NSObject {}

extension AnalyticsEngine: MyClassDelegate {
    func doFoo() {
        print("Track foo event")
    }
}

let logger = Logger()
let analyticsEngine = AnalyticsEngine()

let delegate = MyClassMulticastDelegate()
delegate.add(logger)
delegate.add(analyticsEngine)

let myClass = MyClass()
myClass.delegate = delegate

myClass.foo()

class SearchResultsViewController: UIViewController, UISearchBarDelegate {
    private unowned var svc: SearchViewController

    init(_ svc: SearchViewController) {
        self.svc = svc
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Show over `SearchViewController`
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Hide from `SearchViewController`
    }
}

extension AnalyticsEngine: UISearchBarDelegate {}
extension Logger: UISearchBarDelegate {}

final class SearchBarMulticastDelegate: NSObject, UISearchBarDelegate {

    private let multicast = MulticastDelegate<UISearchBarDelegate>()

    init(delegates: [UISearchBarDelegate]) {
        super.init()
        delegates.forEach(multicast.add)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        multicast.invoke { $0.searchBarSearchButtonClicked?(searchBar) }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        multicast.invoke { $0.searchBarCancelButtonClicked?(searchBar) }
    }
}

class SearchViewController: UIViewController {
    let searchBar = UISearchBar()
}

let search = SearchViewController()

let searchResults = SearchResultsViewController(search)

let searchBarMulticastDelegate = SearchBarMulticastDelegate(delegates: [logger, analyticsEngine, searchResults])
search.searchBar.delegate = searchBarMulticastDelegate
