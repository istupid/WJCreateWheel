//
//  NSObject+WJKVO.h
//  WJKVO
//
//  Created by William on 2016/4/10.
//  Copyright © 2016年 William. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WJObserverBlock)(id observer, NSString *keyPath, id oldValue, id newValue);

@interface NSObject (WJKVO)

- (void)wj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(WJObserverBlock)block;

- (void)wj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
