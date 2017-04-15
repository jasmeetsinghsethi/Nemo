//
//  WebController.swift
//  Nemo
//
//  Created by Dushyant Bansal on 08/07/16.
//  Copyright © 2016 Dushyant Bansal. All rights reserved.
//

import UIKit

class NemoWebView: UIWebView {
}

protocol SearchResultsDelegate: class {
  func didSelectURL(url: NSURL)
}

class WebViewController: UIViewController, UITextFieldDelegate, UIWebViewDelegate, UIGestureRecognizerDelegate, SearchResultsDelegate, UISearchControllerDelegate, UISearchBarDelegate, UIScrollViewDelegate {

  var currentOffset: CGFloat = 0.0
  @IBOutlet weak var searchView: UIView!
//  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var webView: NemoWebView!
  weak var delegate: MainVCWebDelegate?
  
  @IBOutlet weak var searchViewHeightConstraint: NSLayoutConstraint!
  var searchController: UISearchController!
  var url: NSURL?
  
  func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
    return true;
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    webView.delegate = self
    webView.scrollView.scrollsToTop = true
    webView.scrollView.delegate = self
//    textField.delegate = self
    
    let hideKeyboardGesture = UIGestureRecognizer()
    hideKeyboardGesture.delegate = self
    webView.addGestureRecognizer(hideKeyboardGesture)
    
    let sb = UIStoryboard(name: "Main", bundle: nil)
    let srController = sb.instantiateViewControllerWithIdentifier("URLSearchResultsController") as! URLSearchResultsController
    srController.delegate = self
    searchController = UISearchController(searchResultsController: srController)
    searchController.searchBar.frame = searchView.bounds
    searchController.searchResultsUpdater = srController
    searchController.delegate = self
    searchController.searchBar.delegate = self
    
//    searchView.layoutMargins = UIEdgeInsetsZero
    searchView.addSubview(searchController.searchBar)
//    let views = ["searchBar": searchController.searchBar]
//    let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[searchBar]-|", options: .AlignAllCenterX, metrics: nil, views: views)
//    let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[searchBar]-|", options: .AlignAllCenterY, metrics: nil, views: views)
//    searchView.addConstraints(hConstraints)
//    searchView.addConstraints(vConstraints)
    searchController.searchBar.autoresizingMask = UIViewAutoresizing.FlexibleWidth
//    searchController.searchBar.translatesAutoresizingMaskIntoConstraints = true
    
    searchController.searchBar.returnKeyType = UIReturnKeyType.Go
    searchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.None
    searchView.bringSubviewToFront(searchController.searchBar)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    searchController.searchBar.subviews[0].subviews[0].frame = searchView.bounds
  }
  
  //MARK: SearchControllerDelegate
  func didDismissSearchController(searchController: UISearchController) {
    searchController.searchBar.text = webView.request?.URL?.absoluteString
  }
  
  // MARK: SearchResultsDelegate
  func didSelectURL(url: NSURL) {
    searchController.searchBar.text = url.absoluteString
    self.dismissViewControllerAnimated(true, completion: nil)
    webView.loadRequest(NSURLRequest(URL: url))
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//    textField.resignFirstResponder()
    return false
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    if let text = searchController.searchBar.text where text != "" {
      return
    }
    
    if let url = self.url {
      webView.loadRequest(NSURLRequest(URL: url))
      searchController.searchBar.text = url.absoluteString
    } else {
      searchController.searchBar.becomeFirstResponder()
    }
  }
  
  func reloadPage() {
    webView.reload()
  }
  
  // MARK: - UIWebViewDelegate
  func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    if let string:NSString = request.URL?.absoluteString where string.hasPrefix("newtab:") {
      if let url = NSURL(string: string.substringFromIndex(7)) {
        self.delegate?.webVC(self, shouldOpenNewTabForURL: url)
        return false
      }
    }
    return true
  }
  

  func webViewDidFinishLoad(webView: UIWebView) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    
    if let url = webView.request?.URL {
      WebHistory.defaultHistory.addURL(url)
      searchController.searchBar.text = url.absoluteString
    }
    // JS Injection hack to solve the target="_blank" issue and open a real browser in such case.
    let JSInjection = "javascript: var allLinks = document.getElementsByTagName('a'); if (allLinks) {var i;for (i=0; i<allLinks.length; i++) {var link = allLinks[i];var target = link.getAttribute('target'); if (target && target == '_blank') {link.setAttribute('target','_self');link.href = 'newtab:'+link.href;}}}"
    webView.stringByEvaluatingJavaScriptFromString(JSInjection)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let host = webView.request?.URL?.host else {
        return
      }
      let urlString = "http://\(host)/favicon.ico"
      let ur = NSURL(string: urlString)!
      if let data = NSData(contentsOfURL: ur),
        image = UIImage(data: data) {
          print(ur)
          self.delegate?.webVC(self, faviconDidLoad: image)
      }
    }
  }
  
  func webViewDidStartLoad(webView: UIWebView) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
  }
  
  //MARK: textField Delegate
  
//  func textFieldDidBeginEditing(textField: UITextField) {
//    if textField.text != "" {
//      textField.selectAll(nil)
//    }
//  }
//  
//  func textFieldShouldReturn(textField: UITextField) -> Bool {
//    return true
//  }
  
  // MARK: search bar delegate
  func searchBarCancelButtonClicked(searchBar: UISearchBar) {
  }
  
  func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
    if let textField = searchBar.valueForKey("_searchField") as? UITextField {
      textField.selectAll(nil)
    }
  }
  
  func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    dismissViewControllerAnimated(true, completion: nil)
    guard let text = searchBar.text else {
      return
    }
    
    let str = text.hasPrefix("http") ? text : "http://\(text)"
    
    if let url = NSURL(string: str) where url.absoluteString!.rangeOfString(".") != nil {
      webView.loadRequest(NSURLRequest(URL: url))
    } else {
      let txt = "https://www.google.com/search?q=\(text)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
      webView.loadRequest(NSURLRequest(URL: NSURL(string: txt!)!))
    }
  }
  
  //MARK: - UIScrollViewDelegate
  
  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    currentOffset = scrollView.contentOffset.y
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let scrollPos = scrollView.contentOffset.y
    if scrollPos > currentOffset {
      UIView.animateWithDuration(0.25, animations: {
        self.searchViewHeightConstraint.constant = 0
        self.delegate?.hideTabBarFooter()
      })
    } else {
      searchViewHeightConstraint.constant = 44
      delegate?.showTabBarFooter()
    }
  }
  
}
