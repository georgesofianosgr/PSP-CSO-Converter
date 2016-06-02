//
//  CSODecompressor.m
//  CSO_Manager
//
//  Created by George Sofianos on 4/8/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import "CSODecompressor.h"
#import <zlib.h>
#import <zconf.h>

@implementation CSODecompressor
- (id)init{
    
    self = [super init];
    if(self)
    {
        _isConverting = NO;
        _didFinish = YES;
        _finishStatus = @"SUCCESS";
        _errorStatus = @"ERROR_NULL";
        _sourceFile = @"";
        _convertedFile = @"";
        
        _errorString = @{@"ERROR_OPEN_READFILE": @"Couldn't Open Source File",
                         @"ERROR_OPEN_WRITEFILE":@"Couldn't Open Destination File",
                         @"ERROR_ALLOCATE_MEMORY":@"Couldn't Allocate Memory",
                         @"ERROR_ZLIB_INIT":@"Couldn't Initialize ZLib",
                         @"ERROR_READ_FILE":@"Couldn't Read File",
                         @"ERROR_WRITE_FILE":@"Couldn't Write File",
                         @"ERROR_ZLIB_INFLATE":@"Couldn't Perform Inflate From ZLib",
                         @"ERROR_ZLIB_DEFLATE":@"Couldn't Perform Deflate From ZLib",
                         @"ERROR_ZLIB_FINISH_INFLATE":@"Couldn't End Inflate Of ZLib",
                         @"ERROR_ZLIB_FINISH_DEFLATE":@"Couldn't End Deflate Of ZLib",
                         @"ERROR_NULL":@"No Error Occured"};
    }
    return self;
}

- (NSString*)convertCSO:(NSString *)csoPath toPath:(NSString *)saveFilePath{
    // Set Default Values
    [self setStartValuesForFile:csoPath withSaveFilePath:saveFilePath];
    
    // Inform Delegate About Starting
    if([[self delegate]respondsToSelector:@selector(operationStarted:)])
        [[self delegate]operationStarted:self];
    
    // Convert
    [self performConvert];
    
    // Inform Delegate About Ended
    if([[self delegate]respondsToSelector:@selector(operationEnded:)])
        [[self delegate]operationEnded:self];
    
    return [self finishStatus];
}
- (void)cancelConvert{
    if([self isConverting])
        _convertCanceled = YES;
}
- (NSString*)errorDescription{
    return [_errorString valueForKey:[self errorStatus]];
}

#pragma mark - Private Methods

- (void) performConvert{
    
    
    CSO_H header;
    
    // Read First 24 Bytes
    NSInputStream *inStream = [NSInputStream inputStreamWithFileAtPath:[self sourceFile]];
    [inStream open];
    if([inStream read:(unsigned char*)&header maxLength:24] != 24)
    {
        //set error
        _errorStatus = @"ERROR_READ_FILE";
        [inStream close];
        return;
    }
    [inStream close];
    
    
    // DEBUG - Print Header Info
    /*
     NSLog(@"Magic: %c%c%c%c",header.magic[0],header.magic[1],header.magic[2],header.magic[3]); // MAGIC
     NSLog(@"Header Size: %d",header.headerSize); // Header Size (Usually Is 0) Real Header Size is 24 bytes
     NSLog(@"Total Bytes: %ld",header.totalBytes); // Total Bytes
     NSLog(@"Block Size: %d",header.blockSize); // Block Size (Must Be 2048)
     NSLog(@"Total Blocks: %ld",(unsigned long)[self totalBlocks]); // Total Blocks For Reading
     NSLog(@"Version: %d",header.version); // Version (Must Be 1)
     NSLog(@"Align: %d",header.align); // Align
     */
    
    // Get Index Data
    NSData *indexData;
    NSUInteger totalBlocks = (NSUInteger)header.totalBytes / header.blockSize;
    NSUInteger indexSize = (totalBlocks+1) * 4;
    
    // IndexData Start From 25Byte Until Size+25
    inStream = [NSInputStream inputStreamWithFileAtPath:[self sourceFile]];
    [inStream open];
    
    // Check if can read
    if([inStream hasBytesAvailable])
    {
        // Create A Temp Buffer For Storing Index Data
        unsigned char* buffer = malloc(indexSize+24);
        if(!buffer)
        {
            _errorStatus = @"ERROR_ALLOCATE_MEMORY";
            [inStream close];
            return;
        }
        
        // Get File Buffer
        [inStream read:buffer maxLength:indexSize+24];
        
        // Skip 24 Header Bytes
        unsigned char* indexBuffer = buffer+24;
        
        // Read Data From 25 Byte To The End Of Index Size
        indexData = [NSData dataWithBytes:indexBuffer length:indexSize];
        

        free(buffer);
        [inStream close];
        
        if([indexData length] != indexSize)
        {
            _errorStatus = @"ERROR_READ_FILE";
            return;
        }
    }
    else{
        _errorStatus = @"ERROR_READ_FILE";
        [inStream close];
        return;
    }
    
    // Start Main Decompression
    
    // Open Files
    FILE *fileRead = fopen([[self sourceFile]UTF8String], "rb");
    FILE *fileWrite = fopen([[self convertedFile] UTF8String], "wb");
    
    if (!fileRead)
    {
        _errorStatus = @"ERROR_OPEN_READFILE";
        return;
    }
    else if(!fileWrite)
    {
        _errorStatus = @"ERROR_OPEN_WRITEFILE";
        return;
    }
    
    // Allocate Buffers
    int index;
    unsigned int* indexBuffer = (unsigned int*)[indexData bytes];
    unsigned char* readBuffer = malloc(header.blockSize);
    unsigned char* writeBuffer = malloc(header.blockSize*2);
    
    if( !indexBuffer || !readBuffer || !writeBuffer )
    {
        _errorStatus = @"ERROR_ALLOCATE_MEMORY";


        free(readBuffer);
        free(writeBuffer);
        
        fclose(fileRead);
        fclose(fileWrite);
        
        return;
    }
    
    
    // Init Zlib Stream
    z_stream zStream;
    zStream.zalloc = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.zfree = Z_NULL;
    
    // Percentage, Will Be Implemented As Delage
    NSInteger totalPercent = (NSInteger)(totalBlocks /100) ;
    NSInteger currentPercent = 0;
    
    // Read Write Every Block
    for(int block=0; block<totalBlocks; block++)
    {
        // Update Progress Delegate
        if(--currentPercent<=0)
		{
			currentPercent = totalPercent;
			//NSLog(@"decompress %ld %%",block / totalPercent);
            
            // Check if delegate's method exist
            if([self.delegate respondsToSelector:@selector(percentCompleted:)])
            {
                // Call Method
                [[self delegate]percentCompleted:[NSNumber numberWithInt:block / totalPercent]];
            }
            
		}
        
        // Check Cancel
        if(_convertCanceled)
        {
            break;
        }
        
        int readSize;
        // Initialize Zlib
        if(inflateInit2(&zStream, -15) != Z_OK)
        {
            _errorStatus = @"ERROR_ZLIB_INIT";
            break;
        }
        
        // Some Initialization
        index = (unsigned int)indexBuffer[block];  // Get Current Index
        int plain = index & 0x80000000;            // Check If Blocks Is Plain Or Not
        index &= 0x7fffffff;                       // Do This For Unkown Reason
        int readPos = index << header.align;       // Set ReadPosition
        
        // Change readSize based on plain status
        if(plain)
        {
            readSize = header.blockSize;
        }
        else
        {
            int nextIndex = indexBuffer[block+1] & 0x7fffffff;
            
            readSize = (nextIndex - index) << header.align;
        }
        fseek(fileRead, readPos, SEEK_SET);
        
        
        // Save Block To ReadBuffer
		zStream.avail_in  = (unsigned int)fread(readBuffer, 1, readSize , fileRead);
		if(zStream.avail_in != readSize)
		{
            _errorStatus = @"ERROR_READ_FILE";
            break;
		}
        
        // Pass Block For Write Or Decompress With ZLib
        int writeSize = 0; // Size Of Data To Write
        if(plain)
		{
			memcpy(writeBuffer,readBuffer,readSize);
			writeSize = readSize;
		}
		else
		{
			zStream.next_out  = writeBuffer;
			zStream.avail_out = header.blockSize;
			zStream.next_in   = readBuffer;
			int status = inflate(&zStream, Z_FULL_FLUSH);
			if (status != Z_STREAM_END)
			{
                _errorStatus = @"ERROR_ZLIB_INFLATE";
                inflateEnd(&zStream);
                break;
			}
			writeSize = header.blockSize - zStream.avail_out;
			if(writeSize != header.blockSize)
			{
                _errorStatus = @"ERROR_WRITE_FILE";
                inflateEnd(&zStream);
                break;
			}
		}
        
		// write decompressed block
		if(fwrite(writeBuffer, 1,writeSize , fileWrite) != writeSize)
		{
            _errorStatus = @"ERROR_WRITE_FILE";
            inflateEnd(&zStream);
            break;
		}
        
        
        // Shutdown ZLib
        if(inflateEnd(&zStream) != Z_OK)
        {
            _errorStatus = @"ERROR_ZLIB_FINISH_INFLATE";
            break;
        }
    }

    
    // Close Files
    fclose(fileRead);
    fclose(fileWrite);
    
    // Free Read And Write Buffer
    free(readBuffer);
    free(writeBuffer);
    
    // Set Finish Values
    _didFinish = YES;
    _isConverting = NO;
    
    if(_convertCanceled)
        _finishStatus = @"CANCEL";
    else if(![[self errorStatus]isEqualToString:@"ERROR_NULL"])
        _finishStatus = @"ERROR";
    else
        _finishStatus = @"SUCCESS";

}
- (void) setStartValuesForFile:(NSString*) filePath
              withSaveFilePath:(NSString*) saveFilePath{
    _isConverting = YES;
    _didFinish = NO;
    _errorStatus = @"ERROR_NULL";
    _sourceFile = filePath;
    _convertedFile = saveFilePath;
    _convertCanceled = NO;
}

@end
