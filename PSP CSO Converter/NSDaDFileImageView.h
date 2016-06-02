//
//  NSDaDFilesImageView.h
//  Drag And Drop Image View
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ImageViewFileDragAndDropDelegate;

@interface NSDaDFileImageView : NSImageView <NSDraggingDestination>
@property id <ImageViewFileDragAndDropDelegate> delegate;
@property (readonly) BOOL   highlighted;
@property BOOL              dragAndDropEnabled;
@property NSColor*          highlightColor;
@property NSNumber*         highlightSize;


@end

@protocol ImageViewFileDragAndDropDelegate <NSObject>
@optional

- (void) fileDropped:(NSString*) filePath in:(NSDaDFileImageView*) sender;
- (void) fileEntered:(NSString*) filePath in:(NSDaDFileImageView*) sender;
- (void) fileExited: (NSString*) filePath in:(NSDaDFileImageView*) sender;
@end