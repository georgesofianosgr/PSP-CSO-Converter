//
//  CSOManager.m
//  CSO_Manager
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import "CSOManager.h"

@implementation CSOManager
- (id)init{
    
    self = [super init];
    if(self)
    {
        _isConverting = NO;
        _didFinish = YES;
        _compressLevel = @0;
        _finishStatus = @"SUCCESS";
        _errorStatus = @"ERROR_NULL";
        _sourceFile = @"";
        _convertedFile = @"";
        _convertType = @"ISO-CSO";
        
        compressor = [[CSOCompressor alloc]init];
        decompressor = [[CSODecompressor alloc]init];
        
        [compressor setDelegate:self];
        [decompressor setDelegate:self];
        
    }
    return self;
}

- (NSString*) compressISO:(NSString*)isoPath toPath:(NSString*)saveFilePath withCompressLevel:(NSNumber*)level{
    // Set Default Values
    [self setStartValuesForFile:isoPath withSaveFilePath:saveFilePath andCompresslevel:level andType:@"ISO-CSO"];
    
    // Inform Delegate About Starting
    if([[self delegate]respondsToSelector:@selector(convertStarted:)])
        [[self delegate]convertStarted:self];
    
    // Convert
    [compressor convertISO:isoPath toPath:saveFilePath withCompressLevel:level];
    
    _errorStatus = [compressor errorStatus];
    _finishStatus = [compressor finishStatus];
    _isConverting = NO;
    _didFinish = YES;
    
    // Inform Delegate About Ended
    if([[self delegate]respondsToSelector:@selector(convertEnded:)])
        [[self delegate]convertEnded:self];
    
    
    return [compressor finishStatus];
}

- (NSString*) decompressCSO:(NSString*) csoPath toPath:(NSString*)saveFilePath{
    // Set Default Values
    [self setStartValuesForFile:csoPath withSaveFilePath:saveFilePath andCompresslevel:nil andType:@"CSO-ISO"];
    
    // Inform Delegate About Starting
    if([[self delegate]respondsToSelector:@selector(convertStarted:)])
        [[self delegate]convertStarted:self];
    
    // Convert
    [decompressor convertCSO:csoPath toPath:saveFilePath];
    
    _errorStatus = [decompressor errorStatus];
    _finishStatus = [decompressor finishStatus];
    _isConverting = NO;
    _didFinish = YES;
    
    // Inform Delegate About Ended
    if([[self delegate]respondsToSelector:@selector(convertEnded:)])
        [[self delegate]convertEnded:self];
    
    return [decompressor finishStatus];
}

- (void)cancelConvert{
    if([[self convertType]isEqualToString:@"ISO-CSO"])
        return [compressor cancelConvert];
    else
        return [decompressor cancelConvert];
}
- (NSString*)errorDescription{
    if([[self convertType]isEqualToString:@"ISO-CSO"])
        return [compressor errorDescription];
    else
        return [decompressor errorDescription];
}


- (void) setStartValuesForFile:(NSString*) filePath
              withSaveFilePath:(NSString*) saveFilePath
              andCompresslevel:(NSNumber*) level
                       andType:(NSString*) type {
    _isConverting = YES;
    _didFinish = NO;
    _errorStatus = @"ERROR_NULL";
    _sourceFile = filePath;
    _convertedFile = saveFilePath;
    _convertCanceled = NO;
    if([level intValue] >= -1 && [level intValue] <= 9)
        _compressLevel = level;
    else
        _compressLevel = @6;
    
    _convertType = type;
}

- (void)percentCompleted:(NSNumber*)percent{
    if([[self delegate]respondsToSelector:@selector(percentCompleted:)])
       [[self delegate]percentCompleted:percent];
}

- (void)operationEnded:(id)sender{
    
}

-(void)operationStarted:(id)sender{
    
}
@end
