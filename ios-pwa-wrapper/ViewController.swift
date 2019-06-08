import UIKit
import WebKit

class ViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet weak var offlineIcon: UIImageView!
    @IBOutlet weak var offlineButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Globals
    var webView: WKWebView!
    var tempView: WKWebView!
    var progressBar : UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = appTitle
        setupApp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // reload page from offline screen
    @IBAction func onOfflineButtonClick(_ sender: Any) {
        offlineView.isHidden = true
        webViewContainer.isHidden = false
        loadAppUrl()
    }
    
    // Observers for updating UI
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == #keyPath(WKWebView.isLoading)) {
            // show activity indicator

            /*
            // this causes troubles when swiping back and forward.
            // having this disabled means that the activity view is only shown on the startup of the app.
            // ...which is fair enough.
            if (webView.isLoading) {
                activityIndicatorView.isHidden = false
                activityIndicator.startAnimating()
            }
            */
        }
        if (keyPath == #keyPath(WKWebView.estimatedProgress)) {
            progressBar.progress = Float(webView.estimatedProgress)
        }
    }
    
    // Initialize WKWebView
    func setupWebView() {
        // set up webview
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: webViewContainer.frame.width, height: webViewContainer.frame.height))
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewContainer.addSubview(webView)

        // Disable overscroll
        webView.scrollView.bounces = false
        
        // Disable zooming
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        
        // Disable swiping
        webView.allowsBackForwardNavigationGestures = false
        
        // settings
        webView.configuration.preferences.javaScriptEnabled = true
        if #available(iOS 10.0, *) {
            webView.configuration.ignoresViewportScaleLimits = false
        }
        
        // make it possible to detect the version of the app
        webView.evaluateJavaScript("app_version = '" + app_version + "';")
        if #available(iOS 9.0, *) {
            tempView = WKWebView(frame: .zero)
            tempView.evaluateJavaScript("navigator.userAgent", completionHandler: { (result, error) in
                if let resultObject = result {
                    self.webView.customUserAgent = (String(describing: resultObject) + " " + app_version)
                    self.tempView = nil
                }
            })
        }

        // init observers
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: NSKeyValueObservingOptions.new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    // Initialize UI elements
    // call after WebView has been initialized
    func setupUI() {
        // leftButton.isEnabled = false

        // progress bar
        progressBar = UIProgressView(frame: CGRect(x: 0, y: 0, width: webViewContainer.frame.width, height: 40))
        progressBar.autoresizingMask = [.flexibleWidth]
        progressBar.progress = 0.0
        progressBar.tintColor = progressBarColor
        webView.addSubview(progressBar)
        
        // activity indicator
        activityIndicator.color = activityIndicatorColor
        activityIndicator.startAnimating()
        
        // offline container
        offlineIcon.tintColor = offlineIconColor
        offlineButton.tintColor = buttonColor
        offlineView.isHidden = true
        
        // setup navigation bar
        if (forceLargeTitle) {
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.always
            }
        }
        if (useLightStatusBarStyle) {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        }
        
        /*
        // @DEBUG: test offline view
        offlineView.isHidden = false
        webViewContainer.isHidden = true
        */
    }

    // load startpage
    func loadAppUrl() {
        let urlRequest = URLRequest(url: webAppUrl!)
        webView.load(urlRequest)
    }
    
    // Initialize App and start loading
    func setupApp() {
        setupWebView()
        setupUI()
        loadAppUrl()
    }
    
    // Cleanup
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
}

// WebView Event Listeners
extension ViewController: WKNavigationDelegate {
    // didFinish
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // set title
        if (changeAppTitleToPageTitle) {
            navigationItem.title = webView.title
        }
        // hide progress bar after initial load
        progressBar.isHidden = true
        // hide activity indicator
        activityIndicatorView.isHidden = true
        activityIndicator.stopAnimating()
    }
    // didFailProvisionalNavigation
    // == we are offline / page not available
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // show offline screen
        offlineView.isHidden = false
        webViewContainer.isHidden = true
    }
}

// WebView additional handlers
extension ViewController: WKUIDelegate {
    // handle links opening in new tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let requestUrl = navigationAction.request.url {
            if let requestHost = requestUrl.host {
                if (requestHost.range(of: allowedOrigin) != nil ) {
                    decisionHandler(.allow)
                } else {
                    decisionHandler(.cancel)
                    if (UIApplication.shared.canOpenURL(requestUrl)) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(requestUrl)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(requestUrl)
                        }
                    }
                }
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}
