import UIKit

// Basic App-/WebView-configuration
let appTitle = "iOS PWA Wrapper"
let webAppUrl = URL(string: "https://develat.io")
let allowedOrigin = "develat.io"
let app_version = "iOSApp/1.0.0"

// UI Settings
let changeAppTitleToPageTitle = false
let forceLargeTitle = false

// Colors & Styles
let useLightStatusBarStyle = true
let progressBarColor = getColorFromHex(hex: 0xF9ED4F, alpha: 1.0)
let offlineIconColor = UIColor.darkGray
let buttonColor = getColorFromHex(hex: 0xFFFFFF, alpha: 1.0)
let activityIndicatorColor = getColorFromHex(hex: 0xFFFFFF, alpha: 1.0)

// Color Helper function
func getColorFromHex(hex: UInt, alpha: CGFloat) -> UIColor {
    return UIColor(
        red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(hex & 0x0000FF) / 255.0,
        alpha: CGFloat(alpha)
    )
}
