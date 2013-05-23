//
//  KTextRender.h
//  KFramework
//
//  Created by KevinHo on 13-5-22.
//  Copyright (c) 2013年 Kv.h. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KTextRenderDelegate <NSObject>

- (void)anchorClickAtIndex:(int)index;

@end

@interface KTextRender : UIView

//textcolor default UIColor blackColor
@property (nonatomic,retain) UIColor *textColor;
//textfont default systemfont:20
@property (nonatomic,retain) UIFont *textFont;
//anchor color default UIColor redColor
@property (nonatomic,retain) UIColor *anchorColor;
//anchor default @"[?]"
@property (nonatomic,retain) NSString *anchor;
@property (nonatomic,readonly) NSString *sourceText;
@property (nonatomic,assign) id<KTextRenderDelegate> delegate;

//@"hello coretext[?],something[?],[this thing]"
- (void)setText:(NSString *)text;

@end
