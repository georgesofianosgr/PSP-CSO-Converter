//
//  CSODecompressor.h
//  CSO_Manager
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSO_Header.h"

@protocol CSODecompressorDelegate;

@interface CSODecompressor : NSObject{
    NSDictionary *_errorString;
    BOOL _convertCanceled;
}
@property id <CSODecompressorDelegate> delegate;
@property (readonly) BOOL       isConverting;
@property (readonly) BOOL       didFinish;
@property (readonly) NSString*  finishStatus; // Values: SUCCESS,ERROR,CANCEL
@property (readonly) NSString*  errorStatus;
@property (readonly) NSString*  sourceFile;
@property (readonly) NSString*  convertedFile;

// Main Method For Converting CSO To ISO. Returns finishStatus.
- (NSString*) convertCSO:(NSString*)csoPath toPath:(NSString*)saveFilePath;
// If Converting Cancels The Operation
- (void)cancelConvert;
// Describes The Error That Occured
- (NSString*) errorDescription;

@end


@protocol CSODecompressorDelegate <NSObject>
@optional
- (void)percentCompleted:(NSNumber*)percent;
- (void)operationStarted:(id)sender;
- (void)operationEnded:(id)sender;

@end
