/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern CGSize kTileSize;

@implementation KalTileView

@synthesize date;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.autoresizingMask =  UIViewAutoresizingFlexibleWidth ;
        self.contentMode = UIViewContentModeRedraw;
        origin = frame.origin;
        [self resetState];
    }
    return self;
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, self.bounds);
    
    CGFloat fontSize = 18.f;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *shadowColor = nil;
    UIColor *textColor = nil;
    UIColor *circleColor = nil;
    UIImage *markerImage = nil;
    CGContextSelectFont(ctx, [font.fontName cStringUsingEncoding:NSUTF8StringEncoding], fontSize, kCGEncodingMacRoman);
    
    CGContextTranslateCTM(ctx, 0, kTileSize.height);
    CGContextScaleCTM(ctx, 1, -1);
    
    if ([self isToday] && self.selected) {
        textColor = [UIColor whiteColor];
        shadowColor = [UIColor blackColor];
        font = [UIFont boldSystemFontOfSize:fontSize];
        circleColor = [UIColor colorWithRed:191.0/255 green:0/255 blue:0/255 alpha:1.0];
    } else if ([self isToday] && !self.selected) {
        textColor = [UIColor colorWithRed:191.0/255 green:0/255 blue:0/255 alpha:1.0];
        shadowColor = [UIColor blackColor];
        font = [UIFont boldSystemFontOfSize:fontSize];
    } else if (self.selected) {
        textColor = [UIColor whiteColor];
        shadowColor = [UIColor blackColor];
        circleColor = [UIColor blueColor];
        font = [UIFont boldSystemFontOfSize:fontSize];
    } else if (self.belongsToAdjacentMonth) {
        textColor = [UIColor lightGrayColor];
        shadowColor = nil;
    } else {
        textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
        shadowColor = [UIColor whiteColor];
    }
    
    if (self.selected)
    {
        CGContextSetFillColor(ctx, CGColorGetComponents(circleColor.CGColor));
        CGRect circle = CGRectMake(roundf(0.5f * (kTileSize.width - 29.f)), 16, 29, 29);
        CGContextFillEllipseInRect(ctx, circle);
        CGContextFillPath(ctx);
    }
    
    NSUInteger n = [self.date day];
    NSString *dayText = [NSString stringWithFormat:@"%lu", (unsigned long)n];
    const char *day = [dayText cStringUsingEncoding:NSUTF8StringEncoding];
    CGSize textSize = [dayText sizeWithFont:font];
    CGFloat textX, textY;
    textX = roundf(0.5f * (kTileSize.width - textSize.width));
    textY = 6;//12.f + roundf(0.5f * (kTileSize.height - textSize.height));
    
    [textColor setFill];
    //CGContextSelectFont(ctx, font.familyName, font.pointSize,  kCGEncodingFontSpecific);
    //CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0.0f, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    
    [dayText drawAtPoint:CGPointMake(textX, textY) withFont:font];
    
    CGContextRestoreGState(ctx);
    
    if (self.highlighted) {
        [[UIColor colorWithWhite:0.25f alpha:0.3f] setFill];
        CGContextFillRect(ctx, CGRectMake(0.f, 0.f, kTileSize.width, kTileSize.height));
    }
    
    [[UIColor lightGrayColor] setFill];
    CGRect line;
    line.origin = CGPointMake(0.f, rect.size.height - 0.5f);
    line.size = CGSizeMake(self.width, 0.5f);
    CGContextFillRect(UIGraphicsGetCurrentContext(), line);
    
    if (flags.marked)
    {
        CGContextSetFillColor(ctx, CGColorGetComponents([UIColor lightGrayColor].CGColor));
        CGRect circle = CGRectMake(roundf(0.5f * (kTileSize.width - 4.f)), 5.f, 4.f, 4.f);
        CGContextFillEllipseInRect(ctx, circle);
        CGContextFillPath(ctx);
    }
}

- (void)resetState
{
    // realign to the grid
    CGRect frame = self.frame;
    frame.origin = origin;
    frame.size = kTileSize;
    self.frame = frame;
    
    [date release];
    date = nil;
    flags.type = KalTileTypeRegular;
    flags.highlighted = NO;
    flags.selected = NO;
    flags.marked = NO;
}

- (void)setDate:(KalDate *)aDate
{
    if (date == aDate)
        return;
    
    [date release];
    date = [aDate retain];
    
    [self setNeedsDisplay];
}

- (BOOL)isSelected { return flags.selected; }

- (void)setSelected:(BOOL)selected
{
    if (flags.selected == selected)
        return;
    
    flags.selected = selected;
    [self setNeedsDisplay];
}

- (BOOL)isHighlighted { return flags.highlighted; }

- (void)setHighlighted:(BOOL)highlighted
{
    if (flags.highlighted == highlighted)
        return;
    
    flags.highlighted = highlighted;
    [self setNeedsDisplay];
}

- (BOOL)isMarked { return flags.marked; }

- (void)setMarked:(BOOL)marked
{
    if (flags.marked == marked)
        return;
    
    flags.marked = marked;
    [self setNeedsDisplay];
    
}

- (KalTileType)type { return flags.type; }

- (void)setType:(KalTileType)tileType
{
    if (flags.type == tileType)
        return;
    
    flags.type = tileType;
    [self setNeedsDisplay];
}

- (BOOL)isToday { return flags.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return flags.type == KalTileTypeAdjacent; }

- (void)dealloc
{
    [date release];
    [super dealloc];
}

@end
