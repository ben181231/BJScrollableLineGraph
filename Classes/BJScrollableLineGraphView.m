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
#define DEFAULT_GRAPH_X_LABEL_GAP (1)
#define DEFAULT_GRAPH_X_AXIS_HEIGHT (25.0f)
#define DEFAULT_GRAPH_Y_AXIS_WIDTH (48.0f)
#define DEFAULT_GRAPH_HORIZONTAL_PADDING (50.0f)
#define DEFAULT_GRAPH_VERTICAL_PADDING (10.0f)

#define DEFAULT_GRAPH_REFERENCE_LINE_COLOR [UIColor blackColor]
#define DEFAULT_GRAPH_REFERENCE_POPUP_COLOR [UIColor whiteColor]

@interface BJScrollableLineGraphView()
    <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate,
    UIGestureRecognizerDelegate>
{
    CAShapeLayer *_horizontalReferenceLayer;
    CAShapeLayer *_verticalReferenceLayer;
    CAShapeLayer *_popUpTriangleLayer;
}

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) BEMSimpleLineGraphView *graphView;
@property (strong, nonatomic) UIView *xAxisView;
@property (strong, nonatomic) UIView *yAxisView;
@property (strong, nonatomic) UIView *referenceCircleView;
@property (strong, nonatomic) UILabel *referencePopUpView;

@property (strong, nonatomic) NSLayoutConstraint *graphViewWidthConstraint;

@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic, readonly) CGFloat graphYAxisWidth;
@property (nonatomic, readonly) CGFloat graphXAxisHeight;
@property (nonatomic, readonly) CGFloat graphHorizontalPadding;
@property (nonatomic, readonly) CGFloat graphTopPadding;
@property (nonatomic, readonly) CGFloat graphBottomPadding;
@property (nonatomic, readonly) NSUInteger graphXAxisLabelGap;
@property (nonatomic, readonly) UIColor *referenceLineColor;
@property (nonatomic, readonly) UIColor *referencePopUpColor;

@property (nonatomic, assign) NSUInteger referencingIndex;

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

    // -- Setup X Axis View
    [self setXAxisView:[self createXAxisView]];

    // -- Setup Referencing Views
    [self setupReferenceViews];

    // -- Add subviews --
    [self addSubview:self.scrollView];
    [self addSubview:self.yAxisView];
    [self.scrollView addSubview:self.xAxisView];
    [self.scrollView addSubview:self.graphView];
    [self.scrollView addSubview:self.referenceCircleView];
    [self.scrollView addSubview:self.referencePopUpView];

    // -- Add layout constraints --
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.graphView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.yAxisView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.xAxisView setTranslatesAutoresizingMaskIntoConstraints:NO];
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
                                      constant:self.graphTopPadding],
        [NSLayoutConstraint constraintWithItem:self.yAxisView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:-(self.graphXAxisHeight + self.graphBottomPadding)],
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

    [self setGraphViewWidthConstraint:
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:self.frame.size.width]];
    if(self.dataSource){
        [self.graphViewWidthConstraint
             setConstant:(([self.dataSource numberOfPointsInScrollableLineGraph:self] - 1) *
                          self.graphWidthPerDataRecord)];
    }
    [self.scrollView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0f
                                      constant:self.graphTopPadding],
        [NSLayoutConstraint constraintWithItem:self.graphView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.scrollView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:-(self.graphXAxisHeight + self.graphBottomPadding)],
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
                                      constant:-(self.graphXAxisHeight +
                                                 self.graphTopPadding +
                                                 self.graphBottomPadding)],
        self.graphViewWidthConstraint,

        [NSLayoutConstraint constraintWithItem:self.xAxisView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.graphView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0f
                                      constant:self.graphBottomPadding],
        [NSLayoutConstraint constraintWithItem:self.xAxisView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:self.graphXAxisHeight],
        [NSLayoutConstraint constraintWithItem:self.xAxisView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.graphView
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:self.xAxisView
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.graphView
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1.0f
                                      constant:0.0f]
        ]];
}

- (void)setGraphColor:(UIColor *)graphColor
{
    _graphColor = graphColor;
    if(self.graphView){
        [self.graphView setColorLine:graphColor];
        [self.graphView reloadGraph];
    }
    [self.referenceCircleView setBackgroundColor:graphColor];
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
    }

    [self reloadGraph];
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
             setConstant:(([self.dataSource numberOfPointsInScrollableLineGraph:self] - 1) *
                          graphWidthPerDataRecord)];
        [self.graphView reloadGraph];
        [self reloadXAxisView:self.xAxisView];
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

    if(self.xAxisView){
        [self reloadXAxisView:self.xAxisView];
    }

    if (self.referencingIndex != NSNotFound) {
        [self setReferenceAtIndex:self.referencingIndex];
    }
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

- (CGFloat)graphTopPadding
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(topPaddingForScrollableLineGraph:)]){
        return [self.delegate horizontalPaddingForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_VERTICAL_PADDING;
}

- (CGFloat)graphBottomPadding
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(bottomPaddingForScrollableLineGraph:)]){
        return [self.delegate horizontalPaddingForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_VERTICAL_PADDING;
}

- (NSUInteger)graphXAxisLabelGap
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(xAxisLabelGapForScrollableLineGraph:)]) {
        return [self.delegate xAxisLabelGapForScrollableLineGraph:self];
    }
    else return DEFAULT_GRAPH_X_LABEL_GAP;
}

- (UIColor *)referenceLineColor
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(referenceLineColorForScrollable:)]) {
        return [self.delegate referenceLineColorForScrollable:self];
    }
    else return DEFAULT_GRAPH_REFERENCE_LINE_COLOR;
}

- (UIColor *)referencePopUpColor
{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(referencePopUpColorForScrollable:)]) {
        return [self.delegate referencePopUpColorForScrollable:self];
    }
    else return DEFAULT_GRAPH_REFERENCE_POPUP_COLOR;
}


- (CGFloat)bottomOffsetOnGraphForValue:(CGFloat)value
{
    CGFloat maxValue = [self maxValueForLineGraph:self.graphView];
    CGFloat minValue = [self minValueForLineGraph:self.graphView];
    CGFloat graphHeight = self.graphView.frame.size.height;

    if (maxValue == minValue) {
        return graphHeight / 2.0f;
    }

    return (value - minValue) / (maxValue - minValue) * graphHeight;
}

- (CGFloat)bottomOffsetForValue:(CGFloat)value
{
    if(self.graphView){
        return [self bottomOffsetOnGraphForValue:value] +
                self.graphXAxisHeight +
                self.graphBottomPadding;
    }

    return 0.0f;
}

- (BEMSimpleLineGraphView *)createGraphView
{
    BEMSimpleLineGraphView *graphView =
        [[BEMSimpleLineGraphView alloc] initWithFrame:self.scrollView.frame];
    [graphView setDataSource:self];
    [graphView setDelegate:self];
    [graphView setColorLine:self.graphColor];
    [graphView setColorTop:[UIColor clearColor]];
    [graphView setColorBottom:[UIColor clearColor]];
    [graphView setWidthLine:self.lineWidth];
    [graphView setEnableTouchReport:NO];
    [graphView setEnablePopUpReport:NO];
    [graphView setEnableBezierCurve:YES];
    [graphView setEnableYAxisLabel:NO];
    [graphView setAutoScaleYAxis:YES];
    [graphView setAnimationGraphEntranceTime:0];
    [graphView setAnimationGraphStyle:BEMLineAnimationNone];

    [self setTapGesture:
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleTapGesture:)]];
    [self.tapGesture setDelegate:self];
    [graphView addGestureRecognizer:self.tapGesture];

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
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(yAxisColorForScrollableLineGraph:)])
    {
        [yAxisView setBackgroundColor:[self.delegate yAxisColorForScrollableLineGraph:self]];
    }

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

- (UIView *)createXAxisView
{
    UIView *xAxisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1000, 300)];
    [self reloadXAxisView:xAxisView];

    return xAxisView;
}

- (void)reloadXAxisView:(UIView *)xAxisView
{
    if(xAxisView.subviews && [xAxisView.subviews count] > 0){
        for (UIView *perSubView in xAxisView.subviews) {
            [perSubView removeFromSuperview];
        }
    }

    [xAxisView setBackgroundColor:self.graphBackgroundColor];

    UIColor *indicatorColor = [UIColor blackColor];
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(xAxisIndicatorColorForScrollableLineGraph:)])
    {
        indicatorColor = [self.delegate xAxisIndicatorColorForScrollableLineGraph:self];
    }

    BOOL isLongIndicator = NO;
    CGFloat lastOffset = 0.0f;
    NSUInteger dataRecordCount = [self.dataSource numberOfPointsInScrollableLineGraph:self];
    for (NSUInteger idx = 0;
         idx < dataRecordCount + self.graphXAxisLabelGap + 1;   // extend one more label
         idx += (self.graphXAxisLabelGap + 1)) {

        CGFloat perOffset = idx * self.graphWidthPerDataRecord;
        lastOffset = perOffset;

        isLongIndicator = !isLongIndicator;

        NSAttributedString *perLabelString = nil;
        if ([self.dataSource respondsToSelector:@selector(xAxisLabelStringForIndex:)]) {
            perLabelString = [self.dataSource xAxisLabelStringForIndex:idx];
        }
        else{
            perLabelString = [[NSAttributedString alloc] initWithString:@""];
        }
        CGRect perLabelFrame = CGRectMake(0, 0, 100, 100);
        perLabelFrame.size.width = ceilf(perLabelString.size.width);
        perLabelFrame.size.height = ceilf(perLabelString.size.height);

        UILabel *perLabel = [[UILabel alloc] initWithFrame:perLabelFrame];
        [perLabel setAttributedText:perLabelString];

        UIView *perIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 6)];
        [perIndicatorView setBackgroundColor:indicatorColor];

        [xAxisView addSubview:perLabel];
        [xAxisView addSubview:perIndicatorView];

        [perLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [perIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];

        [xAxisView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:perLabel
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:xAxisView
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0f
                                          constant:9.0f],
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
                                         attribute:NSLayoutAttributeCenterX
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:xAxisView
                                         attribute:NSLayoutAttributeLeading
                                        multiplier:1.0f
                                          constant:perOffset],

            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:xAxisView
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0f
                                          constant:0.0f],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:1.0f],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeHeight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1.0f
                                          constant:(isLongIndicator ? 6.0f : 3.0f)],
            [NSLayoutConstraint constraintWithItem:perIndicatorView
                                         attribute:NSLayoutAttributeCenterX
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:xAxisView
                                         attribute:NSLayoutAttributeLeading
                                        multiplier:1.0f
                                          constant:perOffset]
            ]];
    }

    UIView *axisLineView = [[UIView alloc] initWithFrame:xAxisView.frame];
    [axisLineView setBackgroundColor:indicatorColor];

    [xAxisView addSubview:axisLineView];
    [axisLineView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [xAxisView addConstraints:@[
        [NSLayoutConstraint constraintWithItem:axisLineView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:xAxisView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:axisLineView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:xAxisView
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0f
                                      constant:0.0f],
        [NSLayoutConstraint constraintWithItem:axisLineView
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:lastOffset],
        [NSLayoutConstraint constraintWithItem:axisLineView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0f
                                      constant:1.0f]
                                ]];
}

- (void)setupReferenceViews
{
    _referencingIndex = NSNotFound;
    [self setReferenceCircleView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, 9)]];
    [self.referenceCircleView setBackgroundColor:self.graphColor];
    [self.referenceCircleView.layer setCornerRadius:4.5f];
    [self.referenceCircleView setAlpha:0.0f];

    [self setReferencePopUpView:[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 200)]];
    [self.referencePopUpView setBackgroundColor:self.referencePopUpColor];
    [self.referencePopUpView.layer setCornerRadius:4.0f];
    [self.referencePopUpView setClipsToBounds:YES];
    [self.referencePopUpView setAlpha:0.0f];
}

- (void)setReferenceAtIndex:(NSUInteger)index
{
    if (index == NSNotFound) {
        [self removeReference];
        return;
    }

    if (!_horizontalReferenceLayer) {
        _horizontalReferenceLayer = [CAShapeLayer layer];
        [_horizontalReferenceLayer setBounds:self.scrollView.bounds];
        [_horizontalReferenceLayer setPosition:self.scrollView.center];
        [_horizontalReferenceLayer setStrokeColor:self.referenceLineColor.CGColor];
        [_horizontalReferenceLayer setFillColor:nil];
        [_horizontalReferenceLayer setLineWidth:1.0f];
        [_horizontalReferenceLayer setLineDashPattern:@[@3, @3]];
    }
    if (!_verticalReferenceLayer) {
        _verticalReferenceLayer = [CAShapeLayer layer];
        [_verticalReferenceLayer setBounds:self.scrollView.bounds];
        [_verticalReferenceLayer setPosition:self.scrollView.center];
        [_verticalReferenceLayer setStrokeColor:self.referenceLineColor.CGColor];
        [_verticalReferenceLayer setFillColor:nil];
        [_horizontalReferenceLayer setLineWidth:1.0f];
        [_verticalReferenceLayer setLineDashPattern:@[@3, @3]];
    }
    if (!_popUpTriangleLayer) {
        _popUpTriangleLayer = [CAShapeLayer layer];
        [_popUpTriangleLayer setBounds:self.scrollView.bounds];
        [_popUpTriangleLayer setPosition:self.scrollView.center];
        [_popUpTriangleLayer setStrokeColor:self.referencePopUpColor.CGColor];
        [_popUpTriangleLayer setFillColor:self.referencePopUpColor.CGColor];
    }

    [_horizontalReferenceLayer removeFromSuperlayer];
    [_verticalReferenceLayer removeFromSuperlayer];
    [_popUpTriangleLayer removeFromSuperlayer];

    _referencingIndex = index;

    CGFloat value = [self.dataSource scrollableLineGraph:self valueForPointAtIndex:index];
    CGFloat topOffset = self.scrollView.frame.size.height - [self bottomOffsetForValue:value];
    CGFloat leftOffset = self.graphWidthPerDataRecord * index +
                         self.graphYAxisWidth +
                         self.graphHorizontalPadding;

    // Horizontal Reference Line
    CGMutablePathRef horizontalPath = CGPathCreateMutable();
    CGPathMoveToPoint(horizontalPath, NULL, leftOffset, topOffset);
    CGPathAddLineToPoint(horizontalPath, NULL, 0, topOffset);
    [_horizontalReferenceLayer setPath:horizontalPath];
    CGPathRelease(horizontalPath);
    [self.scrollView.layer insertSublayer:_horizontalReferenceLayer atIndex:0];

    // Vertical Reference Line
    CGMutablePathRef verticalPath = CGPathCreateMutable();
    CGPathMoveToPoint(verticalPath, NULL, leftOffset, topOffset);
    CGPathAddLineToPoint(verticalPath, NULL, leftOffset,
                         self.scrollView.frame.size.height - self.graphXAxisHeight);
    [_verticalReferenceLayer setPath:verticalPath];
    CGPathRelease(verticalPath);
    [self.scrollView.layer insertSublayer:_verticalReferenceLayer atIndex:0];

    // Reference Circle View
    [self.referenceCircleView setCenter:CGPointMake(leftOffset, topOffset)];
    [self.referenceCircleView setAlpha:1.0f];

    // Reference Pop Up View
    CGRect currentFrame = self.referencePopUpView.frame;
    CGFloat frameWidth = 0.0f;
    CGFloat frameHeight = 0.0f;
    CGFloat popUpOffset = 16.0f;
    CGFloat popUpTriangleWidth = 15.0f;
    CGFloat popUpTriangleHeight = 7.0f;
    NSAttributedString *popUpString = nil;
    if ([self.dataSource respondsToSelector:@selector(referencePopUpStringForIndex:)]) {
        popUpString = [self.dataSource referencePopUpStringForIndex:index];
    }
    else{
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentCenter;

        popUpString =
            [[NSAttributedString alloc]
                initWithString:[NSString stringWithFormat:@"%.0f", value]
                    attributes:@{
                         NSParagraphStyleAttributeName: paragraphStyle,
                                   NSFontAttributeName: [UIFont systemFontOfSize:13.0f]
                         }];
    }

    frameWidth = currentFrame.size.width = MAX(85.0f, popUpString.size.width + 24.0f);
    frameHeight = currentFrame.size.height = MAX(46.0f, popUpString.size.height + 15.0f);

    [self.referencePopUpView setFrame:currentFrame];
    [self.referencePopUpView setAttributedText:popUpString];
    [self.referencePopUpView setAlpha:1.0f];


    CGMutablePathRef popUpTrianglePath = CGPathCreateMutable();

    if (topOffset > frameHeight + popUpTriangleHeight + popUpOffset * 2) {
        [self.referencePopUpView setCenter:
             CGPointMake(leftOffset, topOffset - currentFrame.size.height / 2.0f - popUpOffset)];

        CGPathMoveToPoint(popUpTrianglePath,
                          NULL,
                          leftOffset - popUpTriangleWidth / 2.0f,
                          topOffset - popUpOffset);
        CGPathAddLineToPoint(popUpTrianglePath,
                             NULL,
                             leftOffset + popUpTriangleWidth / 2.0f,
                             topOffset - popUpOffset);
        CGPathAddLineToPoint(popUpTrianglePath,
                             NULL,
                             leftOffset,
                             topOffset - popUpOffset + popUpTriangleHeight);

    }
    else{
        [self.referencePopUpView setCenter:
             CGPointMake(leftOffset, topOffset + currentFrame.size.height / 2.0f + popUpOffset)];

        CGPathMoveToPoint(popUpTrianglePath,
                          NULL,
                          leftOffset - popUpTriangleWidth / 2.0f,
                          topOffset + popUpOffset);
        CGPathAddLineToPoint(popUpTrianglePath,
                             NULL,
                             leftOffset + popUpTriangleWidth / 2.0f,
                             topOffset + popUpOffset);
        CGPathAddLineToPoint(popUpTrianglePath,
                             NULL,
                             leftOffset,
                             topOffset + popUpOffset - popUpTriangleHeight);
    }

   CGPathCloseSubpath(popUpTrianglePath);

    [_popUpTriangleLayer setPath:popUpTrianglePath];
    CGPathRelease(popUpTrianglePath);

    [self.scrollView.layer addSublayer:_popUpTriangleLayer];
}

- (void)removeReference
{
    _referencingIndex = NSNotFound;
    [_horizontalReferenceLayer removeFromSuperlayer];
    [_verticalReferenceLayer removeFromSuperlayer];
    [_popUpTriangleLayer removeFromSuperlayer];
    [self.referenceCircleView setAlpha:0.0f];
    [self.referencePopUpView setAlpha:0.0f];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGesture
{
    CGPoint location = [tapGesture locationInView:self.graphView];
    NSUInteger closestIndex = roundf(location.x / self.graphWidthPerDataRecord);

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(scrollableLineGraph:didTapOnIndex:)]) {
        [self.delegate scrollableLineGraph:self didTapOnIndex:closestIndex];
    }
}

// override
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tapGesture = (UITapGestureRecognizer *)gestureRecognizer;
        CGPoint location = [tapGesture locationInView:self.graphView];
        if (location.x >= 0) {
            NSUInteger closestIndex = roundf(location.x / self.graphWidthPerDataRecord);
            if (closestIndex < [self.dataSource numberOfPointsInScrollableLineGraph:self]) {
                CGFloat theValue = [self.dataSource scrollableLineGraph:self
                                                   valueForPointAtIndex:closestIndex];
                CGFloat topOffset = self.graphView.frame.size.height -
                                    [self bottomOffsetOnGraphForValue:theValue];

                return ABS(topOffset - location.y) < 20.0f;
            }
        }
        return NO;
    }

    return YES;
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
}

@end
