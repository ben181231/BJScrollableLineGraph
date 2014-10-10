//
//  ViewController.m
//  BJScrollableLineGraph Demo
//
//  Created by Ben Lei on 7/10/14.
//  Copyright (c) 2014 BenJ Lei. All rights reserved.
//

#import "ViewController.h"

#define DEFAULT_DATA_COUNT 350
#define MAX_DATA_COUNT 350
#define AVAILABLE_STEP_CHANGE 20

#define GRAPH_WIDTH_INIT_DIFFERENCE (40.0f)

#define GRAPH_WIDTH_PER_DATA (30.0f)

#define GRAPH_COLOR [UIColor colorWithRed:31.0/255.0 green:187.0/255.0 blue:166.0/255.0 alpha:1.0]

@interface ViewController ()

@property (strong, nonatomic) NSArray *privateData;
@property (strong, nonatomic) NSArray *graphDataArray;
@property (strong, nonatomic) NSNumber *dataCount;

@property (weak, nonatomic) IBOutlet BJScrollableLineGraphView *scrollableLineGraph;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.scrollableLineGraph setGraphWidthPerDataRecord:10.0f];
    [self.scrollableLineGraph setGraphBackgroundColor:[UIColor clearColor]];
    [self.scrollableLineGraph setGraphColor:[UIColor colorWithRed:0.0f
                                                            green:161.0f/255
                                                             blue:229.0f/255
                                                            alpha:1.0f]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.scrollableLineGraph setReferenceAtIndex:(DEFAULT_DATA_COUNT - 1)];
}

- (NSArray *)privateData
{
    if(!_privateData){
        NSMutableArray *privateDataMutable =
            [[NSMutableArray alloc] initWithCapacity:MAX_DATA_COUNT];
        [privateDataMutable addObject:@([self randomInt])];
        for (int idx = 1; idx < MAX_DATA_COUNT; idx++) {
            NSInteger perData = [self randomIntFromInt:[privateDataMutable[idx-1] integerValue]];
            [privateDataMutable addObject:@(perData)];
        }

        _privateData = privateDataMutable;
    }

    return _privateData;
}

- (NSArray *)graphDataArray
{
    if(!_graphDataArray){
        NSUInteger count = [self.dataCount integerValue];
        NSMutableArray *graphDataArrayMutable = [[NSMutableArray alloc] initWithCapacity:count];
        for (int idx = 0; idx < count; idx++) {
            [graphDataArrayMutable addObject:[self.privateData objectAtIndex:idx]];
        }

        _graphDataArray = graphDataArrayMutable;
    }

    return _graphDataArray;
}

- (NSNumber *)dataCount
{
    if(!_dataCount){
        _dataCount = @(DEFAULT_DATA_COUNT);
    }

    return _dataCount;
}

- (NSInteger)randomInt
{
    return (int)(arc4random() % 350) - 50;// Random integer within -50 ~ 300;
}

- (NSInteger)randomIntFromInt:(NSInteger)theInteger
{
    return theInteger + (arc4random() % (AVAILABLE_STEP_CHANGE * 2)) - AVAILABLE_STEP_CHANGE;
}

- (IBAction)refreshButtonDidTap:(UIButton *)button
{
    [self setPrivateData:nil];
    [self setGraphDataArray:nil];
    if(self.scrollableLineGraph){
        [self.scrollableLineGraph reloadGraph];
    }
}


#ifdef __IPHONE_8_0
// override
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (self.scrollableLineGraph) {
        [self.scrollableLineGraph reloadGraph];
    }
}
#else
// override
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.scrollableLineGraph) {
        [self.scrollableLineGraph reloadGraph];
    }
}
#endif

#pragma mark - BJScrollableLineGraphViewDataSource

- (NSInteger)numberOfPointsInScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return [self.graphDataArray count];
}

- (CGFloat)scrollableLineGraph:(BJScrollableLineGraphView *)graph
          valueForPointAtIndex:(NSInteger)index
{
    return [[self.graphDataArray objectAtIndex:index] floatValue];
}

- (NSAttributedString *)yAxisLabelStringForValue:(CGFloat)value
{
    NSString *valueString = [NSString stringWithFormat:@"%.0f", roundf(value)];
    NSRange wholeStringRange = NSMakeRange(0, [valueString length]);
    NSMutableAttributedString *resultStringMutable =
        [[NSMutableAttributedString alloc] initWithString:valueString];

    [resultStringMutable addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"GillSans" size:10.0f]
                                range:wholeStringRange];
    [resultStringMutable addAttribute:NSForegroundColorAttributeName
                                value:[UIColor colorWithWhite:102.0f/255 alpha:1.0f]
                                range:wholeStringRange];

    return resultStringMutable;
}

- (NSAttributedString *)xAxisLabelStringForIndex:(NSUInteger)index
{
    NSString *valueString = [NSString stringWithFormat:@"%u", (unsigned)index];
    NSRange wholeStringRange = NSMakeRange(0, [valueString length]);
    NSMutableAttributedString *resultStringMutable =
        [[NSMutableAttributedString alloc] initWithString:valueString];

    [resultStringMutable addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"GillSans" size:10.0f]
                                range:wholeStringRange];
    [resultStringMutable addAttribute:NSForegroundColorAttributeName
                                value:[UIColor whiteColor]
                                range:wholeStringRange];

    return resultStringMutable;
}

#pragma mark - BJScrollableLineGraphViewDelegate
- (CGFloat)maxValueForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    CGFloat maxValue = [[self.privateData valueForKeyPath:@"@max.intValue"] floatValue];
    return maxValue > 0 ? 1.2f * maxValue : 0.8f * maxValue;
}

- (CGFloat)minValueForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    CGFloat minValue = [[self.privateData valueForKeyPath:@"@min.intValue"] floatValue];
    return  minValue > 0 ? 0.8f * minValue : 1.2f * minValue;
}

- (UIColor *)yAxisColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return [UIColor lightGrayColor];
}

- (UIColor *)yAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return [UIColor colorWithWhite:102.0f/255 alpha:1.0f];
}

- (UIColor *)xAxisIndicatorColorForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return [UIColor whiteColor];
}

- (NSUInteger)xAxisLabelGapForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return 4;
}

- (CGFloat)yAxisWidthForScrollableLineGraph:(BJScrollableLineGraphView *)graph
{
    return 33.0f;
}

- (void)scrollableLineGraph:(BJScrollableLineGraphView *)graph didTapOnIndex:(NSUInteger)index
{
    [graph setReferenceAtIndex:index];
}

@end
