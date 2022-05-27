//
//  File.c
//  
//
//  Created by Tobias Haeberle on 27.07.21.
//

#include "ClibrawShim.h"
#include <libraw/libraw.h>


unsigned char * shim_libraw_processed_image_get_data(libraw_processed_image_t * image) {
    return image->data;
}
