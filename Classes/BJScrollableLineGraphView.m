//
//  BJScrollableLineGraphView.m
//  BJScrollableLineGraph Demo
//
//  Created by Ben Lei on 7/10/14.
//  Copyright (c) 2014 BenJ Lei. All rights reserved.
//

#import "BJScrollableLineGraphView.h"
#import "BEMSimpleLineGraphView.h"

#define DEFAULT_GRAPH_BG_COLOR [UIColor colorWithRed:31.0/255.0 \
                                              green:187.0/255.0 \
                                               blue:166.0/255.0 \
                                              alpha:1.0]
#define DEFAULT_GRAPH_COLOR [UIColor whiteColor]
#define DEFAULT_GRAPH_WIDTH_PER_DATA (30.0f)
#define DEFAULT_GRAPH_MAX_VALUE (1000.0f)
#define DEFAULT_GRAPH_MIN_VALUE (-1000.f)
#define DEFAULT_GRAPH_X_AXIS_HEIGHT (25.0f)
#define DEFAULT_GRAPH_Y_AXIS_WIDTH (48.0f)
#define DEFAULT_GRAPH_HORIZONTAL_PADDING (50.0f)

@interface BJScrollableLineGraphView()
    <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) BEMSimpleLineGraphView *graphView;
@property (strong, nonatomic) UIView *yAxisView;

@property (strong, nonatomic) NSLayoutConstraint *graphViewWidthConstraint;

@property (nonatomic, readonly) CGFloat graphYAxisWidth;
@property (nonatomic, readonly) CGFloat graphXAxisHeight;
@property (nonatomic, readonly) CGFloat graphHorizontalPadding;

@end

@implementation BJScrollableLineGraphView

@synthesize graphColor = _graphColor;
@synthesize graphBackgroundColor = _graphBackgroundColor;
@synthesize lineWidth = _lineWidth;
@synthesize graphWidthPerDataRecord = _graphWidthPerDataRecord;

- (void)awakeFromNib
{
    [super awakeFromNib];

    // -- Setup Scroll View --
    [self setScrollView:[[UIScrollView alloc] initWithFrame:self.frame]];
    [self.scrollView setBackgroundColor:self.graphBackgroundColor];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setBounces:NO];

    // -- Setup Graph View --
    [self setGraphView:[self createGraphView]];

    // -- Setup Y Axis View
    [self setYAxisView:[self createYAxisView]];

    // -- Add subviews --
    [self addSubview:self.scrollView];
    [self addSubview:self.yAxisView];
    [self.scrollView addSubview:self.graphView];

    // -- Add layout constraints --
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.graphView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.yAxisView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.scrollView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.scrollView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.scrollView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.scrollView
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1.0f
                                      constant:0.0f],

        [NSLayoutConstraint constraintWithItem:self.yAxisView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.yAxisView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:-(self.graphXAxisHeight)],
        [NSLayoutConstraint constraintWithItem:self.yAxisView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.yAxisView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:self.graphYAxisWidth]
        ]];

    self.graphViewWidthConstraint =
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:self.frame.size.width];
    if(self.dataSource){
        [self.graphViewWidthConstraint
             setConstant:([self.dataSource numberOfPointsInScrollableLineGraph:self] *
                          self.graphWidthPerDataRecord)];
    }
    [self.scrollView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:-(self.graphXAxisHeight)],
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0f
                                      constant:self.graphYAxisWidth + self.graphHorizontalPadding],
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1.0f
                                      constant:-self.graphHorizontalPadding],
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeHeight
                                    multiplier:1.0f
                                      constant:-(self.graphXAxisHeight)],
        self.graphViewWidthConstraint
        ]];
}

- (void)setGraphColor:(UIColor *)graphColor
{
    _graphColor = graphColor;
    if(self.graphView){
        [self.graphView setColorLine:graphColor];
        [self.graphView reloadGraph];
    }
}

- (UIColor *)graphColor
{
    if (!_graphColor) {
        _graphColor = DEFAULT_GRAPH_COLOR;
    }

    return _graphColor;
}

- (void)setGraphBackgroundColor:(UIColor *)graphBackgroundColor
{
    _graphBackgroundColor = graphBackgroundColor;
    if(self.graphView){
        [self.scrollView setBackgroundColor:graphBackgroundColor];
        [self.graphView setColorTop:graphBackgroundColor];
        [self.graphView setColorBottom:graphBackgroundColor];
        [self.graphView reloadGraph];
    }
}

- (UIColor *)graphBackgroundColor
{
    if (!_graphBackgroundColor) {
        _graphBackgroundColor = DEFAULT_GRAPH_BG_COLOR;
    }

    return _graphBackgroundColor;
}

- (void) setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    if(self.graphView){
        [self.graphView setWidthLine:lineWidth];
        [self.graphView reloadGraph];
    }
}

- (CGFloat)lineWidth
{
    if(!_lineWidth){
        _lineWidth = 3.0f;
    }

    return _lineWidth;
}

- (void)setGraphWidthPerDataRecord:(CGFloat)graphWidthPerDataRecord
{
    _graphWidthPerDataRecord = graphWidthPerDataRecord;
    if(self.graphView && self.dataSource){
        [self.graphViewWidthConstraint
         setConstant:([self.dataSource numberOfPointsInScrollableLineGraph:self] *
                      graphWidthPerDataRecord)];
        [self.graphView reloadGraph];
    }
}

- (CGFloat)graphWidthPerDataRecord
{
    if(!_graphWidthPerDataRecord){
        _graphWidthPerDataRecord = DEFAULT_GRAPH_WIDTH_PER_DATA;
    }

    return _graphWidthPerDataRecord;
}

- (void)reloadGraph
{
    if(self.graphView){
        [self.graphView reloadGraph];
    }

    if(self.yAxisView){
        [self reloadYAxisView:self.yAxisView];
    }

    //TODO: reload x-axis and y-axis
}

- (CGFloat)graphXAxisHeight
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(xAxisHeightForScrollableLineGraph:)])
    {
        return [self.delegate xAxisHeightForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_X_AXIS_HEIGHT;
}

- (CGFloat)graphYAxisWidth
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(yAxisWidthForScrollableLineGraph:)]) {
        return [self.delegate yAxisWidthForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_Y_AXIS_WIDTH;
}

- (CGFloat)graphHorizontalPadding
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(horizontalPaddingForScrollableLineGraph:)]){
        return [self.delegate horizontalPaddingForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_HORIZONTAL_PADDING;
}

- (CGFloat)bottomOffsetForValue:(CGFloat)value
{
    if(self.graphView){
        CGFloat maxValue = [self maxValueForLineGraph:self.graphView];
        CGFloat minValue = [self minValueForLineGraph:self.graphView];
        CGFloat graphHeight = self.graphView.frame.size.height;

        if (maxValue == minValue) {
            return graphHeight / 2.0f + self.graphXAxisHeight;
        }

        CGFloat positionOnYAxis = (graphHeight -
                                   ((value - minValue) /
                                    ((maxValue - minValue) / graphHeight)));

        return graphHeight - positionOnYAxis + self.graphXAxisHeight;
    }

    return 0.0f;
}

- (BEMSimpleLineGraphView *)createGraphView
{
    BEMSimpleLineGraphView *graphView =
        [[BEMSimpleLineGraphView alloc] initWithFrame:self.scrollView.frame];
    [graphView setDataSource:self];
    [graphView setDelegate:self];
    [graphView setColorTop:self.graphBackgroundColor];
    [graphView setColorBottom:self.graphBackgroundColor];
    [graphView setColorLine:self.graphColor];
    [graphView setWidthLine:self.lineWidth];
    [graphView setEnableTouchReport:NO];
    [graphView setEnablePopUpReport:NO];
    [graphView setEnableBezierCurve:YES];
    [graphView setEnableYAxisLabel:NO];
    [graphView setAutoScaleYAxis:YES];
    [graphView setAnimationGraphEntranceTime:0];
    [graphView setAnimationGraphStyle:BEMLineAnimationNone];

    return graphView;
}



- (UIView *)createYAxisView
{
    UIView *yAxisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 1000)];
    [self reloadYAxisView:yAxisView];

    return yAxisView;

}

- (void)reloadYAxisView:(UIView *)yAxisView
{
    if(yAxisView.subviews && [yAxisView.subviews count] > 0){
        for (UIView *perSubView in yAxisView.subviews) {
            [perSubView removeFromSuperview];
        }
    }

    [yAxisView setBackgroundColor:self.graphBackgroundColor];

    UIColor *indicatorColor = [UIColor blackColor];
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(yAxisIndicatorColorForScrollableLineGraph:)])
    {
        indicatorColor = [self.delegate yAxisIndicatorColorForScrollableLineGraph:self];
    }

    CGFloat maxValue = [self maxValueForLineGraph:self.graphView];
    CGFloat minValue = [self minValueForLineGraph:self.graphView];
    NSUInteger stepCount = 7;  // hard code first
    CGFloat stepValue = (maxValue - minValue) / stepCount;

    for (NSUInteger idx = 0; idx <= stepCount; idx++) {
        CGFloat currentValue = minValue + stepValue * idx;

        // create reference view and indicator view
        UIView *perRefView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [perRefView setAlpha:0.0f];

        UIView *perIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 1)];
        [perIndicatorView setBackgroundColor:indicatorColor];

        [yAxisView addSubview:perRefView];
        [yAxisView addSubview:perIndicatorView];

        [perRefView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [perIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];

        [yAxisView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:perRefView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:5.0f],
            [NSLayoutConstraint constraintWithItem:perRefView
                                         attribute:NSLayoutAttributeHeight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:yAxisView
                                         attribute:NSLayoutAttributeHeight
                                        multiplier:(1.0f * idx / stepCount)
                                          constant:0.0f],
            [NSLayoutConstraint constraintWithItem:perRefView
                                         attribute:NSLayoutAttributeLeading
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:yAxisView
                                         attribute:NSLayoutAttributeLeading
                                        multiplier:1.0f
                                          constant:0.0f],
            [NSLayoutConstraint constraintWithItem:perRefView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:yAxisView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0f
                                          constant:0.0f],

            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:perRefView
                                         attribute:NSLayoutAttributeWidth
                                        multiplier:1.0f
                                          constant:0.0f],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeHeight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:1.0f],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeLeading
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:yAxisView
                                         attribute:NSLayoutAttributeLeading
                                        multiplier:1.0f
                                          constant:0.0f],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeCenterY
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:perRefView
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0f
                                          constant:0.0f]
            ]];


        NSAttributedString *perLabelString = nil;
        if(self.dataSource){
            perLabelString = [self.dataSource yAxisLabelStringForValue:currentValue];
        }
        else{
            perLabelString = [[NSAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%.1f", currentValue]];
        }
        CGRect perLabelFrame = CGRectMake(0, 0, 100, 100);
        perLabelFrame.size.width = ceilf(perLabelString.size.width);
        perLabelFrame.size.height = ceilf(perLabelString.size.height);

        UILabel *perLabel = [[UILabel alloc] initWithFrame:perLabelFrame];
        [perLabel setAttributedText:perLabelString];

        [yAxisView addSubview:perLabel];

        [perLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        [yAxisView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:perLabel
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:perLabelFrame.size.width],
            [NSLayoutConstraint constraintWithItem:perLabel
                                         attribute:NSLayoutAttributeHeight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:perLabelFrame.size.height],
            [NSLayoutConstraint constraintWithItem:perLabel
                                         attribute:NSLayoutAttributeLeading
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:perRefView
                                         attribute:NSLayoutAttributeTrailing
                                        multiplier:1.0f
                                          constant:5.0f],
            [NSLayoutConstraint constraintWithItem:perLabel
                                         attribute:NSLayoutAttributeCenterY
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:perRefView
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0f
                                          constant:0.0f]
            ]];
    }
}

#pragma mark - BEMSimpleLineGraphDataSource

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    if(self.dataSource){
        return [self.dataSource numberOfPointsInScrollableLineGraph:self];
    }
    return 0;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    if(self.dataSource){
        return [self.dataSource scrollableLineGraph:self valueForPointAtIndex:index];
    }
    return 0.0f;
}

#pragma mark - BEMSimpleLineGraphDelegate

- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    if(self.delegate){
        return [self.delegate maxValueForScrollableLineGraph:self];
    }
    return DEFAULT_GRAPH_MAX_VALUE;
}

- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    if(self.delegate){
        return [self.delegate minValueForScrollableLineGraph:self];
    }
    return DEFAULT_GRAPH_MIN_VALUE;
}

- (CGFloat)staticPaddingForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 0.0f;
}

- (void)lineGraphDidFinishLoading:(BEMSimpleLineGraphView *)graph
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(scrollableLineGraphDidFinishLoading:)])
    {
        [self.delegate scrollableLineGraphDidFinishLoading:self];
    }

    NSLog(@"[DEBUG] Finish loading line graph within [%.1f ~ %.1f]",
          [self maxValueForLineGraph:self.graphView],
          [self minValueForLineGraph:self.graphView]);
}

@end
