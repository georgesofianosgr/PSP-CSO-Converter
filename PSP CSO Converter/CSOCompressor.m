//
//  CSOCompressor.m
//  CSO_Manager
//
//  Created by George Sofianos on 4/7/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#import "CSOCompressor.h"
#import <zlib.h>           
#import <zconf.h>

@implementation CSOCompressor

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

- (NSString*)convertISO:(NSString *)isoPath toPath:(NSString *)saveFilePath withCompressLevel:(NSNumber *)level{
    // Set Default Values
    [self setStartValuesForFile:isoPath withSaveFilePath:saveFilePath andCompresslevel:level];
    
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
    
    // Header Of CSO Image
    CSO_H header;
    
    // Variables For Convert Operation
    int indexSize;
	int cmpSize;
	int status;
    unsigned char buf4[64];
    
    // Get File Size
    NSDictionary *atributes = [[NSFileManager defaultManager]attributesOfItemAtPath:[self sourceFile] error:NULL];
    NSNumber *fileSize = [atributes valueForKey:@"NSFileSize"];
    
    if(fileSize == Nil){
        _errorStatus = @"ERROR_OPEN_READFILE";
        return;
    }
        
    
    // Create Header
    memset(&header, 0, sizeof(header));
    header.magic[0] = 'C';
	header.magic[1] = 'I';
	header.magic[2] = 'S';
	header.magic[3] = 'O';
	header.version  = 0x01;
    header.blockSize  = 0x800; /* ISO9660 one of sector */
	header.totalBytes = [fileSize unsignedIntegerValue];
    
    // Calculate Total Blocks To Write
    NSUInteger totalBlocks = (NSUInteger)header.totalBytes / header.blockSize;
    
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
    
    
    // Create Buffers
    
    indexSize = (int)(totalBlocks +1)*4;
    unsigned int* indexBuffer = malloc(indexSize);
    unsigned int* crcBuffer = malloc(indexSize);
    unsigned char* readBuffer = malloc(header.blockSize);
    unsigned char* writeBuffer = malloc(header.blockSize*2);
    
    
    if( !indexBuffer || !crcBuffer || !readBuffer || !writeBuffer )
    {
        _errorStatus = @"ERROR_ALLOCATE_MEMORY";
        if(indexBuffer)
            free(indexBuffer);
        if(crcBuffer)
            free(crcBuffer);
        if(readBuffer)
            free(readBuffer);
        if(writeBuffer)
            free(writeBuffer);
        
        fclose(fileRead);
        fclose(fileWrite);
        
        return;
    }
    
    
    
    memset(indexBuffer,0,indexSize);
    memset(crcBuffer,0,indexSize);
    memset(buf4,0,sizeof(buf4));
        
    // Initialize ZLib
    z_stream zStream;
    zStream.zalloc = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.zfree = Z_NULL;
        
    // Show Debug Info
    /*
    printf("Total File Size %ld bytes\n",header.totalBytes);
    printf("block size      %d  bytes\n",header.blockSize);
    printf("index align     %d\n",1<<header.align);
    printf("compress level  %d\n",compLevel);
    */
    
    // Write Header And A Temp Index
    if(fwrite(&header,1,sizeof(header),fileWrite) != sizeof(header) ||
       fwrite(indexBuffer,1,indexSize,fileWrite) != indexSize){
        
        _errorStatus = @"ERROR_WRITE_FILE";
        if(indexBuffer)
            free(indexBuffer);
        if(crcBuffer)
            free(crcBuffer);
        if(readBuffer)
            free(readBuffer);
        if(writeBuffer)
            free(writeBuffer);
        
        fclose(fileRead);
        fclose(fileWrite);
        
        return;
    }
        
    // Set Write Position to Header Bytes + Index Bytes
    unsigned long  writePosition = sizeof(header)+indexSize;
        
    NSInteger totalPercent = (NSInteger)(totalBlocks /100) ;
    NSInteger currentPercent = (NSInteger)(totalBlocks /100);
        
    // Align
    int align,align_b,align_m;
    align_b = 1<<(header.align);
    align_m = align_b -1;
        
    // Write Every Block
    int block;
    for(block=0;block < totalBlocks; block++)
    {
        // Update Percentage By Delegate
        if(--currentPercent<=0)
        {
            currentPercent = totalPercent;
            if([[self delegate] respondsToSelector:@selector(percentCompleted:)])
            {
                    // Call Method
                [[self delegate]percentCompleted:[NSNumber numberWithInt:block / totalPercent]];
            }
        }
            
        if(_convertCanceled)
            break;
            
        // Initialize Zlib
        if (deflateInit2(&zStream, [[self compressLevel]intValue] , Z_DEFLATED, -15,8,Z_DEFAULT_STRATEGY) != Z_OK)
        {
            _errorStatus = @"ERROR_ZLIB_INIT";
            break;
        }
            
        // write align
        align = (int)writePosition & align_m;
        if(align)
        {
            align = align_b - align;
            if(fwrite(buf4,1,align, fileWrite) != align)
            {
                _errorStatus = @"ERROR_WRITE_FILE";
                break;
            }
            writePosition += align;
        }
            
        // mark offset index
        indexBuffer[block] = (unsigned int)writePosition>>(header.align);
            
        // read buffer
        zStream.next_out  = writeBuffer;
        zStream.avail_out = header.blockSize*2;
        zStream.next_in   = readBuffer;
        zStream.avail_in  = (unsigned int)fread(readBuffer, 1, header.blockSize , fileRead);
        if(zStream.avail_in != header.blockSize)
        {
            _errorStatus = @"ERROR_READ_FILE";
            break;
        }
            
        // compress block
        status = deflate(&zStream, Z_FINISH);
        if (status != Z_STREAM_END)
        {
            _errorStatus = @"ERROR_ZLIB_DEFLATE";
            deflateEnd(&zStream);
            break;
        }
            
        cmpSize = header.blockSize*2 - zStream.avail_out;
            
        // choise plain / compress
        if(cmpSize >= header.blockSize)
        {
            cmpSize = header.blockSize;
            memcpy(writeBuffer,readBuffer,cmpSize);
            // plain block mark 
            indexBuffer[block] |= 0x80000000;
        }
            
        // write compressed block
        if(fwrite(writeBuffer, 1,cmpSize , fileWrite) != cmpSize)
        {
            _errorStatus = @"ERROR_WRITE_FILE";
            deflateEnd(&zStream);
            break;
        }
            
        // mark next index
        writePosition += cmpSize;
            
        // Terminate Deflate
        if (deflateEnd(&zStream) != Z_OK)
        {
            _errorStatus =@"ERROR_ZLIB_FINISH_DEFLATE";
            break;
        }
    }
    
    if([[self errorStatus]isEqualToString:@"ERROR_NULL"])
    {
        // last position (total size)
        indexBuffer[block] = (unsigned int)writePosition>>(header.align);
            
        // write header & index block 
        fseek(fileWrite,sizeof(header),SEEK_SET);
        if(fwrite(indexBuffer,1,indexSize,fileWrite)!= indexSize)
        {
            _errorStatus = @"ERROR_WRITE_FILE";
        }
    }
        
    // Close Files
    fclose(fileRead);
    fclose(fileWrite);
    
    // Free Buffers
    if(readBuffer)
        free(readBuffer);
    if(writeBuffer)
        free(writeBuffer);
    if(indexBuffer)
        free(indexBuffer);
    if(crcBuffer)
        free(crcBuffer);
    
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
              withSaveFilePath:(NSString*) saveFilePath
              andCompresslevel:(NSNumber*) level{
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
}

@end
