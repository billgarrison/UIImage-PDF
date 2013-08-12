/*
 UIImage+PDF.m
 
 Copyright 2013 Standard Orbit Software, LLC. All rights reserved. <https://github.com/billgarrison/UIImage-PDF>
 
 Open Sourced at GitHub: <git://github.com/billgarrison/UIImage-PDF.git>
 
 Based on original work by Nigel Barber at <https://github.com/mindbrix/UIImage-PDF>
 
 Copyright 2012 Nigel Timothy Barber - [@mindbrix](http://twitter.com/mindbrix). All rights reserved.
 Permission is given to use this source code file without charge in any project, commercial or otherwise, entirely at your risk,
 with the condition that any redistribution (in part or whole) of source code must retain this copyright and permission notice.
 Attribution in compiled projects is appreciated but not required.
 */

#import "UIImage+PDF.h"
#import <CommonCrypto/CommonDigest.h>

static UIImage *_PDFHelperRenderImage(NSURL *pdfURL, NSData *resourceData,  CGSize size, int page, CGFloat scale);
static CGRect _PDFMediaRect(NSURL *pdfURL, int page);
static size_t _PDFPageCount(NSURL *pdfURL);

static NSString *MD5FromNSString(NSString *string)
{
	/* From: https://gist.github.com/1209911
	 */
	if ([string length] == 0) return nil;
    
	const char *cStr = [string UTF8String];
	unsigned char result[16];
	CC_MD5 (cStr, strlen (cStr), result); /* This is the md5 call */
	return [NSString stringWithFormat:
	        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
	        result[0], result[1], result[2], result[3],
	        result[4], result[5], result[6], result[7],
	        result[8], result[9], result[10], result[11],
	        result[12], result[13], result[14], result[15]
            ];
}

static NSString *MD5FromNSData(NSData *data)
{
	if (!data) return nil;
    
	unsigned char result[16];
	CC_MD5 ([data bytes], [data length], result); /* This is the md5 call */
	return [NSString stringWithFormat:
	        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
	        result[0], result[1], result[2], result[3],
	        result[4], result[5], result[6], result[7],
	        result[8], result[9], result[10], result[11],
	        result[12], result[13], result[14], result[15]
            ];
}

@implementation  UIImage (PDF)


#pragma mark - Disk Cacheing

+ (NSURL *) PDFCacheURL
{
    static NSURL *sPDFCacheURL = nil;

#ifdef UIIMAGE_PDF_CACHEING

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager new];
        NSError *cacheSetupError = nil;
        
        NSURL *cacheURL = [[fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&cacheSetupError]  URLByAppendingPathComponent:@"__UIIMAGE_PDF_CACHE__"];
        
        if (cacheURL) {
            if ([fm createDirectoryAtURL:cacheURL withIntermediateDirectories:YES attributes:nil error:&cacheSetupError]) {
                sPDFCacheURL = cacheURL;
            }
        }
        
        if (sPDFCacheURL == nil) {
            NSLog (@"Error: failed to created cache directory for rendered PDF UImages: %@", cacheSetupError);
        }
    });
#endif

    return sPDFCacheURL;
}

+ (NSString *) cacheFilenameForData:(NSData *)resourceData atSize:(CGSize)size atScaleFactor:(CGFloat)scaleFactor atPage:(int)page
{
	NSString *cachedName = nil;
    
#ifdef UIIMAGE_PDF_CACHEING
    
    CGSize scaledSize = CGSizeMake (size.width * scaleFactor, size.height * scaleFactor);
	NSString *uniquedName = [NSString stringWithFormat:@"%@-%@-%d", MD5FromNSData (resourceData), NSStringFromCGSize (scaledSize), page];
    
	NSString *MD5Hash = MD5FromNSString (uniquedName);
    
    cachedName = [[[[self PDFCacheURL] path] stringByAppendingPathComponent:MD5Hash] stringByAppendingPathExtension:@"png"];
#endif
    
	return cachedName;
}


+ (NSString *) cacheFilenameForURL:(NSURL *)URL atSize:(CGSize)size atScaleFactor:(CGFloat)scaleFactor atPage:(int)page
{
	NSString *cachedName = nil;
    
#ifdef UIIMAGE_PDF_CACHEING
    
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *filePath = [URL path];
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:NULL];
    CGSize scaledSize = CGSizeMake (size.width * scaleFactor, size.height * scaleFactor);

	NSString *uniquedName = [NSString stringWithFormat:@"%@-%@-%@-%@-%d", [filePath lastPathComponent], fileAttributes[NSFileSize], fileAttributes[NSFileModificationDate], NSStringFromCGSize (scaledSize), page];
    
	NSString *MD5Hash = MD5FromNSString (uniquedName);
    cachedName = [[[[self PDFCacheURL] path] stringByAppendingPathComponent:MD5Hash] stringByAppendingPathExtension:@"png"];

#endif
    
	return cachedName;
}


+ (UIImage *) imageWithPDFData:(NSData *)data atSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale
{
	UIImage *image = nil;
    
	NSString *cacheFilename = [self cacheFilenameForData:data atSize:size atScaleFactor:scale atPage:page];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFilename])
    {
		image = [UIImage imageWithCGImage:[[UIImage imageWithContentsOfFile:cacheFilename] CGImage] scale:scale orientation:UIImageOrientationUp];
	}
	else
    {
        image = _PDFHelperRenderImage(nil, data, size, page, scale);
        
		if (cacheFilename) {
			[UIImagePNGRepresentation(image) writeToFile:cacheFilename atomically:NO];
		}
	}
    
	return image;
}


+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL atSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale
{
    if (fileURL == nil) return nil;
    
	UIImage *image = nil;
    
	NSString *cacheFilename = [self cacheFilenameForURL:fileURL atSize:size atScaleFactor:scale atPage:page];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFilename])
    {
		image = [UIImage imageWithCGImage:[[UIImage imageWithContentsOfFile:cacheFilename] CGImage] scale:scale orientation:UIImageOrientationUp];
	}
	else
    {
        image = _PDFHelperRenderImage(fileURL, nil, size, page, scale);
		if (cacheFilename && image) {
			[UIImagePNGRepresentation(image) writeToFile:cacheFilename atomically:NO];
		}
	}

	return image;
}



+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale
{
	/* Get dimensions */
	CGRect mediaRect = _PDFMediaRect(fileURL, page);
    
	/* Calculate scale factor */
	CGFloat scaleFactor = MAX (mediaRect.size.width / size.width, mediaRect.size.height / size.height);
    
	/* Create new size */
	CGSize fittedSize = CGSizeMake (ceilf (mediaRect.size.width / scaleFactor), ceilf (mediaRect.size.height / scaleFactor));
    
	/* Return image */
    return [UIImage imageWithPDFURL:fileURL atSize:fittedSize atPage:page scale:scale];

}


+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitWidth:(CGFloat)width atPage:(size_t)page scale:(CGFloat)scale
{
	CGRect mediaRect = _PDFMediaRect(fileURL, page);
	CGFloat aspectRatio = mediaRect.size.width / mediaRect.size.height;
    
	CGSize size = CGSizeMake (width, ceilf (width / aspectRatio));
    
    return [UIImage imageWithPDFURL:fileURL atSize:size atPage:page scale:scale];
}



+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitHeight:(CGFloat)height atPage:(size_t)page scale:(CGFloat)scale
{
	CGRect mediaRect = _PDFMediaRect(fileURL, page);
	CGFloat aspectRatio = mediaRect.size.width / mediaRect.size.height;
    
	CGSize size = CGSizeMake (ceilf (height * aspectRatio), height);
    
    return [UIImage imageWithPDFURL:fileURL atSize:size atPage:page scale:scale];
}



@end

#pragma mark - PDF Helper Routines

static size_t _PDFPageCount(NSURL *pdfURL)
{
    NSUInteger pageCount = 0;
    
	if (pdfURL)
	{
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL ((__bridge CFURLRef) pdfURL);
		pageCount = CGPDFDocumentGetNumberOfPages (pdf);
		CGPDFDocumentRelease (pdf);
	}
	return pageCount;
}

static CGRect _PDFMediaRect(NSURL *pdfURL, int page)
{
    CGRect rect = CGRectNull;
    
	if (pdfURL)
	{
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL ((__bridge CFURLRef) pdfURL);
		CGPDFPageRef pageRef = CGPDFDocumentGetPage (pdf, page);
        
		rect = CGPDFPageGetBoxRect (pageRef, kCGPDFCropBox);
        
		CGPDFDocumentRelease (pdf);
	}
    return rect;
}

static UIImage *_PDFHelperRenderImage(NSURL *pdfURL, NSData *resourceData, CGSize size, int page, CGFloat scale)
{
    UIImage *rendered = nil;
    
    if (!pdfURL && !resourceData) return nil;
    
    /* Get a PDFDocumentRef */
    
    CGPDFDocumentRef pdf = NULL;
    if (pdfURL)
    {
        pdf = CGPDFDocumentCreateWithURL ((__bridge CFURLRef) pdfURL);
    }
    else
    {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)resourceData);
        pdf = CGPDFDocumentCreateWithProvider (provider);
        CGDataProviderRelease (provider);
    }
    
    
    CGPDFPageRef pageRef = CGPDFDocumentGetPage (pdf, page);
    CGRect mediaRect = CGPDFPageGetBoxRect (pageRef, kCGPDFCropBox);
    
    
    /* If user asked for full PDF size, use the reported PDF media box size. */
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = mediaRect.size;
    }
    
    UIGraphicsBeginImageContextWithOptions (size, NO /*opaque*/, scale);
    CGContextRef bitmapContext = UIGraphicsGetCurrentContext();
    
    /*
     * Reference: http://www.cocoanetics.com/2010/06/rendering-pdf-is-easier-than-you-thought/
     */
    CGContextGetCTM (bitmapContext);
    CGContextScaleCTM (bitmapContext, 1, -1);
    CGContextTranslateCTM (bitmapContext, 0, -size.height);
    
    CGContextScaleCTM (bitmapContext, size.width / mediaRect.size.width, size.height / mediaRect.size.height);
    CGContextTranslateCTM (bitmapContext, -mediaRect.origin.x, -mediaRect.origin.y);
    
    CGContextDrawPDFPage (bitmapContext, pageRef);
    CGPDFDocumentRelease (pdf);
    
    rendered = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
	
    
    return rendered;
}

