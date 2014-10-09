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
- (NSInteger)numberOfPointsInScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (CGFloat)scrollableLineGraph:(BJScrollableLineGraphView *)graph
          valueForPointAtIndex:(NSInteger)index;
- (NSAttributedString *)yAxisLabelStringForValue:(CGFloat)value;

@optional
- (NSAttributedString *)xAxisLabelStringForIndex:(NSUInteger)index;

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
- (UIColor *)yAxisColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)yAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (UIColor *)xAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph;
- (NSUInteger)xAxisLabelGapForScrollableLableLineGraph:(BJScrollableLineGraphView *)graph;
- (void)scrollableLineGraphDidFinishLoading:(BJScrollableLineGraphView *)graph;

@end

@interface BJScrollableLineGraphView : UIView

@property (strong, nonatomic) UIColor *graphColor;
@property (strong, nonatomic) UIColor *graphBackgroundColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat graphWidthPerDataRecord;

@property (nonatomic, assign) IBOutlet id <BJScrollableLineGraphViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id <BJScrollableLineGraphViewDelegate> delegate;

- (void)reloadGraph;

@end
