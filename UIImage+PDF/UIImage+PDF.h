/*
 UIImage+PDF.h
 
 Copyright 2013 Standard Orbit Software, LLC. All rights reserved. <https://github.com/billgarrison/UIImage-PDF>
 
 Open Sourced at GitHub: <git://github.com/billgarrison/UIImage-PDF.git>

 Based on original work by Nigel Barber at <https://github.com/mindbrix/UIImage-PDF>

 Copyright 2012 Nigel Timothy Barber - [@mindbrix](http://twitter.com/mindbrix). All rights reserved.
 Permission is given to use this source code file without charge in any project, commercial or otherwise, entirely at your risk,
 with the condition that any redistribution (in part or whole) of source code must retain this copyright and permission notice.
 Attribution in compiled projects is appreciated but not required.
 */


#import <UIKit/UIKit.h>

#define UIIMAGE_PDF_CACHEING  1


@interface UIImage (PDF)

+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL atSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale;
+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale;

+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitWidth:(CGFloat)width atPage:(size_t)page scale:(CGFloat)scale;
+ (UIImage *) imageWithPDFURL:(NSURL *)fileURL fitHeight:(CGFloat)height atPage:(size_t)page scale:(CGFloat)scale;


+ (UIImage *) imageWithPDFData:(NSData *)data atSize:(CGSize)size atPage:(size_t)page scale:(CGFloat)scale;

@end
