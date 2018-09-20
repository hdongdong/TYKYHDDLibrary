//
//  CTLoopViewController.m
//
//  Created by 腾 on 16/9/3.
//  Copyright © 2016年 腾. All rights reserved.
//

#import "CTAutoLoopViewController.h"

@interface CTAutoLoopViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIScrollViewDelegate>

@property (assign, nonatomic) float loopOnceTime;//循环一次时间
@property (assign, nonatomic) CGSize itemSize;//单元格大小
@property (copy, nonatomic) NSArray *dataArray;//数据
@property (strong, nonatomic) NSTimer *timer;//定时器
@property (assign, nonatomic) CTLoopScollDirection loopScollDirection;//滚动方向
@property (assign, nonatomic) CTLoopCellDisplayModal cellDisplayModal;//单元格显示视图模式
@property (strong, nonatomic) UILabel *pageLabel;//页码显示

@end

@implementation CTAutoLoopViewController

static NSString * const kAutoLoopReuseIdentifier = @"kAutoLoopReuseIdentifier";

+ (instancetype)initWithFrame:(CGRect)frame
                 onceLoopTime:(float)onceLoopTime
             cellDisplayModal:(CTLoopCellDisplayModal)cellDisplayModal
                scollDiretion:(CTLoopScollDirection)loopScollDirection{
    return [[self alloc] initWithFrame:frame
                          onceLoopTime:onceLoopTime
                      cellDisplayModal:cellDisplayModal
                         scollDiretion:loopScollDirection];
}
- (instancetype)initWithFrame:(CGRect)frame
                 onceLoopTime:(float)onceLoopTime
             cellDisplayModal:(CTLoopCellDisplayModal)cellDisplayModal
                scollDiretion:(CTLoopScollDirection)loopScollDirection{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.itemSize = frame.size;
        self.loopOnceTime = onceLoopTime?onceLoopTime:3.0;
        self.loopScollDirection = loopScollDirection;
        self.cellDisplayModal = cellDisplayModal;
        [self initCollectionWithFrame:frame];
    }
    return self;
}

//初始化
- (void)initCollectionWithFrame:(CGRect)frame{
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kAutoLoopReuseIdentifier];

    //图片广告 添加页码指示
    if (_loopScollDirection==CTLoopScollDirectionHorizontal) {//水平滚动

        [self.view addSubview:self.pageLabel];
    }else{
        //竖向滚动
        self.pageCT.frame = CGRectMake(frame.size.width/2-20, frame.size.height/2-10, frame.size.width, 20);
        self.pageCT.transform = CGAffineTransformMakeRotation(M_PI/2);
        [self.view addSubview:self.pageCT];

    }

}
- (void)viewDidLoad {
    [super viewDidLoad];
}
//添加内容
- (void)addLocalModels:(NSArray *)array{
    if (!array||![array isKindOfClass:[NSArray class]]) {
        return;
    }
    self.dataArray = array;

    if (_loopScollDirection==CTLoopScollDirectionHorizontal){
        self.pageLabel.text = [NSString stringWithFormat:@"1/%lu",(unsigned long)self.dataArray.count];

    }else{
        self.pageCT.numberOfPages = self.dataArray.count;

    }
    [self.collectionView reloadData];

    self.pageLabel.hidden = !self.dataArray.count;

    if (self.dataArray.count>1) {
        [self.timer fire];
    }else{
  
        [self stopTimer];
    }

}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.dataArray.count<2) {
        return self.dataArray.count;
    }
    return self.dataArray.count+1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAutoLoopReuseIdentifier forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (self.cellDisplayModal==CTLoopCellDisplayCustomView) {
        if ([self.delegate respondsToSelector:@selector(CTAutoLoopViewController:cellForItemAtIndexPath:)]) {
            
            NSIndexPath *newIndex = indexPath;
            if (newIndex.row == self.dataArray.count) {
                newIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            }
            UIView *customView = [self.delegate CTAutoLoopViewController:cell cellForItemAtIndexPath:newIndex];
            [cell.contentView addSubview:customView];
        }
        return cell;
        
    }else{
        id model = nil;
        if (indexPath.row == self.dataArray.count) {
            model = self.dataArray[0];
        }else{
            model = self.dataArray[indexPath.row];
        }
        UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,_itemSize.width, _itemSize.height)];
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.clipsToBounds = YES;
        if ([model isKindOfClass:[UIImage class]]) {
            img.image = (UIImage *)model;
        }else if ([model isKindOfClass:[NSString class]]){
            img.image = [UIImage imageNamed:model];
            
        }
        [cell.contentView addSubview:img];
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.delegate respondsToSelector:@selector(CTAutoLoopViewController:didSelectItemAtIndexPath:)]) {
        NSIndexPath *newIndex = indexPath;
        if (newIndex.row == self.dataArray.count) {
            newIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        }
        [self.delegate CTAutoLoopViewController:collectionView didSelectItemAtIndexPath:newIndex];
    }
    
}

//自动滚动
- (void)nextPage
{
    if (!_dataArray) {
        return;
    }
    
    CGPoint offset = self.collectionView.contentOffset;
    NSInteger currentPage = 0;
    if (self.loopScollDirection==0) {
        currentPage = floor(offset.x / _itemSize.width);
    }else{
        currentPage = floor(offset.y / _itemSize.height);
    }
    if (currentPage != _dataArray.count) {
        NSInteger rowIndex = currentPage+1;
        if (rowIndex>_dataArray.count-1) {
            rowIndex = _dataArray.count-1;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:rowIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
//        NSLog(@"正在滚动%@",indexPath);
        
    }
    
}

-(void)stopTimer{
//    NSLog(@"定时器停止了");
    if (!_timer) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
    
}
//重置位置
- (void)resetContentOffset
{
    CGPoint offset = self.collectionView.contentOffset;
    NSInteger page = 0;
    if (self.loopScollDirection==0) {
        page = floor(offset.x / _itemSize.width);
    }else{
        page = floor(offset.y / _itemSize.height);
    }
    //当滚动到最底层时 复位到第一个
    if (page == _dataArray.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    if (page==0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_dataArray.count inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        
    }

}
//开始拖曳 停止定时器
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopTimer];
}
//手动滚动停止后调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self resetContentOffset];
    [self.timer fire];

}
//自动滚动停止后调用
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self resetContentOffset];
}
#pragma mark 滚动调用
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSInteger pageNum = 0;
    if (self.loopScollDirection==0) {
        pageNum = (scrollView.contentOffset.x - _itemSize.width / 2) / _itemSize.width + 1;

    }else{
        pageNum = (scrollView.contentOffset.y - _itemSize.height / 2) / _itemSize.height + 1;

    }
    if (pageNum==self.dataArray.count) {
        pageNum = 0;
    }
    if (_pageLabel) {
        _pageLabel.text = [NSString stringWithFormat:@"%ld/%lu",pageNum+1,(unsigned long)self.dataArray.count];
    }

    if (_pageCT) {
        _pageCT.currentPage = pageNum;

    }
}

- (UIPageControl *)pageCT{
    if (_pageCT ==nil) {
        _pageCT = [UIPageControl new];
        _pageCT.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageCT.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageCT.hidesForSinglePage = YES;
        
    }
    return _pageCT;
}
- (UICollectionView *)collectionView{
    if (_collectionView ==nil) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(self.view.frame.size.width , self.view.frame.size.height);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.sectionInset = UIEdgeInsetsZero;
        if (self.loopScollDirection==CTLoopScollDirectionHorizontal) {
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
        }else{
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
            
        }
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:layout];
        _collectionView.backgroundColor  = [UIColor whiteColor];
        _collectionView.pagingEnabled = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.directionalLockEnabled  = YES;
        
        [self.view addSubview:_collectionView];

    }
    return _collectionView;
}
- (UILabel *)pageLabel{
    if (_pageLabel==nil) {
        _pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-40, self.view.frame.size.height-30, 30, 20)];
        _pageLabel.textAlignment = NSTextAlignmentCenter;
        _pageLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _pageLabel.textColor = [UIColor whiteColor];
        _pageLabel.font = [UIFont systemFontOfSize:10];
        _pageLabel.layer.masksToBounds = YES;
        _pageLabel.layer.cornerRadius = 10.0;
        _pageLabel.hidden = YES;
        
    }
    return _pageLabel;
}
- (NSTimer *)timer{
    if (!_timer) {
        @autoreleasepool{
            _timer = [NSTimer timerWithTimeInterval:self.loopOnceTime target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];

        }
        
    }
    return _timer;
}
@end
