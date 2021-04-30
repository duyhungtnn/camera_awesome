//
//  ImageStreamController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "ImageStreamController.h"

@implementation ImageStreamController
{
    dispatch_queue_t _compressQueue;
    int frameDrop;
}

- (instancetype)initWithEventSink:(FlutterEventSink)imageStreamEventSink {
    self = [super init];
    _imageStreamEventSink = imageStreamEventSink;
    _streamImages = imageStreamEventSink != nil;
    _compressQueue = dispatch_queue_create("dispatch_queue_awesome_camera_on_fly_compress",
                                           DISPATCH_QUEUE_SERIAL);
    return self;
}

# pragma mark - Camera Delegates
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // Retain sample buffer and lock base address
    CFRetain(sampleBuffer);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
//    const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
//    size_t planeCount;
//    if (isPlanar) {
//        planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
//    } else {
//        planeCount = 1;
//    }
//
//    FlutterStandardTypedData *data;
//    for (int i = 0; i < planeCount; i++) {
//        void *planeAddress;
//        size_t bytesPerRow;
//        size_t height;
//        size_t width;
//
//        if (isPlanar) {
//            planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
//            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
//            height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
//            width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
//        } else {
//            planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
//            bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
//            height = CVPixelBufferGetHeight(pixelBuffer);
//            width = CVPixelBufferGetWidth(pixelBuffer);
//        }
//
//        NSNumber *length = @(bytesPerRow * height);
//        NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];
//        data = [FlutterStandardTypedData typedDataWithBytes:bytes];
//    }
    
    __weak typeof(self) _weakSelf = self;
    if (self->frameDrop % 2 != 0){
        self->frameDrop += 1;
        return;
   }
        
    dispatch_async(_compressQueue, ^{
        if (_weakSelf == nil) {
            return;
        }
       
        CIImage * ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        UIImage * image = [[UIImage alloc] initWithCIImage:ciImage];
        NSData* imageData = UIImageJPEGRepresentation(image, 0.3);
        // Only send bytes for now
        FlutterStandardTypedData *data;
        data = [FlutterStandardTypedData typedDataWithBytes:imageData];
        _weakSelf.imageStreamEventSink(data);
        NSLog(@"Finish OnFlyCompress");
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CFRelease(sampleBuffer);
    });
    
}

@end
