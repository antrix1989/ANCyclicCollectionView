//
//  ANCyclicCollectionView.m
//  Antrix
//
//  Created by Sergey Demchenko on 9/25/13.
//  Copyright (c) 2013 antrix1989@gmail.com. All rights reserved.
//

#import "ANCyclicCollectionView.h"
#import "ANCollectionViewDelegateWrapper.h"

const NSUInteger kDefaultSectionNumber = 0;
const NSUInteger kMinimalCountOfCopies = 3;
const CGFloat kAutoSwipeTimerInterval = 3.0;

@interface ANCyclicCollectionView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) id<ANCyclicCollectionViewDataSource> originalDataSource;
@property (strong, nonatomic) ANCollectionViewDelegateWrapper *delegateWrapper;

@property (assign, nonatomic) CGFloat lastHorizontalOffset;
@property (assign, nonatomic) CGFloat lastScrollDistance;

@property (strong, nonatomic) NSTimer *autoSwipeTimer;

@property (assign, nonatomic) NSUInteger countOfItems;

@property (assign, nonatomic) CGFloat horizontalWidthOfItems;

@property (assign, nonatomic) CGFloat leftThreshold;
@property (assign, nonatomic) CGFloat rightThreshold;

@property (assign, nonatomic) BOOL isJump;
@property (assign, nonatomic) BOOL isInitialScroll;

@end

@implementation ANCyclicCollectionView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _countOfCopies = kMinimalCountOfCopies;
        _countOfItems = 0;
        _horizontalWidthOfItems = 0.0;
        _leftThreshold = 0.0;
        _rightThreshold = 0.0;
        _isJump = NO;
        _isInitialScroll = NO;
        _autoSwipeTimerInterval = kAutoSwipeTimerInterval;
    }
    return self;
}

- (void)setDataSource:(id<ANCyclicCollectionViewDataSource>)dataSource
{
    self.originalDataSource = dataSource;
    [super setDataSource:self];
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    self.delegateWrapper = [[ANCollectionViewDelegateWrapper alloc] initWithDelegate:delegate andCollectionView:self];
    [super setDelegate:self.delegateWrapper];
}

- (void)setCountOfCopies:(NSUInteger)countOfCopies
{
    if (countOfCopies >= kMinimalCountOfCopies) {
        _countOfCopies = countOfCopies;
        [self reloadData];
    }
}

- (void)setAutoSwipeTimerInterval:(CGFloat)autoSwipeTimerInterval
{
    if (_autoSwipeTimerInterval != autoSwipeTimerInterval) {
        _autoSwipeTimerInterval = autoSwipeTimerInterval;
        [self stopAutoSwipeTimer];
        [self startAutoSwipeTimer];
    }
}

- (void)reloadData
{
    [super reloadData];
    [self calculateHorizontalWidthOfItems];
    [self calculateThresholds];
    [self scrollToFirstItem];
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:didScrollWithDistance:)] && self.isInitialScroll == NO) {
        NSInteger scrollDistance = contentOffset.x - self.contentOffset.x;
        if (self.isJump) {
            // if scrollDistance > 0 then we jumped to the right and direction is from left(-1) else direction is from right
            CGFloat scrollDirection = (scrollDistance > 0) ? -1 : 1;
            // Calculate scroll distance without jump distance
            scrollDistance = scrollDirection * (self.horizontalWidthOfItems - ABS(scrollDistance));
        }
        [self.delegateWrapper.originalDelegate cyclicCollectionView:self didScrollWithDistance:scrollDistance];
    }
    
    self.isJump = NO;
    self.isInitialScroll = NO;
    
    [super setContentOffset:contentOffset];
}

#pragma mark - Public

- (void)setContentHorizontalOffsetDelta:(CGFloat)contentHorizontalOffsetDelta
{
    if (self.contentSize.width > 0) {
        CGPoint contentOffset = self.contentOffset;
        contentOffset.x += contentHorizontalOffsetDelta;
        self.contentOffset = [self validateOffset:contentOffset];
    }
}

- (void)startAutoSwipeTimer
{
    if (self.autoSwipeTimer == nil) {
        self.autoSwipeTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoSwipeTimerInterval
                                                               target:self
                                                             selector:@selector(autoSwipeTimerHandler)
                                                             userInfo:nil
                                                              repeats:YES];
        NSLog(@"Auto swipe timer is started! Interval: %f", self.autoSwipeTimerInterval);
    }
}

- (void)stopAutoSwipeTimer
{
    if (self.autoSwipeTimer) {
        [self.autoSwipeTimer invalidate];
        self.autoSwipeTimer = nil;
        NSLog(@"Auto swipe timer is stoped!");
    }
}

- (NSUInteger)indexOfVisibleCell
{
    NSInteger offsetAtBegining = (NSInteger)self.contentOffset.x % (NSInteger)self.horizontalWidthOfItems;
    NSUInteger itemIndex = offsetAtBegining / (self.horizontalWidthOfItems / self.countOfItems);
    return itemIndex;
}

- (void)scrollToItemAtIndex:(NSUInteger)index withAnimation:(BOOL)animation
{
    if (index < self.countOfItems) {
        CGPoint contentOffset = self.contentOffset;
        NSInteger displayedItemIndex = floor(self.contentOffset.x / self.horizontalWidthOfItems) * self.countOfItems;
        contentOffset.x = (displayedItemIndex + index) * (self.horizontalWidthOfItems / self.countOfItems);
        [self setContentOffset:contentOffset animated:animation];
        
        if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:visibleItemAtIndex:)]) {
            [self.delegateWrapper.originalDelegate cyclicCollectionView:self visibleItemAtIndex:index];
        }
    } else {
        NSLog(@"Tried to scroll to non-existent item at index: %d with total count: %d", index, self.countOfItems);
    }
}

#pragma mark - AutoSwipe Timer handler

- (void)autoSwipeTimerHandler
{
    if (self.countOfItems > 0) {
        CGPoint contentOffset = self.contentOffset;
        CGFloat oneItemWidth = (self.horizontalWidthOfItems / self.countOfItems);
        NSInteger nextDisplayedItemIndex = floor(self.contentOffset.x / oneItemWidth) + 1;
        contentOffset.x = nextDisplayedItemIndex * oneItemWidth;
        [self setContentOffset:contentOffset animated:YES];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    self.countOfItems = [self.originalDataSource collectionView:collectionView numberOfItemsInSection:section];
    return [self totalCountOfItems];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.originalDataSource cyclicCollectionView:self cellForItemAtIndexPath:indexPath andIndex:[self itemPositionFromTotalIndex:indexPath.row]];
}

#pragma mark - UICollectionViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.delegateWrapper.originalDelegate scrollViewWillBeginDragging:scrollView];
    }
    
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:visibleItemAtIndex:)]) {
        [self.delegateWrapper.originalDelegate cyclicCollectionView:self visibleItemAtIndex:[self indexOfVisibleCell]];
    }
    
    [self stopAutoSwipeTimer];
    self.contentOffset = [self validOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.delegateWrapper.originalDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:didEndDragWithLastDirection:)]) {
        [self.delegateWrapper.originalDelegate cyclicCollectionView:self didEndDragWithLastDirection:self.lastScrollDistance];
    }
    
    self.contentOffset = [self validOffset];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.delegateWrapper.originalDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
    
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:visibleItemAtIndex:)]) {
        [self.delegateWrapper.originalDelegate cyclicCollectionView:self visibleItemAtIndex:[self indexOfVisibleCell]];
    }
    
    self.contentOffset = [self validOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.delegateWrapper.originalDelegate scrollViewDidEndDecelerating:scrollView];
    }
    
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(cyclicCollectionView:visibleItemAtIndex:)]) {
        [self.delegateWrapper.originalDelegate cyclicCollectionView:self visibleItemAtIndex:[self indexOfVisibleCell]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegateWrapper.originalDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegateWrapper.originalDelegate scrollViewDidScroll:scrollView];
    }
    
    CGFloat horizontalOffset = self.contentOffset.x;
    self.lastScrollDistance = horizontalOffset - self.lastHorizontalOffset;
    self.lastHorizontalOffset = horizontalOffset;
}

#pragma mark - Private

- (NSUInteger)totalCountOfItems
{
    return self.countOfItems * self.countOfCopies;
}

- (NSUInteger)itemPositionFromTotalIndex:(NSUInteger)totalIndex
{
    return totalIndex % self.countOfItems;
}

- (void)calculateHorizontalWidthOfItems
{
    self.horizontalWidthOfItems = 0.0;
    NSUInteger numberOfItems = [self numberOfItemsInSection:kDefaultSectionNumber] / self.countOfCopies;
    for (NSUInteger i = 0; i < numberOfItems; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:kDefaultSectionNumber];
        self.horizontalWidthOfItems += [self sizeForItemAtIndexPath:indexPath].width + [self minimumLineSpacingForSectionAtIndex:kDefaultSectionNumber];
    }
}

- (void)scrollToFirstItem
{
    if (self.contentSize.width > 0) {
        self.isInitialScroll = YES;
        NSUInteger firstItemPosition = floor(self.countOfCopies / 2);
        [self setContentOffset:CGPointMake(firstItemPosition * self.horizontalWidthOfItems, self.contentOffset.y)];
    }
}

- (void)calculateThresholds
{
    self.leftThreshold = self.horizontalWidthOfItems / 2.0;
    self.rightThreshold = self.leftThreshold + ((self.countOfCopies - 1) * self.horizontalWidthOfItems);
}

- (CGPoint)validOffset
{
    return [self validateOffset:self.contentOffset];
}

- (CGPoint)validateOffset:(CGPoint)newOffset
{
    if (self.horizontalWidthOfItems > 0) {
        if (newOffset.x <= self.leftThreshold) {
            newOffset.x += self.horizontalWidthOfItems;
            self.isJump = YES;
            //            NSLog(@"Scroll to frame {%.2f, %.2f}", newOffset.x, newOffset.x + self.width);
            //            NSLog(@"Jump right");
        } else if (newOffset.x + self.frame.size.width >= self.rightThreshold) {
            newOffset.x -= self.horizontalWidthOfItems;
            self.isJump = YES;
            //            NSLog(@"Scroll to frame {%.2f, %.2f}", newOffset.x, newOffset.x + self.width);
            //            NSLog(@"Jump left");
        }
    }
    return (self.contentSize.width > 0) ? newOffset : CGPointZero;
}

#pragma mark - CollectionViewFlowLayout exension

- (id<UICollectionViewDelegateFlowLayout>)delegateFlowLayout
{
    return (id<UICollectionViewDelegateFlowLayout>)self.delegate;
}

- (UICollectionViewFlowLayout *)collectionViewFlowLayout
{
    if([self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]])
        return (UICollectionViewFlowLayout *)self.collectionViewLayout;
    return nil;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.delegateFlowLayout respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)])
        return [self.delegateFlowLayout collectionView:self layout:self.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    return self.collectionViewFlowLayout.itemSize;
}

- (CGFloat)minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if([self.delegateFlowLayout respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)])
        return [self.delegateFlowLayout collectionView:self layout:self.collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
    return self.collectionViewFlowLayout.minimumLineSpacing;
}

@end
