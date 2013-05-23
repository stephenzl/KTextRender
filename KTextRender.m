//
//  KTextRender.m
//  KFramework
//
//  Created by KevinHo on 13-5-22.
//  Copyright (c) 2013年 Kv.h. All rights reserved.
//

#import "KTextRender.h"
#import <CoreText/CoreText.h>

@interface KTextRender()

@property (nonatomic,retain) NSMutableArray *lineInfo;
@property (nonatomic,retain) NSMutableAttributedString *attrText;
@property (nonatomic,assign) CTFrameRef textFrame;
@property (nonatomic,assign) CFArrayRef lines;

@property (nonatomic,assign) CGFloat fontSize;
@property (nonatomic,assign) NSString *fontName;

@end

@implementation KTextRender
@synthesize lineInfo = _lineInfo;
@synthesize attrText = _attrText;
@synthesize textFrame = _textFrame;
@synthesize delegate = _delegate;
@synthesize textColor = _textColor;
@synthesize anchor = _anchor;
@synthesize anchorColor = _anchorColor;
@synthesize textFont = _textFont;
@synthesize fontSize = _textSize;
@synthesize fontName = _fontName;


- (void)setText:(NSString *)text
{
    _sourceText = text;
    self.attrText = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textColor = [UIColor blackColor];
        self.anchorColor = [UIColor redColor];
        self.textFont = [UIFont systemFontOfSize:20];
        self.anchor = @"[?]";
        
        self.backgroundColor = [UIColor clearColor];
        self.lineInfo = [NSMutableArray array];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.attrText) {
        return;
    }
    
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.textFont.fontName, self.textFont.pointSize, NULL);
    
    NSDictionary *styleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                (id)self.textColor.CGColor,kCTForegroundColorAttributeName,
                                (id)fontRef,kCTFontAttributeName,
                                nil];
    
    [self.attrText setAttributes:styleAttrs range:NSMakeRange(0, self.attrText.length)];
    
    
    //set up coordinate system
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    
    //do drawing
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.anchor options:0 error:NULL];
    
    
    NSDictionary *anchorStyleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                (id)self.anchorColor.CGColor,kCTForegroundColorAttributeName,
                                (id)fontRef,kCTFontAttributeName,
                                nil];
    
    __block int idx = 0;
    [regex enumerateMatchesInString:self.attrText.string options:0 range:NSMakeRange(0, self.attrText.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange matchRange = result.range;

        [self.attrText setAttributes:anchorStyleAttrs range:NSMakeRange(matchRange.location-1, 3)];
        [self.attrText addAttribute:@"Slot" value:[NSNumber numberWithInt:idx] range:matchRange];
        
        idx ++;
    }];
    
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attrText);
    self.textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, self.attrText.length), path, NULL);
    CTFrameDraw(self.textFrame, context);
    
    CGRect frameBoundingBox = CGPathGetBoundingBox(path);
    
    self.lines = CTFrameGetLines(self.textFrame);
    CGPoint origines[CFArrayGetCount(self.lines)];
    CTFrameGetLineOrigins(self.textFrame, CFRangeMake(0, 0), origines);
    CFIndex linesCount = CFArrayGetCount(self.lines);
    
    for (int lineIndex = 0; lineIndex < linesCount; lineIndex ++) {
        
        CGContextSetTextPosition(context, origines[lineIndex].x+frameBoundingBox.origin.x, frameBoundingBox.origin.y + origines[lineIndex].y);
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(self.lines, lineIndex);
        CGRect lineBounds = CTLineGetImageBounds(line, context);
        lineBounds.origin.y = self.frame.size.height - origines[lineIndex].y - lineBounds.size.height;
        
        CFRange lineRange = CTLineGetStringRange(line);
        
        [self.lineInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  NSStringFromRange(NSMakeRange(lineRange.location, lineRange.length)),
                                  @"Range",NSStringFromCGRect(lineBounds),@"Bounds"
                                  , nil]];
    }
    
    
    CFRelease(fontRef);
    CFRelease(path);
    CFRelease(framesetter);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    CGPoint tapLocation = [[touches anyObject] locationInView:self];
    for (NSDictionary *line in self.lineInfo) {
        
        CFIndex idx = [self.lineInfo indexOfObject:line];
        CTLineRef lineRef = (CTLineRef)CFArrayGetValueAtIndex(self.lines, idx);
        CGRect lineBounds = CGRectFromString([line valueForKey:@"Bounds"]);
        if (CGRectContainsPoint(lineBounds, tapLocation)) {
            NSRange longestRange;
            
            CFIndex wordIndex = CTLineGetStringIndexForPosition(lineRef, tapLocation);
            
            
            NSDictionary *attributes = [self.attrText attributesAtIndex:wordIndex longestEffectiveRange:&longestRange inRange:NSMakeRange(wordIndex, 1)];
            
            NSNumber *num = [attributes valueForKey:@"Slot"];
            if (num != nil) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(slotClickAtIndex:)])
                {
                    [self.delegate slotClickAtIndex:[num intValue]];
                }
                
                break;
            }
            break;
        }
    }
}



- (void)dealloc
{
    [_sourceText release];
    [_textFont release];
    [_textColor release];
    [_anchorColor release];
    [_anchor release];
    
    [_attrText release];
    [_lineInfo release];
    CFRelease(_textFrame);
    CFRelease(_lines);
    _delegate = nil;
    [super dealloc];
}

@end
