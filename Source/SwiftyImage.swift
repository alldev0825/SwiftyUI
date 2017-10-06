//
//  SwiftyImage.swift
//  WHCWSIFT
//
//  Created by Haochen Wang on 10/1/17.
//  Copyright © 2017 Haochen Wang. All rights reserved.
//

//import CoreGraphics
import UIKit

extension UIImage
{
    public final class func load(_ data: Data) -> UIImage?
    {
        var image : UIImage?
        NSLock().locker(ClosureWrapper({ (_) in
            image = UIImage(data: data)
        }))
        return image
    }

    public final class func load(_ data: Data, scale: CGFloat) -> UIImage?
    {
        var image : UIImage?
        NSLock().locker(ClosureWrapper({ (_) in
            image = UIImage(data: data, scale: scale)
        }))
        return image
    }
    
    public final class func load(_ name: String) -> UIImage?
    {
        var image : UIImage?
        NSLock().locker(ClosureWrapper({ (_) in
            let imageCachePool : ImageCachePool = .defalut
            if let cacheImage = imageCachePool.image(withIdentifier: name)
            {
                image = cacheImage
            }
            else if let oriImage = UIImage(named: name)
            {
                oriImage.inflate()
                imageCachePool.add(oriImage, withIdentifier: name)
                image = oriImage
            }
        }))
        return image
    }
    
    public final class func load(_ aImage: UIImage?, identifier: String) -> UIImage?
    {
        var image : UIImage?
        NSLock().locker(ClosureWrapper({ (_) in
            let imageCachePool : ImageCachePool = .defalut
            if let oriImage = aImage
            {
                oriImage.inflate()
                imageCachePool.add(oriImage, withIdentifier: identifier)
                image = oriImage
            }
        }))
        return image
    }
}

extension UIImage
{
    private struct AssociatedKey {
        fileprivate static var isInflatedKey : UnsafeRawPointer = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
    }
    
    private final var isInflated: Bool {
        get {
            guard let obj = objc_getAssociatedObject(self, AssociatedKey.isInflatedKey) as? Bool else {
                
                self.isInflated = false
                return self.isInflated
            }
            return obj
        }
        set {
            objc_setAssociatedObject(self, AssociatedKey.isInflatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func inflate()
    {
        guard isInflated == false else { return }
        isInflated = true
        _ = cgImage?.dataProvider?.data
    }
    
    public final var isOpaque: Bool
    {
        
        let alphaInfo = cgImage?.alphaInfo
        return !(alphaInfo == .first || alphaInfo == .last || alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast)
    }

    public func reSize(to size: CGSize) -> UIImage
    {
        guard size.width > 0 && size.height > 0 else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    public func reSize(toFit size: CGSize) -> UIImage
    {
        guard size.width > 0 && size.height > 0 else { return self }
        
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height
        var resizeFactor: CGFloat
        if imageAspectRatio > canvasAspectRatio
        {
            resizeFactor = size.width / self.size.width
        }
        else
        {
            resizeFactor = size.height / self.size.height
        }
        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: origin, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
    
        return scaledImage
    }
    
    public func reSize(toFill size: CGSize) -> UIImage
    {
        guard size.width > 0 && size.height > 0 else { return self }

        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height
        var resizeFactor: CGFloat
        if imageAspectRatio > canvasAspectRatio
        {
            resizeFactor = size.height / self.size.height
        }
        else
        {
            resizeFactor = size.width / self.size.width
        }
        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2.0, y: (size.height - scaledSize.height) / 2.0)
        
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
        draw(in: CGRect(origin: origin, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    public func rounded(withCornerRadius radius: CGFloat, divideRadiusByImageScale: Bool = false) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let scaledRadius = divideRadiusByImageScale ? radius / scale : radius
        
        let clippingPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: size), cornerRadius: scaledRadius)
        clippingPath.addClip()
        
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return roundedImage
    }
    
    public func roundedIntoCircle() -> UIImage
    {
        let radius = min(size.width, size.height) / 2.0
        var squareImage = self
        if size.width != size.height
        {
            let squareDimension = min(size.width, size.height)
            let squareSize = CGSize(width: squareDimension, height: squareDimension)
            squareImage = reSize(toFill: squareSize)
        }
        
        UIGraphicsBeginImageContextWithOptions(squareImage.size, false, 0.0)
        let clippingPath = UIBezierPath( roundedRect: CGRect(origin: CGPoint.zero, size: squareImage.size), cornerRadius: radius)
        clippingPath.addClip()
        squareImage.draw(in: CGRect(origin: CGPoint.zero, size: squareImage.size))
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return roundedImage
    }
}

    
final class ImageCachePool: ImageCacheable
{
    open static let defalut: ImageCachePool = {
        return ImageCachePool()
    }()
    
    private init()
    {
        NotificationCenter.default.addObserver(self, name: Notification.Name.UIApplicationDidReceiveMemoryWarning, object: nil, selector: ClosureWrapper({ [weak self] (_) in
            
            guard let strongSelf = self else { return }
            strongSelf.removeAllImages()
        }))
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
}

