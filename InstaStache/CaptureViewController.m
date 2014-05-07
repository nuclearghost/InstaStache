//
//  CaptureViewController.m
//  InstaStache
//
//  Created by Mark Meyer on 5/1/14.
//  Copyright (c) 2014 Mark Meyer. All rights reserved.
//

#import "CaptureViewController.h"

@interface CaptureViewController ()
@property (strong, nonatomic) UIImagePickerController *imgPicker;
@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) NSMutableArray *filters;
@end

@implementation CaptureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imgPicker = [[UIImagePickerController alloc] init];
    self.imgPicker.delegate = self;
    
    self.context = [CIContext contextWithOptions:nil];
    
    self.filters = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cameraTapped:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imgPicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        //CGAffineTransform transform = CGAffineTransformMakeScale(1.0, 0.8);
        //self.imgPicker.cameraViewTransform = transform;
    } else {
        self.imgPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    self.imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *) kUTTypeImage,nil];
    //self.imgPicker.allowsEditing = NO;
    
    [self presentViewController:self.imgPicker animated:YES completion:^{
        NSLog(@"Completed camera");
    }];
}

- (IBAction)drawTapped:(id)sender {
}

- (IBAction)shareTapped:(id)sender {
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[self.imgMainView.image] applicationActivities:nil];
    [self presentViewController:activityView animated:YES completion:^{
        NSLog(@"Completed activty");
    }];
    activityView.completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"Activity View completed (%hhd) for %@",completed, activityType);
    };
}

- (void)applyFilter:(id)sender {
    NSLog(@"Tapped");
    
    UIButton *filterView = (UIButton *)sender;
    
    CIFilter *filter = [self.filters objectAtIndex:filterView.tag];
    
    NSLog(@"Filter applied %@", filter);
    
    CIImage *outputImage = [filter outputImage];
    
    CGImageRef cgimg =
    [self.context createCGImage:outputImage fromRect:[outputImage extent]];
    
    self.imgMainView.image = [UIImage imageWithCGImage:cgimg];
    
    CGImageRelease(cgimg);
}

-(void)initFiltersFor:(CIImage*)image {
    CIFilter *sepiaFilter = [CIFilter filterWithName:@"CISepiaTone"
                                       keysAndValues:kCIInputImageKey, image, @"inputIntensity", @0.8, nil];
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"
                                            keysAndValues:kCIInputImageKey,image, @"inputColor",[CIColor colorWithString:@"Red"], @"inputIntensity",[NSNumber numberWithFloat:0.8], nil];
    CIFilter *pixelateFilter = [CIFilter filterWithName:@"CIPixellate" keysAndValues:kCIInputImageKey,image , @"inputScale",[NSNumber numberWithFloat:30.0], nil];
    CIFilter *pointilizeFilter = [CIFilter filterWithName:@"CIVibrance" keysAndValues:kCIInputImageKey,image, @"inputAmount",[NSNumber numberWithFloat:0.8], nil];
    
    [self.filters addObject:sepiaFilter];
    [self.filters addObject:monochromeFilter];
    [self.filters addObject:pixelateFilter];
    [self.filters addObject:pointilizeFilter];
}

- (void)createFiltersfor:(CIImage *)image {
    [self clearFilter];
    [self initFiltersFor:image];
    
    for (int i = 0; i < self.filters.count; ++i) {
        CIFilter *filter = (CIFilter*)[self.filters objectAtIndex:i];
        CIImage *outputImage = [filter outputImage];
        UIButton *btnPreview = [[UIButton alloc] initWithFrame:CGRectMake(i * self.scrollView.frame.size.height, 0, self.scrollView.frame.size.height, self.scrollView.frame.size.height)];
        
        CGImageRef cgimg = [self.context createCGImage:outputImage fromRect:[outputImage extent]];
        
        btnPreview.tag = i;
        [btnPreview setImage:[UIImage imageWithCGImage:cgimg] forState:UIControlStateNormal];
        [btnPreview addTarget:self action:@selector(applyFilter:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:btnPreview];
        
        CGImageRelease(cgimg);
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.height * self.filters.count, self.scrollView.frame.size.height);
}

-(void)clearFilter {
    [self.filters removeAllObjects];
    [self.scrollView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
}

#pragma mark UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"Completed: %@",info);
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    //Crop the image to a square
    //From http://stackoverflow.com/questions/17712797/ios-custom-uiimagepickercontroller-camera-crop-to-square
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    if (width != height) {
        CGFloat newDimension = MIN(width, height);
        CGFloat widthOffset = (width - newDimension) / 2;
        CGFloat heightOffset = (height - newDimension) / 2;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDimension, newDimension), NO, 0.);
        [image drawAtPoint:CGPointMake(-widthOffset, -heightOffset)
                 blendMode:kCGBlendModeCopy
                     alpha:1.];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    self.imgMainView.image = image;
    
    [self createFiltersfor:[[CIImage alloc] initWithImage:image]];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Canceled");
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    NSLog(@"Gesture: %@", gestureRecognizer);
    NSLog(@"Other: %@", otherGestureRecognizer);
    return YES;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"Gesture: %@", gestureRecognizer);
    return YES;
}
@end
