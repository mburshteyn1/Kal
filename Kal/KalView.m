/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"

@interface KalView ()
- (void)addSubviewsToHeaderView:(UIView *)headerView;
- (void)addSubviewsToContentView:(UIView *)contentView;
- (void)setHeaderTitleText:(NSString *)text;
@end

extern const CGSize kTileSize;
static const CGFloat kHeaderHeight = 44.f;
static const CGFloat kMonthLabelHeight = 17.f;
extern int minWidth = 0;
extern const kTabBarHeight;
extern const kNavigationBarHeight;

@implementation KalView

@synthesize delegate, tableView, extended;

UIButton* previousDayButton;
UIButton *nextDayButton;
UIView *headerView;
UIView *weekdayView;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate logic:(KalLogic *)theLogic
{
    if ((self = [super initWithFrame:frame])) {
        extended = YES;
        delegate = theDelegate;
        logic = [theLogic retain];
        [logic addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor whiteColor];
        minWidth = MIN([[UIScreen mainScreen] applicationFrame].size.height, [[UIScreen mainScreen] applicationFrame].size.width);

        UIView *contentView = [[[UIView alloc] initWithFrame:CGRectMake(0.f, kHeaderHeight, frame.size.width, frame.size.height - kNavigationBarHeight - kTabBarHeight)] autorelease];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubviewsToContentView:contentView];
        [self addSubview:contentView];
        
        headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, kHeaderHeight)] autorelease];
        headerView.backgroundColor = [UIColor grayColor];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubviewsToHeaderView:headerView];
        [self addSubview:headerView];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
        headerTitleLabel.userInteractionEnabled = YES;
        [headerTitleLabel addGestureRecognizer:tap];
        
        [self willRotateToInterfaceOrientation:[UIDevice currentDevice].orientation duration:0];
        //
        //      UISwipeGestureRecognizer* swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
        //      [swipeUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
        //      gridView.userInteractionEnabled = YES;
        //      [gridView addGestureRecognizer:swipeUp];
        //      //[tableView addGestureRecognizer:swipeUp];
        //
        //      UISwipeGestureRecognizer* swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
        //      [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
        //      [headerTitleLabel addGestureRecognizer:swipeDown];
        //
        //      UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
        //      [swipeLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
        //      [tableView addGestureRecognizer:swipeLeft];
        //
        //      UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
        //      [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
        //      [tableView addGestureRecognizer:swipeRight];
    }
    
    return self;
}


- (IBAction)handleTapGesture:(UIPanGestureRecognizer *)sender {
    if (!extended )
    {
        [UIView animateWithDuration:.5 animations:^{[gridView setTop:0];}];
        extended = YES;
        [previousDayButton setHidden:YES];
        [nextDayButton setHidden:YES];
        [self setHeaderTitleText:[logic selectedMonthNameAndYear]];
    }
    else
    {
        [UIView animateWithDuration:.5 animations:^{
            //            if (gridView.height > 222)
            //                [gridView setTop:-265];
            //            else
            //            [gridView setTop:-221];
            [gridView setTop:-gridView.frame.size.height + .5f];
        }];
        //[headerView setHeight:kHeaderHeight - 15.f];
        //[headerView clipsToBounds];
        extended = NO;
        [previousDayButton setHidden:NO];
        [nextDayButton setHidden:NO];
        [self setHeaderTitleText:[logic selectedDayMonthNameAndYear:gridView.selectedDate]];
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer*)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionUp && gridView.top == 0)
    {
        [UIView animateWithDuration:.5 animations:^{
            if (gridView.height > 222)
                [gridView setTop:-265];
            else
                [gridView setTop:-221];
        }];
        [headerView setHeight:kHeaderHeight - 15.f];
        [headerView clipsToBounds];
        extended = NO;
        [previousDayButton setHidden:NO];
        [nextDayButton setHidden:NO];
        [self setHeaderTitleText:[logic selectedDayMonthNameAndYear:gridView.selectedDate]];
    }
    else if (sender.direction == UISwipeGestureRecognizerDirectionDown && gridView.top <0)
    {
        [UIView animateWithDuration:.5 animations:^{[gridView setTop:0];}];
        extended = YES;
        [previousDayButton setHidden:YES];
        [nextDayButton setHidden:YES];
        [self setHeaderTitleText:[logic selectedMonthNameAndYear]];
    }
    else if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        [self showFollowingDay];
    }
    else if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        [self showPreviousDay];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    [NSException raise:@"Incomplete initializer" format:@"KalView must be initialized with a delegate and a KalLogic. Use the initWithFrame:delegate:logic: method."];
    return nil;
}

- (void)redrawEntireMonth { [self jumpToSelectedMonth]; }

- (void)slideDown { [gridView slideDown]; }
- (void)slideUp { [gridView slideUp]; }

- (void)showPreviousMonth
{
    if (!gridView.transitioning)
        [delegate showPreviousMonth];
    if (!extended)
    {
        extended = YES;
        [self handleTapGesture:nil];
    }
}

- (void)showFollowingMonth
{
    if (!gridView.transitioning)
        [delegate showFollowingMonth];
    if (!extended)
    {
        extended = YES;
        [self handleTapGesture:nil];
    }
}

- (void)showPreviousDay
{
    NSDate* tempDate = gridView.selectedDate.NSDate;
    tempDate = [tempDate dateByAddingTimeInterval:60*60*24*-1];
    KalDate* date = [KalDate dateFromNSDate:tempDate];
    if (gridView.selectedDate.month > date.month)
        [self showPreviousMonth];
    [delegate didSelectDate:date];
    [gridView selectDate:date];
}

- (void)showFollowingDay
{
    NSDate* tempDate = gridView.selectedDate.NSDate;
    tempDate = [tempDate dateByAddingTimeInterval:60*60*24*1];
    KalDate* date = [KalDate dateFromNSDate:tempDate];
    if (gridView.selectedDate.month < date.month)
        [self showFollowingMonth];
    [delegate didSelectDate:date];
    [gridView selectDate:date];
}

- (void)highlightWeekday:(KalDate*)date
{
    int x = 1;
    for (UILabel* lbl in [weekdayView subviews]) {
        lbl.textColor = [UIColor blackColor];
        if (x == [date dayOfWeek])
        {
            lbl.textColor = [UIColor colorWithRed:191.0/255 green:0/255 blue:0/255 alpha:1.0];
        }
        x++;
    }
    UILabel* lbl = [[weekdayView subviews] objectAtIndex:[date dayOfWeek] - 1];
    lbl.textColor = [UIColor redColor];
}

- (void)addSubviewsToHeaderView:(UIView *)headerView
{
    const CGFloat kChangeMonthButtonWidth = 46.0f;
    const CGFloat kChangeMonthButtonHeight = 30.0f;
    const CGFloat kMonthLabelWidth = 200.0f;
    const CGFloat kHeaderVerticalAdjust = 3.f;
    
    headerView.backgroundColor = [UIColor colorWithRed:247.0/255 green:247.0/255 blue:247.0/255 alpha:247.0/255];
    
    // Create the previous month button on the left side of the view
    CGRect previousMonthButtonFrame = CGRectMake(self.left,
                                                 kHeaderVerticalAdjust,
                                                 kChangeMonthButtonWidth,
                                                 kChangeMonthButtonHeight);
    UIButton *previousMonthButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
    [previousMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_left_arrow.png"] forState:UIControlStateNormal];
    previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:previousMonthButton];
    [previousMonthButton release];
    
    previousDayButton = [[UIButton alloc] initWithFrame:previousMonthButtonFrame];
    [previousDayButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_left_arrow.png"] forState:UIControlStateNormal];
    previousDayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    previousDayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [previousDayButton addTarget:self action:@selector(showPreviousDay) forControlEvents:UIControlEventTouchUpInside];
    [previousDayButton setHidden:YES];
    [headerView addSubview:previousDayButton];
    [previousDayButton release];
    
    // Draw the selected month name centered and at the top of the view
    CGRect monthLabelFrame = CGRectMake((self.width/2.0f) - (kMonthLabelWidth/2.0f),
                                        kHeaderVerticalAdjust,
                                        kMonthLabelWidth,
                                        kMonthLabelHeight);
    headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
    headerTitleLabel.backgroundColor = [UIColor clearColor];
    headerTitleLabel.font = [UIFont systemFontOfSize:18.f];
    headerTitleLabel.textAlignment = UITextAlignmentCenter;
    headerTitleLabel.textColor = [UIColor blackColor];
    headerTitleLabel.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self setHeaderTitleText:[logic selectedMonthNameAndYear]];
    [headerView addSubview:headerTitleLabel];
    
    // Create the next month button on the right side of the view
    CGRect nextMonthButtonFrame = CGRectMake(self.width - kChangeMonthButtonWidth,
                                             kHeaderVerticalAdjust,
                                             kChangeMonthButtonWidth,
                                             kChangeMonthButtonHeight);
    UIButton *nextMonthButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
    [nextMonthButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"] forState:UIControlStateNormal];
    nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [nextMonthButton addTarget:self action:@selector(showFollowingMonth) forControlEvents:UIControlEventTouchUpInside];
    nextMonthButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:nextMonthButton];
    [nextMonthButton release];
    
    nextDayButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
    [nextDayButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"] forState:UIControlStateNormal];
    nextDayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    nextDayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [nextDayButton addTarget:self action:@selector(showFollowingDay) forControlEvents:UIControlEventTouchUpInside];
    [nextDayButton setHidden: YES];
    nextDayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:nextDayButton];
    [nextDayButton release];
    
    // Add column labels for each weekday (adjusting based on the current locale's first weekday)
    NSArray *weekdayNames = [[[[NSDateFormatter alloc] init] autorelease] veryShortWeekdaySymbols];
    NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
    NSUInteger i = firstWeekday - 1;
    CGRect frame = headerView.frame;
    frame.size.width = minWidth;
    weekdayView = [[UIView alloc] initWithFrame:frame];
    CGPoint center = weekdayView.center;
    center.x = headerView.center.x;
    weekdayView.center = center;
    weekdayView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    for (CGFloat xOffset = 0.f; xOffset < weekdayView.width; xOffset += kTileSize.width, i = (i+1)%7) {
        //if (weekdayView.width - xOffset >= kTileSize.width)
        {
            CGRect weekdayFrame = CGRectMake(xOffset, 30.f, kTileSize.width, kHeaderHeight - 29.f);
            UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
            weekdayLabel.backgroundColor = [UIColor clearColor];
            weekdayLabel.font = [UIFont systemFontOfSize:10.f];
            weekdayLabel.textAlignment = UITextAlignmentCenter;
            weekdayLabel.textColor = [UIColor blackColor];
            weekdayLabel.text = [weekdayNames objectAtIndex:i];
            //weekdayLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [weekdayView addSubview:weekdayLabel];
            [weekdayLabel release];
        }
    }
    [headerView insertSubview:weekdayView atIndex:0];
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
    //    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    //    {
    //        // Both the tile grid and the list of events will automatically lay themselves
    //        // out to fit the # of weeks in the currently displayed month.
    //        // So the only part of the frame that we need to specify is the width.
    //        CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0.f, 0.f, self.width/2.0, self.height);
    //
    //        // The tile grid (the calendar body)
    //        gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame logic:logic delegate:delegate];
    //        [gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    //        [contentView addSubview:gridView];
    //
    //        // The list of events for the selected day
    //        CGRect fullWidthAutomaticLayoutFrame2 = CGRectMake(self.width/2.0, 0.f, self.width/2.0, self.height);
    //
    //        tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame2 style:UITableViewStylePlain];
    //        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //        [contentView addSubview:tableView];
    //
    //        // Trigger the initial KVO update to finish the contentView layout
    //        [gridView sizeToFit];
    //        return;
    //    }
    
    
    // Both the tile grid and the list of events will automatically lay themselves
    // out to fit the # of weeks in the currently displayed month.
    // So the only part of the frame that we need to specify is the width.
    CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0.f, 0.f, self.width, 0.f);
    
    // The tile grid (the calendar body)
    gridView = [[KalGridView alloc] initWithFrame:fullWidthAutomaticLayoutFrame logic:logic delegate:delegate];
    [gridView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    [contentView addSubview:gridView];
    
    // The list of events for the selected day
    tableView = [[UITableView alloc] initWithFrame:fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [contentView addSubview:tableView];
    
    // Trigger the initial KVO update to finish the contentView layout
    [gridView sizeToFit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == gridView && [keyPath isEqualToString:@"frame"]) {
        
        /* Animate tableView filling the remaining space after the
         * gridView expanded or contracted to fit the # of weeks
         * for the month that is being displayed.
         *
         * This observer method will be called when gridView's height
         * changes, which we know to occur inside a Core Animation
         * transaction. Hence, when I set the "frame" property on
         * tableView here, I do not need to wrap it in a
         * [UIView beginAnimations:context:].
         */
        CGFloat gridBottom = gridView.top + gridView.height;
        CGRect frame = tableView.frame;
        frame.origin.y = gridBottom;
        frame.size.height = tableView.superview.height - gridBottom;
        tableView.frame = frame;
        shadowView.top = gridBottom;
        
    } else if ([keyPath isEqualToString:@"selectedMonthNameAndYear"]) {
        [self setHeaderTitleText:[change objectForKey:NSKeyValueChangeNewKey]];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setHeaderTitleText:(NSString *)text
{
    [headerTitleLabel setText:text];
    [headerTitleLabel sizeToFit];
    headerTitleLabel.left = floorf(self.width/2.f - headerTitleLabel.width/2.f);
}

- (void)jumpToSelectedMonth { [gridView jumpToSelectedMonth]; }

- (void)selectDate:(KalDate *)date{
    [gridView selectDate:date];
}

- (BOOL)isSliding { return gridView.transitioning; }

- (void)markTilesForDates:(NSArray *)dates { [gridView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return gridView.selectedDate; }

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        extended = YES;
        headerTitleLabel.userInteractionEnabled = NO;
    }
    else
    {
        extended = NO;
        headerTitleLabel.userInteractionEnabled = YES;
    }
    [self handleTapGesture:nil];
}

- (void)dealloc
{
    [logic removeObserver:self forKeyPath:@"selectedMonthNameAndYear"];
    [logic release];
    
    [headerTitleLabel release];
    [gridView removeObserver:self forKeyPath:@"frame"];
    [gridView release];
    [tableView release];
    [shadowView release];
    [super dealloc];
}
@end
