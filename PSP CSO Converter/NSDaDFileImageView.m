//
//  NSDaDFilesImageView.m
//  Drag And Drop Image View
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import "NSDaDFileImageView.h"

@implementation NSDaDFileImageView
@synthesize highlightColor = _highlightColor;
@synthesize highlightSize = _highlightSize;

- (void)awakeFromNib{
}

- (id)initWithFrame:(NSRect)frame{
    
    self = [super initWithFrame:frame];
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        // Unregister Default Image View Types
        [self unregisterDraggedTypes];
        // Register URL Type
        NSArray *dragTypes = @[NSURLPboardType];
        [self registerForDraggedTypes:dragTypes];
        
        // Default Values
        _dragAndDropEnabled = YES;
        _highlightSize = @6.0;
        _highlightColor = [NSColor selectedControlColor];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Call Super Draw Rect For Default Behavior
    [super drawRect:dirtyRect];
    
    // Set Highlight Color Or ClearColor For Not Highlighting
    if([self dragAndDropEnabled] && [self isHighlighted])
    {
        [[self highlightColor]set];
        [NSBezierPath setDefaultLineWidth:[[self highlightSize]floatValue]];
    }
    else{
        [[NSColor clearColor]set];
    }
    
    // Display Highlight
    [NSBezierPath strokeRect:dirtyRect];
    
}

#pragma mark - Getters - Setters

- (NSColor*)highlightColor{
    return  _highlightColor;
}
- (void)setHighlightColor:(NSColor *)highlightColor{
    if(highlightColor == nil)
        _highlightColor = [NSColor selectedControlColor];
    else
        _highlightColor = highlightColor;
}

- (NSNumber*)highlightSize{
    return _highlightSize;
}
- (void)setHighlightSize:(NSNumber *)highlightSize{

    if(highlightSize == nil || [highlightSize floatValue] < 0)
    {
        _highlightSize = @6.0;
    }
    else
    {
        _highlightSize = highlightSize;
    }
}

#pragma mark - Dragging Delegate

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{

    //  If Drag And Drop Is Enabled
    if([self dragAndDropEnabled])
    {
        NSPasteboard *pBoard = [sender draggingPasteboard];
        if([[pBoard types]containsObject:NSURLPboardType])
        {
            [self setHighlighted:YES];
            NSURL *pathURL = [NSURL URLFromPasteboard:pBoard];
            NSString *path = [pathURL path];
            
            // Update Delegate
            if([[self delegate]respondsToSelector:@selector(fileEntered:in:)])
                [[self delegate]fileEntered:path in:self];
        }
    }
    
    return NSDragOperationLink;
}
- (void) draggingExited:(id<NSDraggingInfo>)sender{

    // Set Highlight Always Off To bypass any errors
    [self setHighlighted:NO];
    
    //  If Drag And Drop Is Enabled
    if([self dragAndDropEnabled])
    {
        
        NSPasteboard *pBoard = [sender draggingPasteboard];
        if([[pBoard types]containsObject:NSURLPboardType])
        {
            NSURL *pathURL = [NSURL URLFromPasteboard:pBoard];
            NSString *path = [pathURL path];
            
            // Update Delegate
            if([[self delegate]respondsToSelector:@selector(fileExited:in:)])
                [[self delegate]fileExited:path in:self];
        }
    }
}
- (BOOL) performDragOperation:(id < NSDraggingInfo >)sender{
    
    [self setHighlighted:NO];
    //  If Drag And Drop Is Enabled
    if([self dragAndDropEnabled])
    {
        
        NSPasteboard *pBoard = [sender draggingPasteboard];
        if([[pBoard types]containsObject:NSURLPboardType])
        {
            NSURL *pathURL = [NSURL URLFromPasteboard:pBoard];
            NSString *path = [pathURL path];
            
            // Update Delegate
            if([[self delegate]respondsToSelector:@selector(fileDropped:in:)])
                [[self delegate]fileDropped:path in:self];
            return YES;
        }
    }
    return NO;
}
- (void) draggingEnded:(id<NSDraggingInfo>)sender{

    // Nothing To Do Here
    
}
- (void) concludeDragOperation:(id < NSDraggingInfo >)sender{
 
    // Nothing To Do Here
}
@end
