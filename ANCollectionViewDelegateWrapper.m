//
//  ANCollectionViewDelegateWrapper.m
//  Antrix
//
//  Created by Sergey Demchenko on 9/26/13.
//  Copyright (c) 2013 antrix1989@gmail.com. All rights reserved.
//

#import "ANCollectionViewDelegateWrapper.h"
#import "ANCyclicCollectionView.h"

@implementation ANCollectionViewDelegateWrapper

- (instancetype)initWithDelegate:(id<ANCyclicCollectionViewDelegate>)delegate
               andCollectionView:(id)collectionView{
    self = [super init];
	if (self != nil) {
        self.originalDelegate = delegate;
        self.extendedCollectionView = collectionView;
	}
	return self;
}

- (void)dealloc
{
    self.originalDelegate = nil;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.extendedCollectionView respondsToSelector:aSelector]) {
        return self.extendedCollectionView;
    } else {
        return self.originalDelegate;
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.originalDelegate respondsToSelector:aSelector] || [self.extendedCollectionView respondsToSelector:aSelector];
}

@end
