//
//  ImagePickerViewController.m
//  ImagePickerDemo
//
//  Created by 李世航 on 2018/6/14.
//  Copyright © 2018年 WeiYiAn. All rights reserved.
//

#import "LLPhotoBrowserViewController.h"
#import "LLPhotoBrowser.h"
#import "LLPhotoBrowserCell.h"
#import "LLPhotoBrowserManager.h"
#import "LLPhotoBrowserModel.h"
#import "LLPhotoEditPhotoViewController.h"
#import "LLPhotoBrowserBottomBar.h"
#import "LLPhotoBrowserTakePhotoCell.h"

@interface LLPhotoBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSMutableArray * dataSource;
@property (nonatomic, strong) LLPhotoBrowserBottomBar * bottomBar;
@property (nonatomic, strong) NSMutableArray * assets;
@property (nonatomic, strong) LLPhotoBrowserAlbumModel * albumModel;
@end

@implementation LLPhotoBrowserViewController {
    NSMutableArray * _cacheArray;   // 预加载缓存数组
    NSMutableArray * _preViewArray; // 预览视图数组
    BOOL selectOriginalImage;
}

#pragma mark ======= LifeCircle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self dataContainerInitialization];
    [self setupUI];
    [self getDataSource];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:YES];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0.9 alpha:0.1];
    //去掉导航栏底部的黑线
    self.navigationController.navigationBar.shadowImage = [UIImage new];

    CGFloat width = (ScreenWidth - 25) / 4 * 1.7;
    [[LLPhotoBrowserManager sharedPhotoBrowserManager] startCacheAssetWithArray:_cacheArray size:CGSizeMake(width, width)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    CGFloat width = (ScreenWidth - 25) / 4 * 1.7;
    [[LLPhotoBrowserManager sharedPhotoBrowserManager] stopCacheAssetWithArray:_cacheArray size:CGSizeMake(width, width)];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDarkContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"调用了图片viewcontroll----2");
    self.albumModel = nil;
    self.dataSource = nil;
    self.assets     = nil;
    _cacheArray     = nil;
    _preViewArray   = nil;
}

#pragma mark ======= UI
- (void)setupUI
{
    self.title = @"相册胶卷";
    [self.view ll_addSubViews:@[ self.bottomBar, self.collectionView ]];

    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"取消" forState:UIControlStateNormal];
    [button setTitleColor:random(51, 51, 51, 1) forState:UIControlStateNormal];
    button.frame           = CGRectMake(0, 0, 40, 30);
    button.titleLabel.font = FONT(15);
    WeakSelf(weakSelf);
    [button addCallBackAction:^(UIButton * button) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.bottomBar.originalButton.hidden = ![self config].allowSelectOriginal;
}

#pragma mark - Private Method
- (void)dataContainerInitialization
{
    LLPhotoBrowserManager * manager = [LLPhotoBrowserManager sharedPhotoBrowserManager];
    [manager setSortAscending:[self config].sortAscending];
    if (self.album) {
        self.albumModel = self.album;
    } else {
        self.albumModel = [manager getCameraRollAlbumList:[self config].allowSelectVideo
                                         allowSelectImage:[self config].allowSelectImage];
    }

    _cacheArray = [NSMutableArray array];
    [self.albumModel.models enumerateObjectsUsingBlock:^(LLPhotoBrowserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [_cacheArray addObject:obj.asset];
    }];
    _preViewArray = [NSMutableArray array];
}

- (void)getDataSource
{
    LLPhotoBrowserManager * manager = [LLPhotoBrowserManager sharedPhotoBrowserManager];
    self.dataSource = [manager getPhotoInResult:self.albumModel.result
                               allowSelectVideo:[self config].allowSelectVideo
                               allowSelectImage:[self config].allowSelectImage
                                 allowSelectGif:[self config].allowSelectGif
                           allowSelectLivePhoto:[self config].allowSelectLivePhoto];

    [self.collectionView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self config].sortAscending) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.dataSource.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    });
}

- (void)showAlert
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:@"您已选择最大个数，请删除后继续添加"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:@"知道了"
                                                        style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)previewClick
{
    if (_preViewArray.count < 1) {
        return;
    }
    LLPhotoEditPhotoViewController * vc = [[LLPhotoEditPhotoViewController alloc] init];
    vc.models                            = _preViewArray;
    vc.selectedModels                    = _preViewArray;
    vc.callback                          = ^(NSMutableArray<LLPhotoBrowserModel *> * _Nonnull array) {
        //        NSArray * models = [self.dataSource copy];
        //        for (LLPhotoBrowserModel * photoModel in models) {
        //            for (LLPhotoBrowserModel * model in array) {
        //                if ([photoModel.asset isEqual:model.asset]) {
        //                    [self.dataSource ll_safeReplaceObjectAtIndex:[self.dataSource indexOfObject:photoModel] withObject:model];
        //                }
        //            }
        //        }
        //        [self.collectionView reloadData];

    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)originalImageWithSelect:(BOOL)select
{
    selectOriginalImage = select;
}

- (void)doneClick
{
    __block NSMutableArray * array      = [NSMutableArray array];
    __block NSMutableArray * videoAsset = [NSMutableArray array];
    WeakSelf(weakSelf);
    [_preViewArray enumerateObjectsUsingBlock:^(LLPhotoBrowserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == LLAssetMediaTypeVideo) {
            [videoAsset addObject:obj.asset];
        }
        if (obj.image) {
            [array addObject:obj.image];
        } else {
            [[LLPhotoBrowserManager sharedPhotoBrowserManager] requestSelectedImageForAsset:obj
                                                                                  isOriginal:selectOriginalImage
                                                                              allowSelectGif:[weakSelf config].allowSelectGif
                                                                                  completion:^(UIImage * image, NSDictionary * info) {
                                                                                      [array addObject:image];
                                                                                  }];
        }
    }];
    LLPhotoBrowser * photoBrowser = (LLPhotoBrowser *)self.navigationController;
    if (photoBrowser.callBackBlock) {
        photoBrowser.callBackBlock(array, videoAsset);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectCellImageWithModel:(LLPhotoBrowserModel *)model select:(BOOL)select
{


    if (select) {
        [[LLPhotoBrowserManager sharedPhotoBrowserManager] requestSelectedImageForAsset:model
                                                                              isOriginal:selectOriginalImage
                                                                          allowSelectGif:[self config].allowSelectGif
                                                                              completion:^(UIImage * image, NSDictionary * info) {
                                                                                  model.image = image;
                                                                              }];
        [_preViewArray addObject:model];
        if (_preViewArray.count == [self config].maxSelectCount) {
            for (LLPhotoBrowserModel * model in self.dataSource) {
                if (![_preViewArray containsObject:model]) {
                    model.needCover = YES;
                }
            }
            [self.collectionView reloadData];
        }

    } else {
        if (model.image) {
            model.image = nil;
        }
        [_preViewArray removeObject:model];
        if (_preViewArray.count < [self config].maxSelectCount) {
            for (LLPhotoBrowserModel * model in self.dataSource) {
                model.needCover = NO;
            }
            [self.collectionView reloadData];
        }
    }
    [self changePreviewButtonState];
    [self changeDoneButtonState];

    if (![self config].allowChoosePhotoAndVideo) {
        BOOL isCannotSelectVideo = NO;
        BOOL isCannotSelectImage = NO;
        for (LLPhotoBrowserModel * model in _preViewArray) {
            if (model.type == LLAssetMediaTypeImage) {
                isCannotSelectVideo = YES;
            } else if (model.type == LLAssetMediaTypeVideo) {
                isCannotSelectImage = YES;
            }
        }
        if (isCannotSelectVideo == YES && model.type == LLAssetMediaTypeImage) {
            for (LLPhotoBrowserModel * model in self.dataSource) {
                if (model.type == LLAssetMediaTypeVideo) {
                    model.needCover = YES;
                }
            }
            [self.collectionView reloadData];
        }
        if (isCannotSelectImage == YES && model.type == LLAssetMediaTypeVideo) {
            for (LLPhotoBrowserModel * model in self.dataSource) {
                LLPhotoBrowserModel * firstModel = _preViewArray.firstObject;
                if (model != firstModel) {
                    model.needCover = YES;
                }
            }
            [self.collectionView reloadData];
            return;
        }
    }
}

- (void)changePreviewButtonState
{
    if (_preViewArray.count > 0) {
        self.bottomBar.previewButton.enabled = YES;
    } else {
        self.bottomBar.previewButton.enabled = NO;
    }
}

- (void)changeDoneButtonState
{
    if (_preViewArray.count > 0) {
        self.bottomBar.doneButton.enabled = YES;
        [self.bottomBar.doneButton setTitle:[NSString stringWithFormat:@"完成(%d)", _preViewArray.count] forState:UIControlStateNormal];
    } else {
        self.bottomBar.doneButton.enabled = NO;
    }
}

- (void)takePhoto{
    WeakSelf(weakSelf);
    LLCameraViewController * camera = [[LLCameraViewController alloc] initWithType:LLCameraTypeAll
                                                                   cameraOrientation:LLCameraOrientationBack];
    camera.preset    = AVCaptureSessionPresetMedium;
    camera.saveAblum = YES;
//    camera.albumName = @"测试";
    camera.time = 60;
    camera.takePhoto = ^(UIImage * photo, NSString * imagePath) {
        [UIView ll_showToastImage:@"spin" autoRotation:YES ImageType:LLToastImageTypeSVG sourceInKitBundle:YES autoDismiss:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView ll_dismissToast];
            [weakSelf.dataSource removeAllObjects];
            [weakSelf dataContainerInitialization];
            [weakSelf getDataSource];
        });

    };
    camera.takeVideo = ^(NSString * videoPath) {
        [UIView ll_showToastImage:@"spin" autoRotation:YES ImageType:LLToastImageTypeSVG sourceInKitBundle:YES autoDismiss:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView ll_dismissToast];
            [weakSelf.dataSource removeAllObjects];
            [weakSelf dataContainerInitialization];
            [weakSelf getDataSource];
        });
    };
    [self presentViewController:camera animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count + ([self config].canTakePicture ? 1 : 0);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self config].canTakePicture) {
        if (indexPath.item == 0) {
            LLPhotoBrowserTakePhotoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"takePhoto" forIndexPath:indexPath];
            return cell;
        }
    }
    NSInteger selectIndex = [self config].canTakePicture ? indexPath.item - 1 : indexPath.item;
    LLPhotoBrowserCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"image" forIndexPath:indexPath];
    cell.model = self.dataSource[selectIndex];
    WeakSelf(weakSelf);
    cell.selectImage = ^(LLPhotoBrowserModel * model, BOOL isSelect) {
        [weakSelf selectCellImageWithModel:model select:isSelect];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = (ScreenWidth - 25) / 4;
    return CGSizeMake(width, width);
}

//设置每个item的UIEdgeInsets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0 * SizeAdapter, 5, 0 * SizeAdapter, 5);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView
                                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0 * SizeAdapter;
}

//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView
                             layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self config].canTakePicture) {
        if (indexPath.item == 0) {
            [self takePhoto];
            return;
        }
    }

    if (![self config].allowChoosePhotoAndVideo) {
        LLPhotoBrowserModel * model = self.dataSource[indexPath.item];
        if (model.needCover == YES) {
            return;
        }
    }
    NSInteger selectIndex = [self config].canTakePicture ? indexPath.item - 1 : indexPath.item;
    LLPhotoEditPhotoViewController * vc = [[LLPhotoEditPhotoViewController alloc] init];
    vc.models                            = self.dataSource;
    vc.selectedModels                    = _preViewArray;
    LLPhotoBrowserModel * model         = self.dataSource[selectIndex];
    vc.selectIndex                       = [self.dataSource indexOfObject:model];
    vc.callback                          = ^(NSMutableArray<LLPhotoBrowserModel *> * _Nonnull array) {
        //        NSArray * models = [self.dataSource copy];
        //        for (LLPhotoBrowserModel * photoModel in models) {
        //            for (LLPhotoBrowserModel * model in array) {
        //                if ([photoModel.asset isEqual:model.asset]) {
        //                    [self.dataSource
        //                     ll_safeReplaceObjectAtIndex:[self.dataSource indexOfObject:photoModel]
        //                     withObject:model];
        //                }
        //            }
        //        }
        //        [collectionView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark--- Getter
- (NSMutableArray *)assets
{
    if (!_assets) {
        _assets = ({
            NSMutableArray * object = [[NSMutableArray alloc] init];
            object;
        });
    }
    return _assets;
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = ({
            NSMutableArray * object = [[NSMutableArray alloc] init];
            object;
        });
    }
    return _dataSource;
}

- (LLPhotoBrowserBottomBar *)bottomBar
{
    if (!_bottomBar) {
        _bottomBar = ({
            CGFloat object_x                  = 0;
            CGFloat object_y                  = ScreenHeight - LLBottomHeight - 49;
            CGFloat object_width              = ScreenWidth;
            CGFloat object_height             = 49;
            CGRect object_rect                = CGRectMake(object_x, object_y, object_width, object_height);
            LLPhotoBrowserBottomBar * object = [[LLPhotoBrowserBottomBar alloc] initWithFrame:object_rect];
            WeakSelf(weakSelf);
            object.previewBlock = ^{
                [weakSelf previewClick];
            };
            object.originalBlock = ^(BOOL select) {
                [weakSelf originalImageWithSelect:select];
            };
            object.doneBlock = ^{
                [weakSelf doneClick];
            };
            object;
        });
    }
    return _bottomBar;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat collectionView_X            = self.view.cmam_left;
        CGFloat collectionView_Y            = self.view.cmam_top;
        CGFloat collectionView_Width        = self.view.cmam_width;
        CGFloat collectionView_Height       = self.view.cmam_height - LLBottomHeight - 49;
        CGRect rect                         = CGRectMake(collectionView_X, collectionView_Y, collectionView_Width, collectionView_Height);
        _collectionView =
        [[UICollectionView alloc] initWithFrame:rect
                           collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource      = self;
        _collectionView.delegate        = self;
        if (@available(iOS 11, *)) {
            _collectionView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
        } else {
            _collectionView.contentInset = UIEdgeInsetsMake(LLTopHeight, 0, 0, 0);
        }

        [_collectionView registerClass:[LLPhotoBrowserCell class] forCellWithReuseIdentifier:@"image"];
        [_collectionView registerClass:[LLPhotoBrowserTakePhotoCell class] forCellWithReuseIdentifier:@"takePhoto"];
    }
    return _collectionView;
}

- (LLPhotoBrowserConfig *)config
{
    LLPhotoBrowser * photoBrowser = (LLPhotoBrowser *)self.navigationController;
    return photoBrowser.config;
}

@end
