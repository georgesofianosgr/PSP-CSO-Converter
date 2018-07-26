//
//  PCCAppDelegate.m
//  PSP CSO Converter
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import "PCCAppDelegate.h"

@implementation PCCAppDelegate

- (id)init{
    self = [super init];
    if(self)
    {
        csoManager = [[CSOManager alloc]init];
        [csoManager setDelegate:self];
        
        finishSound = [NSSound soundNamed:@"Glass"];
    }
    return self;
}

- (void)awakeFromNib{
    [[self dragADropImageView]setDelegate:self];
    sPanel = [NSSavePanel savePanel];
    [self initDockTileBar];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    // Insert code here to initialize your application
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}
- (void)applicationWillTerminate:(NSNotification *)aNotification{
    if([csoManager isConverting])
    {
        [csoManager cancelConvert];
        [self deleteSemiCompleteFile];
    }
}
- (void)initDockTileBar{
    dockTile = [[NSApplication sharedApplication] dockTile];
    NSImageView *iv = [[NSImageView alloc] init];
    [iv setImage:[[NSApplication sharedApplication] applicationIconImage]];
    [dockTile setContentView:iv];
    
    progressDockIndicator = [[NSProgressIndicator alloc]
                             initWithFrame:NSMakeRect(0.0f, 0.0f, dockTile.size.width, 20.)];
    [progressDockIndicator setStyle:NSProgressIndicatorBarStyle];
    [progressDockIndicator setIndeterminate:NO];
    [iv addSubview:progressDockIndicator];
    
    [progressDockIndicator setBezeled:YES];
    [progressDockIndicator setMinValue:0];
    [progressDockIndicator setMaxValue:100];
}
#pragma mark - Main Methods


- (void)convertFile:(NSString*) filePath{
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(convertFile:) withObject:filePath waitUntilDone:NO];
        return;
    }
    
    // Open Save Panel
    NSString *saveFilePath = [self savePanelForFile:filePath];
    
    if(saveFilePath){

        // Update View To Convert Started
        [self updateViewForEvent:@"CONVERT_STARTED"];
        // Convert
        if([[filePath pathExtension]caseInsensitiveCompare:@"ciso"] == NSOrderedSame||
           [[filePath pathExtension]caseInsensitiveCompare:@"cso"] == NSOrderedSame)
        {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [csoManager decompressCSO:filePath toPath:saveFilePath];
            });
        }
        else if([[filePath pathExtension]caseInsensitiveCompare:@"iso"] == NSOrderedSame)
        {
            // Get Lavel From Save Panel
            NSString *levelStr = [[self levelPopUp]titleOfSelectedItem];
            NSNumber *level = [NSNumber numberWithInt:[levelStr intValue]];
            if([level intValue] < 0 || [level intValue] >9)
                level = [NSNumber numberWithInt:6];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [csoManager compressISO:filePath toPath:saveFilePath withCompressLevel:level];
            });
        }
        // Update View To Convert Ended
        [self updateViewForEvent:@"CONVERT_ENDED"];
    }
}

#pragma mark - UI

- (void)updateViewForEvent:(NSString*) event{
    
    __unused NSArray * events = @[@"DROP_ENTERED",
                         @"DROP_EXITED",
                         @"DROP_DROPPED",
                         @"CONVERT_STARTED",
                         @"CONVERT_ENDED",
                         @"PANEL_OPENED",
                         @"PANEL_CLOSED"];
    
    if([event isEqualToString:@"DROP_ENTERED"])
    {
        [[self dragADropImageView]setImage:[self resourceImageForFileName:@"dadDrop.gif"]];
    }
    else if([event isEqualToString:@"DROP_EXITED"])
    {
        [[self dragADropImageView]setImage:[self resourceImageForFileName:@"dadDefault.png"]];
    }
    else if([event isEqualToString:@"DROP_DROPPED"])
    {
        [[self dragADropImageView]setImage:[self resourceImageForFileName:@"dadDefault.png"]];
    }
    else if([event isEqualToString:@"CONVERT_STARTED"])
    {
        [[self openButton]setEnabled:NO];
        [[self cancelButton]setEnabled:YES];
        [[self progressLabel]setHidden:NO];
        [[self progressPercentLabel]setHidden:NO];
        [[self progressPercentLabel]setStringValue:@"0%"];
        [[self convertStatusLabel]setStringValue:@"Converting"];
        [[self convertStatusIcon]setImage:[self resourceImageForFileName:@"converting.png"]];
        [[self dragADropImageView]setDragAndDropEnabled:NO];
        [[self dragADropImageView]setImage:[self resourceImageForFileName:@"dadConverting.gif"]];
        
        // Show DockTile
        [progressDockIndicator setHidden:NO];
        [dockTile display];
    }
    else if([event isEqualToString:@"CONVERT_ENDED"])
    {
        [[self openButton]setEnabled:YES];
        [[self cancelButton]setEnabled:NO];
        [[self progressLabel]setHidden:YES];
        [[self progressPercentLabel]setHidden:YES];
        [[self progressPercentLabel]setStringValue:@"0%"];
        [[self progressIndicator]setDoubleValue:0.0];
        [[self dragADropImageView]setDragAndDropEnabled:YES];
        [[self dragADropImageView]setImage:[self resourceImageForFileName:@"dadDefault.png"]];
        
        // Show DockTile
        [progressDockIndicator setHidden:YES];
        [dockTile display];
        
        // Set Status Label And Icon
        NSString* statusLabel;
        NSImage*  statusIcon;
        if([[csoManager finishStatus]isEqualToString:@"SUCCESS"])
        {
            statusLabel = @"Converted";
            statusIcon = [self resourceImageForFileName:@"success.png"];
        }
        else if([[csoManager finishStatus]isEqualToString:@"ERROR"])
        {
            statusLabel = @"Error";
            statusIcon = [self resourceImageForFileName:@"error.png"];
        }
        else if([[csoManager finishStatus]isEqualToString:@"CANCEL"])
        {
            statusLabel = @"Canceled";
            statusIcon = [self resourceImageForFileName:@"error.png"];
        }
        
        [[self convertStatusLabel]setStringValue:statusLabel];
        [[self convertStatusIcon]setImage:statusIcon];
        

    }
    else if([event isEqualToString:@"PANEL_OPENED"])
    {
        [[self dragADropImageView]setDragAndDropEnabled:NO];
        [[self openButton]setEnabled:NO];
        [[self exitButton]setEnabled:NO];
        
    }
    else if([event isEqualToString:@"PANEL_CLOSED"])
    {
        [[self dragADropImageView]setDragAndDropEnabled:YES];
        [[self openButton]setEnabled:YES];
        [[self exitButton]setEnabled:YES];
    }
    else
        NSLog(@"Error: Unknown Event");
    
}
- (void)updateViewPercent:(NSNumber*) percent{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateViewPercent:) withObject:percent waitUntilDone:NO];
        return;
    }
    [[self progressPercentLabel]setStringValue:[NSString stringWithFormat:@"%@%%",percent]];
    [[self progressIndicator]setDoubleValue:[percent doubleValue]];
    [progressDockIndicator setDoubleValue:[percent doubleValue]];
    [dockTile display];
    
}

#pragma mark - Help Methods

- (NSString*)openPanel{
    
    NSString *openPath;
    [self updateViewForEvent:@"PANEL_OPENED"];
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    NSArray *fileTypes = @[@"iso",@"cso",@"ciso"];
    [openPanel setAllowedFileTypes:fileTypes];
    
    
    if([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL * urlPath = [[openPanel URLs]objectAtIndex:0];
        openPath = [urlPath path];
    }

    
    [self updateViewForEvent:@"PANEL_CLOSED"];
    return openPath;
}
- (NSString*)savePanelForFile:(NSString*) filePath{
    
    NSString *savePath;
    [self performSelectorOnMainThread:@selector(updateViewForEvent:) withObject:@"PANEL_OPENED" waitUntilDone:YES];
    
    //NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setExtensionHidden:NO];
    [sPanel setCanSelectHiddenExtension:YES];
    // Set Panel Title
    [sPanel setTitle:@"Choose Save Path For Converted Image"];
    
    // Set Default Name
    // getName, check Extension And Change It
    NSArray *pathComponents = [filePath pathComponents];
    NSString* name =[[pathComponents objectAtIndex:[pathComponents count]-1]stringByDeletingPathExtension];
    NSString *fileName;

    if([[filePath pathExtension]caseInsensitiveCompare:@"iso"] == NSOrderedSame)
    {
        [sPanel setAllowedFileTypes:@[@"cso",@"ciso"]];
        fileName = [name stringByAppendingString:@".cso"];
        
        // Set Compress View
        [sPanel setAccessoryView:[self accessoryView]];
    }
    else if([[filePath pathExtension]caseInsensitiveCompare:@"cso"] == NSOrderedSame ||
            [[filePath pathExtension]caseInsensitiveCompare:@"ciso"] == NSOrderedSame)
    {
        [sPanel setAllowedFileTypes:@[@"iso"]];
        fileName = [name stringByAppendingString:@".iso"];
        
        // Set Compress View
        [sPanel setAccessoryView:nil];
    }
    
    if(fileName)
    {
        [sPanel setNameFieldStringValue:fileName];
        if([sPanel runModal] == NSFileHandlingPanelOKButton)
        {
            NSURL *urlPath = [sPanel URL];
            savePath = [urlPath path];
        }
    }

    
    [self updateViewForEvent:@"PANEL_CLOSED"];
    return savePath;
}

- (void) deleteSemiCompleteFile{
    if([[NSFileManager defaultManager]fileExistsAtPath:[csoManager convertedFile]])
    {
        [[NSFileManager defaultManager]removeItemAtPath:[csoManager convertedFile] error:nil];
    }
}

- (void) sendNotification{
    NSUserNotification *notifitation = [[NSUserNotification alloc]init];
    
    // Get File Name Without Extension
    NSString *fileName = [csoManager sourceFile];
    fileName = [[[fileName pathComponents]lastObject]stringByDeletingPathExtension];
    
    // Set Notification Message
    [notifitation setTitle:@"PSP CSO Converter"];
    if([[csoManager finishStatus]isEqualToString:@"SUCCESS"])
    {
        [notifitation setSubtitle:@"Operation Was Successful"];
        [notifitation setInformativeText:[NSString stringWithFormat:@"\"%@\" File Converted",fileName]];
    }
    else if([[csoManager finishStatus]isEqualToString:@"ERROR"])
    {
        [notifitation setSubtitle:@"Operation Produced Error"];
        [notifitation setInformativeText:[NSString stringWithFormat:@"\"%@\" File Was Not Converted",fileName]];
    }
    else if([[csoManager finishStatus]isEqualToString:@"CANCEL"])
    {
        [notifitation setSubtitle:@"Operation Canceled"];
        [notifitation setInformativeText:[NSString stringWithFormat:@"\"%@\" File Was Not Converted",fileName]];
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter]deliverNotification:notifitation];
}

- (NSString*)resourcePathForFileName:(NSString*) fileName{
    return [[NSBundle mainBundle]pathForImageResource:fileName];
}
- (NSImage*) resourceImageForFileName:(NSString*) fileName{
    return [[NSImage alloc]initWithContentsOfFile:[self resourcePathForFileName:fileName]];
}

#pragma mark - IBActions
- (IBAction)openPressed:(id)sender {
    
    if(![csoManager isConverting])
    {
        NSString* openFile = [self openPanel];
        if(openFile)
        {
            [self performSelectorInBackground:@selector(convertFile:) withObject:openFile];
        }
    }
}
- (IBAction)cancelPressed:(id)sender {
    [csoManager cancelConvert];
}
- (IBAction)exitPressed:(id)sender {
    [[NSApplication sharedApplication]terminate:self];
}

#pragma mark - Drag And Drop Delegate

- (void) fileDropped:(NSString*) filePath in:(NSDaDFileImageView*) sender{
    
    // Check If File Path Is CSO,CISO,ISO
    if([[filePath pathExtension]caseInsensitiveCompare:@"iso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"cso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"ciso"] == NSOrderedSame )
    {
        [self updateViewForEvent:@"DROP_DROPPED"];
        [self performSelectorInBackground:@selector(convertFile:) withObject:filePath];
    }
}
- (void) fileEntered:(NSString*) filePath in:(NSDaDFileImageView*) sender{
    
    // Check If File Path Is CSO,CISO,ISO
    if([[filePath pathExtension]caseInsensitiveCompare:@"iso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"cso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"ciso"] == NSOrderedSame )
    {
            [self updateViewForEvent:@"DROP_ENTERED"];
    }
}
- (void) fileExited: (NSString*) filePath in:(NSDaDFileImageView*) sender{

    // Check If File Path Is CSO,CISO,ISO
    if([[filePath pathExtension]caseInsensitiveCompare:@"iso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"cso"] == NSOrderedSame ||
       [[filePath pathExtension]caseInsensitiveCompare:@"ciso"] == NSOrderedSame )
    {
        [self updateViewForEvent:@"DROP_EXITED"];
    }
}

#pragma mark - Convert Delegate

- (void)percentCompleted:(NSNumber*)percent{
    [self updateViewPercent:percent];
}
- (void)convertStarted:(id)sender{
    
}
- (void)convertEnded:(id)sender{
    
    if([[csoManager finishStatus]isEqualToString:@"CANCEL"] ||
       [[csoManager finishStatus]isEqualToString:@"ERROR"])
    {
        [self deleteSemiCompleteFile];
    }

    // Write To Error Log
    if([[csoManager finishStatus]isEqualToString:@"ERROR"]){
        
        NSString *errorLog = [NSString stringWithFormat:@"Error: %@ \nDescription: %@",[csoManager errorStatus],[csoManager errorDescription]];
        [errorLog writeToFile:[self resourcePathForFileName:@"error.log"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    
    // Send Notification
    [self sendNotification];
    
    // Play Sound
    [finishSound play];
}

@end
