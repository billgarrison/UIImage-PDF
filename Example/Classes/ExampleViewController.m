//
//  UIImage_PDF_exampleViewController.m
//  UIImage+PDF example
//
//  Created by Nigel Barber on 15/10/2011.
//  Copyright 2011 Mindbrix. All rights reserved.
//

#import "ExampleViewController.h"


@implementation ExampleViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
	
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSURL *yangURL = [[NSBundle mainBundle] URLForResource:@"YingYang.pdf" withExtension:nil];
    
    /* Add image from PDF file anchored at the top of the view, and fitted to the view size. */
    {
        CGFloat topAnchor = 10.0f;
        UIImage *image = [UIImage imageWithPDFURL:yangURL fitSize:[[self view] bounds].size atPage:1 scale:scale];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.center = (CGPoint){
            .x = CGRectGetWidth([[self view] bounds]) / 2.0f,
            .y = topAnchor + CGRectGetHeight ([imageView bounds]) / 2.0f
        };

        [[self view] addSubview:imageView];
    }
    
    /* Add image from PDF data anchored at the bottom of the view, original PDF size. */
    {
        NSData *PDFData = [NSData dataWithContentsOfURL:yangURL options:NSDataReadingUncached error:NULL];
        UIImage *image = [UIImage imageWithPDFData:PDFData atSize:CGSizeZero atPage:1 scale:scale];
        
        CGFloat bottomAnchor = CGRectGetHeight ([[self view] bounds]) - 10.0f;
        UIImageView *imageView = [[ UIImageView alloc ] initWithImage:image];
        imageView.center = (CGPoint) {
            .x = CGRectGetWidth([[self view] bounds])/ 2.0f ,
            .y = bottomAnchor - CGRectGetHeight ([imageView frame])/ 2.0f
        };
        [[self view] addSubview:imageView];
    }
   
	/* Draw a growing vertical line of small images to demonstate the scaling
	 */
	CGFloat kSpacing = 10;
	CGFloat imagePositionY = kSpacing;

	for (int i = 0; i < 8; i++)
	{
		/* Always round up coordinates before passing them into UIKit
		 */
		CGFloat imageWidth = ceilf ((6.0f * i) + 22.0f);
		CGSize imageSize = (CGSize){.width=imageWidth, .height=imageWidth};
        
        CGRect frame = (CGRect){
            .origin.x=kSpacing,
            .origin.y=imagePositionY,
            .size =imageSize,
        };
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
		
		/* Set the button image from the PDF asset. */
        NSURL *yangURL = [[NSBundle mainBundle] URLForResource:@"YingYang.pdf" withExtension:nil];
        [ imageView setImage:[UIImage imageWithPDFURL:yangURL atSize:imageSize atPage:1 scale:scale]];
        
        [ self.view addSubview:imageView ];
		
		imagePositionY += CGRectGetHeight([imageView frame]) + kSpacing;
	}
    
    
}


@end
