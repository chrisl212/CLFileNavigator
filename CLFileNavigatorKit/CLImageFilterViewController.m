//
//  CLImageFilterViewController.m
//  CLFileNavigator
//
//  Created by Christopher Loonam on 10/6/15.
//  Copyright (c) 2015 Christopher Loonam. All rights reserved.
//

#import "CLImageFilterViewController.h"
#import "CLFilterCell.h"

@implementation CLImageFilterViewController

- (id)initWithImage:(UIImage *)image delegate:(id<CLImageFilterViewControllerDelegate>)delegate
{
    if (self = [super init])
    {
        self.delegate = delegate;
        self.image = image;
        
        self.collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        self.collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.collectionViewLayout.itemSize = CGSizeMake(150.0, 170.0);
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewLayout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self.collectionView registerNib:[UINib nibWithNibName:@"CLFilterCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];
        
        self.filterNames = [CIFilter filterNamesInCategory:kCICategoryColorEffect];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.frame = self.view.bounds;
    [self.view addSubview:self.collectionView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.navigationItem.title = @"Filters";
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save
{
    CLFilterCell *selectedCell = (CLFilterCell *)[self.collectionView cellForItemAtIndexPath:self.collectionView.indexPathsForSelectedItems[0]];
    [self.delegate filterWasAppliedToImage:selectedCell.imageView.image];
    [self dismiss];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)applyFilterNamed:(NSString *)filterName toImage:(UIImage *)image
{
    CIFilter *filter = [CIFilter filterWithName:filterName];
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    
    return [UIImage imageWithCIImage:filter.outputImage scale:1.0 orientation:UIImageOrientationUp];
}

#pragma mark - Collection View Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.filterNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    CLFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    NSString *filterName = self.filterNames[indexPath.row];
    filterName = [filterName substringFromIndex:2];
    //NSMutableString *prettyName = filterName.mutableCopy;
    
    
    cell.textLabel.text = filterName;
    cell.imageView.image = nil;
    [cell.spinner startAnimating];
    dispatch_async(dispatch_queue_create("com.cl", NULL), ^{
        UIImage *image = [self applyFilterNamed:self.filterNames[indexPath.row] toImage:self.image];
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        
        [image drawAtPoint:CGPointZero];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.spinner stopAnimating];
            cell.imageView.image = image;
        });
    });
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

@end
