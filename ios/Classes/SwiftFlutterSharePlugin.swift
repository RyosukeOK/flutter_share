import Flutter
import UIKit
import LinkPresentation

public class SwiftFlutterSharePlugin: NSObject, FlutterPlugin {
    
    private var result: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_share", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SwiftFlutterSharePlugin(), channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("share" == call.method) {
            if #available(iOS 13.0, *) {
                self.result = result
                result(shareWithMetadata(call: call))
            } else {
                self.result = result
                result(share(call: call))
            }
            
        } else if ("shareFile" == call.method) {
            self.result = result
            result(shareFile(call: call))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func share(call: FlutterMethodCall) -> Bool {
        let args = call.arguments as? [String: Any?]
        
        let title = args!["title"] as? String
        let text = args!["text"] as? String
        let linkUrl = args!["linkUrl"] as? String
        
        if (title == nil || title!.isEmpty) {
            return false
        }
        
        var sharedItems : Array<NSObject> = Array()
        var textList : Array<String> = Array()
        
        // text
        if (text != nil && text != "") {
            textList.append(text!)
        }
        // Link url
        if (linkUrl != nil && linkUrl != "") {
            textList.append(linkUrl!)
        }
        
        var textToShare = ""
        
        if (!textList.isEmpty) {
            textToShare = textList.joined(separator: "\n\n")
        }
        
        sharedItems.append((textToShare as NSObject?)!)
        
        let activityViewController = UIActivityViewController(activityItems: sharedItems, applicationActivities: nil)
        
        // Subject
        if (title != nil && title != "") {
            activityViewController.setValue(title, forKeyPath: "subject");
        }
        
        DispatchQueue.main.async {
            UIApplication.topViewController()?.present(activityViewController, animated: true, completion: nil)
        }
        
        return true
    }
    
    @available(iOS 13.0, *)
    public func shareWithMetadata(call: FlutterMethodCall) -> Bool {
        
        let args = call.arguments as? [String: Any?]
        
        let title = args!["title"] as? String
        let filePath = args!["filePath"] as? String
        let text = args!["text"] as? String
        let linkUrl = args!["linkUrl"] as? String
        
        if (title == nil || title!.isEmpty) {
            return false
        }
        if (title == nil || title!.isEmpty || filePath == nil || filePath!.isEmpty) {
            return false
        }
        
        let metadataItemSource = LinkPresentationItemSource(title:title!,fileURL:URL(fileURLWithPath: filePath!),url:URL(string: linkUrl!)!,text:text!)
        let activityViewController = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [])
        
        // Subject
        if (title != nil && title != "") {
            activityViewController.setValue(title, forKeyPath: "subject");
        }
        
        DispatchQueue.main.async {
            UIApplication.topViewController()?.present(activityViewController, animated: true, completion: nil)
        }
        
        return true
    }
    
    public func shareFile(call: FlutterMethodCall) -> Bool {
        let args = call.arguments as? [String: Any?]
        
        let title = args!["title"] as? String
        let text = args!["text"] as? String
        let filePath = args!["filePath"] as? String
        
        if (title == nil || title!.isEmpty || filePath == nil || filePath!.isEmpty) {
            return false
        }
        
        var sharedItems : Array<NSObject> = Array()
        
        // text
        if (text != nil && text != "") {
            sharedItems.append((text as NSObject?)!)
        }
        
        // File url
        if (filePath != nil && filePath != "") {
            let filePath = URL(fileURLWithPath: filePath!)
            sharedItems.append(filePath as NSObject);
        }
        
        let activityViewController = UIActivityViewController(activityItems: sharedItems, applicationActivities: nil)
        
        // Subject
        if (title != nil && title != "") {
            activityViewController.setValue(title, forKeyPath: "subject");
        }
        
        // For iPads, fix issue where Exception is thrown by using a popup instead
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = UIApplication.topViewController()?.view
            if let view = UIApplication.topViewController()?.view {
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.topViewController()?.present(activityViewController, animated: true, completion: nil)
        }
        
        return true
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

@available(iOS 13.0, *)
class LinkPresentationItemSource: NSObject, UIActivityItemSource {
    
    private let title: String
    private let linkMetadata: LPLinkMetadata
    private let fileURL: URL
    private let url: URL
    private let text: String
    
    
    init( title:String,fileURL: URL, url: URL, text:String) {
        self.title = title
        self.fileURL = fileURL
        self.url = url
        self.text = text
        linkMetadata = LPLinkMetadata()
        super.init()
        
        linkMetadata.title = title
        linkMetadata.originalURL = url
        linkMetadata.iconProvider = NSItemProvider(contentsOf: fileURL)
        //        linkMetadata.imageProvider = NSItemProvider(contentsOf: fileURL)
        
        //  async metadata URL
        //        let metadataProvider = LPMetadataProvider()
        //        metadataProvider.startFetchingMetadata(for: url) { [linkMetadata] metadata, error in
        //            // `linkMetadata` に足りなかった情報を入れてプレビューを完成させる
        //            linkMetadata.title = metadata?.title
        //            linkMetadata.url = metadata?.url
        //            linkMetadata.originalURL = metadata?.originalURL
        //            linkMetadata.iconProvider = metadata?.iconProvider
        //            linkMetadata.imageProvider = metadata?.imageProvider
        //        }
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return linkMetadata
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        
        guard let activityType = activityType else {
            return ""
        }
        
        switch activityType {
        case .postToFacebook:
            return url.absoluteString+" "+text
        case .postToTwitter:
            return url.absoluteString+" "+text
            
        default:
            return url.absoluteString
        }
    }
    
}
