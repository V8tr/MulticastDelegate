//
//  AppDelegate.swift
//  MulticastDelegate
//
//  Created by Vadym Bulavin on 5/15/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

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

let logger = Logger()
let analyticsEngine = AnalyticsEngine()
let searchResults = SearchResultsViewController(search)

let searchBarMulticastDelegate = SearchBarMulticastDelegate(delegates: [logger, analyticsEngine, searchResults])
search.searchBar.delegate = searchBarMulticastDelegate
