//
//  ClibrawShim.h
//  
//
//  Created by Tobias Haeberle on 27.07.21.
//

#ifndef ClibrawShim_h
#define ClibrawShim_h

#include <libraw/libraw.h>


unsigned char * shim_libraw_processed_image_get_data(libraw_processed_image_t * image);

#endif /* ClibrawShim_h */
