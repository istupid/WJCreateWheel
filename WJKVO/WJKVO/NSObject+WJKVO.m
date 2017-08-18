//
//  NSObject+WJKVO.m
//  WJKVO
//
//  Created by William on 2016/4/10.
//  Copyright © 2016年 William. All rights reserved.
//

#import "NSObject+WJKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kWJKVOPrefix = @"_WJKVO";
static char *const kWJAssociatedObserver = "kWJAssociatedObserver";

#pragma mark 

@interface WJObserverInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) WJObserverBlock block;

@end

@implementation WJObserverInfo

+ (instancetype)observerInfoWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath block:(WJObserverBlock)block {
    WJObserverInfo *info = [[self alloc] init];
    info.observer = observer;
    info.keyPath = keyPath;
    info.block = block;
    return info;
}

@end

#pragma mark - override imp

static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

static NSString *getterForSetter(NSString *setter) {
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = {3, setter.length - 4};
    NSString *key = [setter substringWithRange:range];
    
    return key.lowercaseString;
}

static void kvo_setter(id self, SEL _cmd, id value) {
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *getter = getterForSetter(setter);
    if (!getter) {
        return;
    }
    
    id oldValue = [self valueForKey:getter];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, value);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, kWJAssociatedObserver);
    for (WJObserverInfo *info in observers) {
        if ([info.keyPath isEqualToString:getter]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                info.block(self, getter, oldValue, value);
            });
        }
    }
}

@implementation NSObject (WJKVO)


- (Class)createClassWithsuperClass:(Class)cls {
    
    NSString *clsName = NSStringFromClass(cls);
    NSString *className = [kWJKVOPrefix stringByAppendingString:clsName];
    
    Class class = NSClassFromString(className);
    if (class) return class;
    
    class = objc_allocateClassPair(cls, className.UTF8String, 0);
    
    Method clsMethod = class_getInstanceMethod(cls, @selector(class));
    const char *types = method_getTypeEncoding(clsMethod);
    class_addMethod(class, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(class);
    
    return class;
}

- (BOOL)hasSelector:(SEL)selector {
    
    Class cls = object_getClass(self);
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(cls, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL sel = method_getName(methodList[i]);
        if (sel == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

- (void)wj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(WJObserverBlock)block {
    if (keyPath.length <= 0) return;
    
    NSString *setter = [NSString stringWithFormat:@"set%@%@:",[keyPath substringToIndex:1].uppercaseString, [keyPath substringFromIndex:1]];
    SEL setterSel = NSSelectorFromString(setter);
    Method setterMethod = class_getInstanceMethod([self class], setterSel);
    if (!setterMethod) {
        //
        NSCParameterAssert(!setterMethod);
        return;
    }
    
    Class cls = object_getClass(self);
    if (![NSStringFromClass(cls) hasPrefix:kWJKVOPrefix]) {
        cls = [self createClassWithsuperClass:cls];
        object_setClass(self, cls); // modify isa
    }
    
    // add setter
    if (![self hasSelector:setterSel]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(cls, setterSel, (IMP)kvo_setter, types);
    }
    
    WJObserverInfo *info = [WJObserverInfo observerInfoWithObserver:observer keyPath:keyPath block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, kWJAssociatedObserver);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, kWJAssociatedObserver, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}

- (void)wj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    
    NSMutableArray *observers = objc_getAssociatedObject(self, kWJAssociatedObserver);
    
    [observers enumerateObjectsUsingBlock:^(WJObserverInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.observer == observer && [obj.keyPath isEqualToString:keyPath]) {
            [observers removeObject:obj];
            *stop = YES;
        }
    }];
}

@end
