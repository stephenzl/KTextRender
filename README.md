KTextRender
===========

handle anchor click in text, using core text

Using:
- (IBAction)onTextRender:(id)sender
{
    UIFont *font = [UIFont systemFontOfSize:10.f];
    
    NSString *input = @"hello coretext[?],something[?],[this thing],ok ok ok[?]";
    CGSize size = [input sizeWithFont:font constrainedToSize:CGSizeMake(200, CGFLOAT_MAX)];
    
    KTextRender *render = [[[KTextRender alloc] initWithFrame:CGRectMake(100, 100, size.width, size.height)] autorelease];
    render.textFont = font;
    render.textColor = [UIColor blueColor];
    render.anchorColor = [UIColor redColor];
    [render setText:input];
    render.delegate = self;
    
    [self.view addSubview:render];
}

//delegate to notify which anchor is clicked
- (void)anchorClickAtIndex:(int)index
{
    DLog(@"%d is click",index);
}
