//
//  JHDisplayLink.m
//  CocoaUtils
//
//  Created by Nick Hutchinson on 01/05/2013.
//
//

#import "JHDisplayLink.h"

#include <QuartzCore/CVDisplayLink.h>

#if OS_OBJECT_USE_OBJC_RETAIN_RELEASE
static void
JHDispatchRelease(__strong dispatch_object_t *var) {
    *var = nil;
}

#else

static void
JHDispatchRelease(dispatch_object_t *var) {
    dispatch_release(*var);
    *var = NULL;
}
#endif

typedef enum : unsigned {
    // We don't want to naively schedule the callback from the displaylink
    // thread, because this will likely happen faster than the main thread
    // can process it. Instead, we try to only schedule the callback if the
    // callback isn't already executing.
    kJHDisplayLinkIsRendering = 1u << 0
} JHDisplayLinkAtomicFlags;


@interface JHDisplayLink () {
    CVDisplayLinkRef _displayLink;
    CVTimeStamp _timeStamp;
    
    JHDisplayLinkAtomicFlags _atomicFlags;
    bool _isRunning;
    
    /// Serial dispatch queue that has client's queue as its target
    dispatch_queue_t _internalDispatchQueue;
    
    /// Queue that serialises calls to -start and -stop.
    dispatch_queue_t _stateChangeQueue;
}

@end

@implementation JHDisplayLink

/// Client's dispatch queue. Unretained.
@synthesize dispatchQueue = _clientDispatchQueue;

- (id)init {
    if ((self = [super init])) {
        CVReturn status =
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        assert(status == kCVReturnSuccess);
        
        _stateChangeQueue = dispatch_queue_create("JHDisplayLink.stateChange",
                                                  NULL);
        _clientDispatchQueue = dispatch_get_main_queue();
        _internalDispatchQueue = dispatch_queue_create("JHDisplayLink", NULL);
        dispatch_set_target_queue(_internalDispatchQueue, _clientDispatchQueue);
        
        CVDisplayLinkSetOutputCallback(_displayLink, JHDisplayLinkCallback,
                                       (__bridge void*)self);
    }
    
    return self;
}

- (void)dealloc {
    CVDisplayLinkRelease(_displayLink);
    JHDispatchRelease(&_internalDispatchQueue);
    JHDispatchRelease(&_stateChangeQueue);
}

- (void)setDispatchQueue:(dispatch_queue_t)dispatchQueue {
    dispatch_set_target_queue(_internalDispatchQueue, dispatchQueue);
    _clientDispatchQueue = dispatchQueue;
}

- (void)start {
    dispatch_async(_stateChangeQueue, ^{
        if (_isRunning)
            return;
        
        _isRunning = true;
        
        // We CFRetain self while the displaylink thread is active, to ensure it
        // always has a valid 'self' pointer. The CFRetain is undone by [1].
        CFRetain((__bridge CFTypeRef)self);
        
        CVDisplayLinkStart(_displayLink);
    });
}

- (void)stop {
    dispatch_async(_stateChangeQueue, ^{
        if (!_isRunning)
            return;
        
        _isRunning = false;
        // The displaylink thread resumes the queue at [2]
        dispatch_suspend(_stateChangeQueue);
    });
}

static CVReturn
JHDisplayLinkCallback(CVDisplayLinkRef displayLink,
                      const CVTimeStamp *inNow,
                      const CVTimeStamp *inOutputTime,
                      CVOptionFlags flagsIn,
                      CVOptionFlags *flagsOut,
                      void *ctx) {
    JHDisplayLink *self = (__bridge JHDisplayLink*)ctx;
    
    if (!self->_isRunning) {
        CVDisplayLinkStop(displayLink);
        dispatch_resume(self->_stateChangeQueue); // See [2]
        CFRelease(ctx); // See [1]
        
    } else if (!__sync_fetch_and_or(&self->_atomicFlags,
                                    kJHDisplayLinkIsRendering)) {
        self->_timeStamp = *inOutputTime;
        dispatch_async_f(self->_internalDispatchQueue,
                         (void*)CFBridgingRetain(self),
                         JHDisplayLinkRender);
    }
    
    return kCVReturnSuccess;
}

static void
JHDisplayLinkRender(void *ctx) {
    JHDisplayLink *self = CFBridgingRelease(ctx);
    if (self->_isRunning) {
        [self->_delegate displayLink:self
              didRequestFrameForTime:&self->_timeStamp];
    }
    __sync_fetch_and_and(&self->_atomicFlags, ~kJHDisplayLinkIsRendering);
}

@end