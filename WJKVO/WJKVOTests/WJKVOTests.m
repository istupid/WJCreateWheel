//
//  WJKVOTests.m
//  WJKVOTests
//
//  Created by William on 2016/4/10.
//  Copyright © 2016年 William. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+WJKVO.h"

#pragma mark - WJPerson

@interface WJPerson : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) unsigned int age;

@end

@implementation WJPerson

@end


#pragma mark - WJKVOTests

@interface WJKVOTests : XCTestCase

@end

@implementation WJKVOTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    WJPerson *person = [WJPerson new];
    [person wj_addObserver:self forKeyPath:@"name" block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"name %@--- %@", oldValue,newValue);
    }];
    for (int i = 0; i < 50; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            person.name = [NSString stringWithFormat: @"xiongchun%zd", i];
        });
    }
    
//    [person wj_removeObserver:self forKeyPath:@"name"];
}

- (void)testKVO {
    WJPerson *person = [WJPerson new];
    person.name = @"lizhang";
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

}

@end
