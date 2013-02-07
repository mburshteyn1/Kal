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

static const CGFloat kHeaderHeight = 44.f;
static const CGFloat kMonthLabelHeight = 17.f;

@implementation KalView

@synthesize delegate, tableView, extended;

UIButton* previousDayButton;
UIButton *nextDayButton;
UIView *headerView;

- (id)initWithFrame:(CGRect)frame delegate:(id<KalViewDelegate>)theDelegate logic:(KalLogic *)theLogic
{
  if ((self = [super initWithFrame:frame])) {
      extended = YES;
    delegate = theDelegate;
    logic = [theLogic retain];
    [logic addObserver:self forKeyPath:@"selectedMonthNameAndYear" options:NSKeyValueObservingOptionNew context:NULL];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
      UIView *contentView = [[[UIView alloc] initWithFrame:CGRectMake(0.f, kHeaderHeight, frame.size.width, frame.size.height - kHeaderHeight)] autorelease];
      contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
      [self addSubviewsToContentView:contentView];
      [self addSubview:contentView];
      
      headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, kHeaderHeight)] autorelease];
      headerView.backgroundColor = [UIColor grayColor];
      [self addSubviewsToHeaderView:headerView];
      [self addSubview:headerView];
      
      UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
      headerTitleLabel.userInteractionEnabled = YES;
      [headerTitleLabel addGestureRecognizer:tap];
      
      UISwipeGestureRecognizer* swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
      [swipeUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
      gridView.userInteractionEnabled = YES;
      [gridView addGestureRecognizer:swipeUp];
      //[tableView addGestureRecognizer:swipeUp];
      
      UISwipeGestureRecognizer* swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
      [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
      [headerTitleLabel addGestureRecognizer:swipeDown];
      
      UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
      [swipeLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
      [tableView addGestureRecognizer:swipeLeft];
      
      UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
      [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
      [tableView addGestureRecognizer:swipeRight];
  }
  
  return self;
}

- (IBAction)handleTapGesture:(UIPanGestureRecognizer *)sender {
    if (gridView.top < 0 )
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
}

- (void)showFollowingMonth
{
  if (!gridView.transitioning)
    [delegate showFollowingMonth];
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

- (void)addSubviewsToHeaderView:(UIView *)headerView
{
  const CGFloat kChangeMonthButtonWidth = 46.0f;
  const CGFloat kChangeMonthButtonHeight = 30.0f;
  const CGFloat kMonthLabelWidth = 200.0f;
  const CGFloat kHeaderVerticalAdjust = 3.f;
  
  // Header background gradient
  UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"]];
  CGRect imageFrame = headerView.frame;
  imageFrame.origin = CGPointZero;
  backgroundView.frame = imageFrame;
  [headerView addSubview:backgroundView];
  [backgroundView release];
  
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
  headerTitleLabel.font = [UIFont boldSystemFontOfSize:22.f];
  headerTitleLabel.textAlignment = UITextAlignmentCenter;
  headerTitleLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_header_text_fill.png"]];
  headerTitleLabel.shadowColor = [UIColor whiteColor];
  headerTitleLabel.shadowOffset = CGSizeMake(0.f, 1.f);
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
  [headerView addSubview:nextMonthButton];
  [nextMonthButton release];
    
    nextDayButton = [[UIButton alloc] initWithFrame:nextMonthButtonFrame];
    [nextDayButton setImage:[UIImage imageNamed:@"Kal.bundle/kal_right_arrow.png"] forState:UIControlStateNormal];
    nextDayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    nextDayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [nextDayButton addTarget:self action:@selector(showFollowingDay) forControlEvents:UIControlEventTouchUpInside];
    [nextDayButton setHidden: YES];
    [headerView addSubview:nextDayButton];
    [nextDayButton release];
  
  // Add column labels for each weekday (adjusting based on the current locale's first weekday)
  NSArray *weekdayNames = [[[[NSDateFormatter alloc] init] autorelease] shortWeekdaySymbols];
  NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
  NSUInteger i = firstWeekday - 1;
  for (CGFloat xOffset = 0.f; xOffset < headerView.width; xOffset += 46.f, i = (i+1)%7) {
    CGRect weekdayFrame = CGRectMake(xOffset, 30.f, 46.f, kHeaderHeight - 29.f);
    UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
    weekdayLabel.backgroundColor = [UIColor clearColor];
    weekdayLabel.font = [UIFont boldSystemFontOfSize:10.f];
    weekdayLabel.textAlignment = UITextAlignmentCenter;
    weekdayLabel.textColor = [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:1.f];
    weekdayLabel.shadowColor = [UIColor whiteColor];
    weekdayLabel.shadowOffset = CGSizeMake(0.f, 1.f);
    weekdayLabel.text = [weekdayNames objectAtIndex:i];
    [headerView addSubview:weekdayLabel];
    [weekdayLabel release];
  }
}

- (void)addSubviewsToContentView:(UIView *)contentView
{
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
  
  // Drop shadow below tile grid and over the list of events for the selected day
  shadowView = [[UIImageView alloc] initWithFrame:fullWidthAutomaticLayoutFrame];
  shadowView.image = [UIImage imageNamed:@"Kal.bundle/kal_grid_shadow.png"];
  shadowView.height = shadowView.image.size.height;
  [contentView addSubview:shadowView];
  
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

- (void)selectDate:(KalDate *)date { [gridView selectDate:date]; }

- (BOOL)isSliding { return gridView.transitioning; }

- (void)markTilesForDates:(NSArray *)dates { [gridView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return gridView.selectedDate; }

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
