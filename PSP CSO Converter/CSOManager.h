//
//  CSOManager.h
//  CSO_Manager
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//
/*
    CSO Manager is made for converting psp images from iso to cso and backwards.
    Class user must implement the delegate to get info of when operation started, ended and percent completed.
    To check if operation was successfull after operation end read message finishStatus
 
 */
#import <Foundation/Foundation.h>

#import "CSODecompressor.h"
#import "CSOCompressor.h"
@protocol CSOManagerDelegate;

@interface CSOManager : NSObject <CSOCompressorDelegate,CSODecompressorDelegate>{
    CSODecompressor *decompressor;
    CSOCompressor *compressor;
    
    BOOL _convertCanceled;
}
@property id <CSOManagerDelegate> delegate;
@property (readonly) BOOL       isConverting;
@property (readonly) BOOL       didFinish;
@property (readonly) NSNumber*  compressLevel;
@property (readonly) NSString*  finishStatus; // Values: SUCCESS,ERROR,CANCEL
@property (readonly) NSString*  errorStatus;
@property (readonly) NSString*  sourceFile;
@property (readonly) NSString*  convertedFile;
@property (readonly) NSString*  convertType; // CSO-ISO or ISO-CSO


// Main Method For Converting Images
- (NSString*) compressISO:(NSString*)isoPath toPath:(NSString*)saveFilePath withCompressLevel:(NSNumber*)level;
- (NSString*) decompressCSO:(NSString*) csoPath toPath:(NSString*)saveFilePath;

// If Converting Cancels The Operation
- (void)cancelConvert;
// Describes The Error That Occured
- (NSString*) errorDescription;

@end


@protocol CSOManagerDelegate <NSObject>
@optional
- (void)percentCompleted:(NSNumber*)percent;
- (void)convertStarted:(id)sender;
- (void)convertEnded:(id)sender;

@end
