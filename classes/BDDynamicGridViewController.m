//
//  BDDynamicGridViewController.m
//  BDDynamicGridViewDemo
//
//
//  Copyright (c) 2012, Norsez Orankijanan (Bluedot) All Rights Reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation 
//  and/or other materials provided with the distribution.
//
//  3. Neither the name of Bluedot nor the names of its contributors may be used 
//  to endorse or promote products derived from this software without specific
//  prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//  POSSIBILITY OF SUCH DAMAGE.

#import "BDDynamicGridViewController.h"

#define kDefaultBorderWidth 5

@interface BDDynamicGridViewController  () <UITableViewDelegate, UITableViewDataSource>{
    UITableView *_tableView;
}
@end

@implementation BDDynamicGridViewController

- (id)init
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor blackColor];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.borderWidth = kDefaultBorderWidth;
    [self.view addSubview:_tableView];
    [_tableView reloadData];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    _tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [_tableView reloadData];
    return [super shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger total = (int) (((double)self.delegate.numberOfViews/self.delegate.numberOfColumns ));
    if (total * self.delegate.numberOfColumns < self.delegate.numberOfViews) {
        total = total + 1;
    }
    return total;
}



- (CGRect) rectForView:(UIView*)view
{
    if (self.gridLayoutStyle == BDDynamicGridLayoutStyleFill) {
        if (view.frame.size.width > view.frame.size.height) {
            return CGRectMake(0, 0, self.rowHeight * 3.0 / 2.0, self.rowHeight);
        }else {
            return CGRectMake(0, 0, self.rowHeight * 2.0 / 3.0, self.rowHeight);
        }
    }else if (self.gridLayoutStyle == BDDynamicGridLayoutStyleEven){
        return CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    }
    return CGRectZero;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.contentView.clipsToBounds = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
        longPress.numberOfTouchesRequired = 1;
        [cell.contentView addGestureRecognizer:longPress];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [cell.contentView addGestureRecognizer:doubleTap];
    }
    
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }
    
    NSUInteger numberOfColumns = self.delegate.numberOfColumns;
    NSUInteger start = indexPath.row * numberOfColumns;
    NSUInteger end = MIN(start + numberOfColumns, self.delegate.numberOfViews );

    for(int i = start; i < end; i++){
        UIView *viewToAdd = [self.delegate viewAtIndex:i];
        viewToAdd.frame = [self rectForView:viewToAdd];
        viewToAdd.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if  (self.gridLayoutStyle == BDDynamicGridLayoutStyleFill){
            viewToAdd.contentMode = UIViewContentModeScaleAspectFill;
        }else if(self.gridLayoutStyle == BDDynamicGridLayoutStyleEven){
            viewToAdd.contentMode = UIViewContentModeScaleAspectFit;
        }

        [cell.contentView addSubview:viewToAdd];        
        cell.contentView.tag = indexPath.row;        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //layout what's in the cell
    CGFloat aRowHeight = [self tableView:_tableView heightForRowAtIndexPath:indexPath];
    CGFloat totalWidth = 0;
    for (UIView* subview in cell.contentView.subviews){       
        totalWidth = totalWidth + subview.frame.size.width + (self.borderWidth * 2);
    }
    CGFloat widthScaling =  (cell.contentView.frame.size.width/totalWidth);
    CGFloat accumWidth = self.borderWidth;
    
    for (UIView* subview in cell.contentView.subviews){
        subview.frame = CGRectMake(0, 0, subview.frame.size.width * widthScaling, aRowHeight - (self.borderWidth * 2.0));
        subview.frame = CGRectOffset(subview.frame, accumWidth, 0);
        accumWidth = accumWidth + subview.frame.size.width + self.borderWidth;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.rowHeight>0?self.rowHeight:_tableView.rowHeight;
}

- (void)reloadData
{
    [_tableView reloadData];
}

#pragma mark - events

- (void)gesture:(UIGestureRecognizer*)gesture view:(UIView**)view viewIndex:(NSInteger*)viewIndex
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        NSUInteger row = gesture.view.tag;
        
        CGPoint tapPoint = [gesture locationInView:gesture.view];
        NSArray *viewsSortedByXDesc = [gesture.view.subviews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            UIView * v1 = obj1;
            UIView * v2 = obj2;
            return v1.frame.origin.x - v2.frame.origin.x;
        }];
        
        if (viewsSortedByXDesc.count == 1) {   
            *view = [viewsSortedByXDesc objectAtIndex:0];
            *viewIndex = (row * self.delegate.numberOfColumns);
            return;
        }
        
        UIView * tappedView = nil;
        NSUInteger index = 0;
        for (int i=1; i<viewsSortedByXDesc.count; i++) {
            UIView * prevView = [viewsSortedByXDesc objectAtIndex:i-1];
            UIView * curView = [viewsSortedByXDesc objectAtIndex:i];
            if (prevView.frame.origin.x < tapPoint.x &&
                tapPoint.x < curView.frame.origin.x) {
                tappedView = curView;
                index = i;
            }
        }
        if (tappedView==nil) {
            tappedView = [viewsSortedByXDesc objectAtIndex:0];
            index = viewsSortedByXDesc.count ;
        }
        
        index = index - 1;
        
        *view = tappedView;
        *viewIndex = ((row * self.delegate.numberOfColumns) + index);
    }
}

- (void)didLongPress:(UILongPressGestureRecognizer*)longPress
{
    if (longPress.state == UIGestureRecognizerStateRecognized) {
        UIView *view = nil;
        NSInteger viewIndex = -1;
        [self gesture:longPress view:&view viewIndex:&viewIndex];
        if (self.onLongPress) {
            self.onLongPress(view, viewIndex);
        }
    }

}

- (void)didDoubleTap:(UITapGestureRecognizer*)doubleTap
{
    if (doubleTap.state == UIGestureRecognizerStateRecognized) {
        UIView *view = nil;
        NSInteger viewIndex = -1;
        [self gesture:doubleTap view:&view viewIndex:&viewIndex];
        if (self.onDoubleTap) {
            self.onDoubleTap(view, viewIndex);
        }
    }

}


@synthesize borderWidth;
@synthesize delegate;
@synthesize rowHeight;
@synthesize onLongPress;
@synthesize onDoubleTap;
@synthesize gridLayoutStyle;
@end
