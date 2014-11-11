//
//  BJScrollableLineGraphView.h
//  BJScrollableLineGraph Demo
//
//  Created by Ben Lei on 7/10/14.
//  Copyright (c) 2014 BenJ Lei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BJScrollableLineGraphView;

@protocol BJScrollableLineGraphViewDataSource <NSObject>
@required
- (NSUInteger)numberOfPointsInScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)scrollableLineGraph:(BJScrollableLineGraphView *)graph
          valueForPointAtIndex:(NSInteger)index;
- (NSAttributedString *)yAxisLabelStringForValue:(CGFloat)value;

@optional
- (NSAttributedString *)xAxisLabelStringForIndex:(NSUInteger)index;
- (NSAttributedString *)referencePopUpStringForIndex:(NSUInteger)index;

@end

@protocol BJScrollableLineGraphViewDelegate <NSObject>
@required
- (CGFloat)maxValueForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)minValueForScrollableLineGraph:(BJScrollableLineGraphView *)graph;

@optional
- (CGFloat)xAxisHeightForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)yAxisWidthForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)horizontalPaddingForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)topPaddingForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)bottomPaddingForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (NSUInteger)yAxisLabelCountForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)yAxisColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)yAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)xAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (NSUInteger)xAxisLabelGapForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (NSUInteger)xAxisLabelExtendCountForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (NSUInteger)xAxisLabelInitialOffsetForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)referenceLineColorForScrollable:(BJScrollableLineGraphView *)graph;
- (UIColor *)referencePopUpColorForScrollable:(BJScrollableLineGraphView *)graph;
- (BOOL)referencePopUpDragableForScrollable:(BJScrollableLineGraphView *)graph;

- (void)scrollableLineGraphDidFinishLoading:(BJScrollableLineGraphView *)graph;
- (void)scrollableLineGraph:(BJScrollableLineGraphView *)graph didTapOnIndex:(NSUInteger)index;

@end

@interface BJScrollableLineGraphView : UIView

@property (strong, nonatomic) UIColor *graphColor;
@property (strong, nonatomic) UIColor *graphBackgroundColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat graphWidthPerDataRecord;
@property (nonatomic, readonly, getter=isScrolledToEnd) BOOL scrolledToEnd;

@property (nonatomic, assign) IBOutlet id <BJScrollableLineGraphViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id <BJScrollableLineGraphViewDelegate> delegate;

- (void)reloadGraph;
- (CGFloat)bottomOffsetForValue:(CGFloat)value;
- (void)setReferenceAtIndex:(NSUInteger)index;
- (void)setReferenceAtIndex:(NSUInteger)index
       withScrollViewUpdate:(BOOL)isUpdateScrollView
                   animated:(BOOL)animated;
- (void)removeReference;

@end
