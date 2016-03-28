#import "GPUImageFilter.h"

@interface GPUImageToneCurveFilter : GPUImageFilter

@property(readwrite, nonatomic, copy) NSArray *redControlPoints;
@property(readwrite, nonatomic, copy) NSArray *greenControlPoints;
@property(readwrite, nonatomic, copy) NSArray *blueControlPoints;
@property(readwrite, nonatomic, copy) NSArray *rgbCompositeControlPoints;

// Initialization and teardown
- (id)initWithACVData:(NSData*)data;

//file name without extension
- (id)initWithACV:(NSString*)curveFilename;
- (id)initWithACVURL:(NSURL*)curveFileURL;

//file name with extension,custom curve file
- (id)initWithCurveFile:(NSString *)curveFileName;
- (id)initWithCurveFileURL:(NSURL*)curveFileURL;

-(id)initWithRawIntegerDataAll:(int*)nAll red:(int*)nRed green:(int*)nGreen blue:(int*)nBlue;
-(id)initWithIntegerDataRed:(int*)nRed green:(int*)nGreen blue:(int*)nBlue;

// This lets you set all three red, green, and blue tone curves at once.
// NOTE: Deprecated this function because this effect can be accomplished
// using the rgbComposite channel rather then setting all 3 R, G, and B channels.
- (void)setRGBControlPoints:(NSArray *)points DEPRECATED_ATTRIBUTE;

- (void)setPointsWithACV:(NSString*)curveFilename;
- (void)setPointsWithACVURL:(NSURL*)curveFileURL;

// Curve calculation
- (NSMutableArray *)getPreparedSplineCurve:(NSArray *)points;
- (NSMutableArray *)splineCurve:(NSArray *)points;
- (NSMutableArray *)secondDerivative:(NSArray *)cgPoints;
- (void)updateToneCurveTexture;
//Sibin Compatibility: Compatilibity for curve input directly
- (void)setRedCurvePoints:(NSArray *)redValue greenCurvePoints:(NSArray *)greenValue blueCurvePoints:(NSArray *)blueValue;
@end
