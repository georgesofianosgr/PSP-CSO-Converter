//
//  CSO_Header.h
//  CSO_Manager
//
//  Created by George Sofianos on 4/7/13.
//  Copyright (c) 2013 Dream Development. All rights reserved.
//

#ifndef CSO_Manager_CSO_Header_h
#define CSO_Manager_CSO_Header_h

typedef struct CSO_Header
{
	unsigned char   magic[4];		// 4 Bytes For Chars : C,I,S,O
	unsigned int    headerSize;		// 4 Bytes (size = 0x18 , 2048 bytes)
	unsigned long   totalBytes;     // 8 Bytes , Original Size
	unsigned int    blockSize;		// 4 Bytes , Block Size (Must Be 24KB , 0x00080000)
	unsigned char   version;		// 1 Byte  , Version must be 01
	unsigned char   align;			// 1 Byte  , align of index value , Usually 0
	unsigned char   reserved[2];	// 2 Byte  , Value For Each = 0
    // Total Header Bytes: 24
}CSO_H;

#endif
