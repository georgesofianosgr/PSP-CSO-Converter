//
//  PCCAppDelegate.h
//  PSP CSO Converter
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDaDFileImageView.h"
#import "CSOManager.h"
@interface PCCAppDelegate : NSObject <NSApplicationDelegate,CSOManagerDelegate,ImageViewFileDragAndDropDelegate>
{
    CSOManager *csoManager;
    NSSound *finishSound;
    NSSavePanel *sPanel;
    
    // For Displaying A Bar At Dock
    NSDockTile *dockTile;
    NSProgressIndicator *progressDockIndicator;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *openButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *exitButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSTextField *progressPercentLabel;
@property (weak) IBOutlet NSTextField *convertStatusLabel;
@property (weak) IBOutlet NSImageView *convertStatusIcon;
@property (weak) IBOutlet NSDaDFileImageView *dragADropImageView;
@property (weak) IBOutlet NSView *accessoryView;
@property (weak) IBOutlet NSPopUpButton *levelPopUp;



@end
