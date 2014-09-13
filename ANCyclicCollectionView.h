//
//  ANCyclicCollectionView.h
//  Antrix
//
//  Created by Sergey Demchenko on 9/25/13.
//  Copyright (c) 2013 antrix1989@gmail.com. All rights reserved.
//

@class ANCyclicCollectionView;

@protocol ANCyclicCollectionViewDataSource <UICollectionViewDataSource>

/*
 * Data source should implement this method instead of
 * - (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
 * because cell dequeued with changed indexPath displayed at position of new indexPath on iOS7.
 */
- (UICollectionViewCell *)cyclicCollectionView:(ANCyclicCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath andIndex:(NSUInteger)index;

@end

@protocol ANCyclicCollectionViewDelegate <UICollectionViewDelegate>

@optional

/*
 * Notify the delegate index of visible item.
 */
- (void)cyclicCollectionView:(ANCyclicCollectionView *)collectionView visibleItemAtIndex:(NSUInteger)index;

- (void)cyclicCollectionView:(ANCyclicCollectionView *)collectionView didScrollWithDistance:(CGFloat)distance;

- (void)cyclicCollectionView:(ANCyclicCollectionView *)collectionView didEndDragWithLastDirection:(CGFloat)direction;

@end

@interface ANCyclicCollectionView : UICollectionView

@property (weak, nonatomic) id<ANCyclicCollectionViewDataSource> dataSource;

/*
 * Count of copies.
 * Better to set the odd number
 * Default = 3
 * Min value = 3
 */
@property (assign, nonatomic) NSUInteger countOfCopies;

/*
 * Interval of autoswipe timer.
 */
@property (assign, nonatomic) CGFloat autoSwipeTimerInterval;

/*
 * Set horizontal content offset with validation.
 */
- (void)setContentHorizontalOffsetDelta:(CGFloat)contentHorizontalOffsetDelta;

/*
 * Start autoswipe timer.
 */
- (void)startAutoSwipeTimer;

/*
 * Stop autoswipe timer.
 */
- (void)stopAutoSwipeTimer;

/*
 * Index of item in the center of the collection view.
 */
- (NSUInteger)indexOfVisibleCell;

/*
 * Scroll to item at index.
 */
- (void)scrollToItemAtIndex:(NSUInteger)index withAnimation:(BOOL)animation;

@end
