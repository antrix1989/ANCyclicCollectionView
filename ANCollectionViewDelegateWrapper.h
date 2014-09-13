//
//  ANCollectionViewDelegateWrapper.h
//  Antrix
//
//  Created by Sergey Demchenko on 9/26/13.
//  Copyright (c) 2013 antrix1989@gmail.com. All rights reserved.
//

@protocol ANCyclicCollectionViewDelegate;

@interface ANCollectionViewDelegateWrapper : NSObject <UICollectionViewDelegate>

@property (nonatomic, assign) id<ANCyclicCollectionViewDelegate> originalDelegate;
@property (nonatomic, assign) id extendedCollectionView;

- (instancetype)initWithDelegate:(id<UICollectionViewDelegate>)delegate andCollectionView:(id)collectionView;

@end
