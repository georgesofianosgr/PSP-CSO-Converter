//
//  CSOCompressor.h
//  CSO_Manager
//
//  Created by George Sofianos on 4/7/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSO_Header.h"

@protocol CSOCompressorDelegate;

@interface CSOCompressor : NSObject{
    NSDictionary *_errorString;
    BOOL _convertCanceled;
}
@property id <CSOCompressorDelegate> delegate;
@property (readonly) BOOL       isConverting;
@property (readonly) BOOL       didFinish;
@property (readonly) NSNumber*  compressLevel;
@property (readonly) NSString*  finishStatus; // Values: SUCCESS,ERROR,CANCEL
@property (readonly) NSString*  errorStatus;
@property (readonly) NSString*  sourceFile;
@property (readonly) NSString*  convertedFile;

// Main Method For Converting ISO To CSO. Returns finishStatus. Default Level Is 6 for wrong input
- (NSString*) convertISO:(NSString*)isoPath toPath:(NSString*)saveFilePath withCompressLevel:(NSNumber*)level;
// If Converting Cancels The Operation
- (void)cancelConvert;
// Describes The Error That Occured
- (NSString*) errorDescription;

@end


@protocol CSOCompressorDelegate <NSObject>
@optional
- (void)percentCompleted:(NSNumber*)percent;
- (void)operationStarted:(id)sender;
- (void)operationEnded:(id)sender;

@end
