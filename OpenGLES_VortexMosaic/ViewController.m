//
//  ViewController.m
//  OpenGLES_分屏滤镜
//
//  Created by 桑协东 on 2019/6/30.
//  Copyright © 2019 ZB_Demo. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import "FilterBar.h"

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface ViewController () <FilterBarDelegate>

@property (nonatomic, assign) SenceVertex *vertices;
@property (nonatomic, strong) EAGLContext *context;

// 用于刷新屏幕
@property (nonatomic, strong) CADisplayLink *displayLink;
// 开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
// 着色器程序
@property (nonatomic, assign) GLuint program;
// 顶点缓存
@property (nonatomic, assign) GLuint vertexBuffer;
// 纹理 ID
@property (nonatomic, assign) GLuint textureID;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupFilterBar];
    
    [self filterInit];
    
    [self startFileAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 移除 displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)startFileAnimation {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)timeAction {
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
    
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1i(time, currentTime);
    
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render {
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - FilterBarDelegate

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index {
    //1. 选择默认shader
    switch (index) {
        case 0:
            [self setupNormalShaderProgram];
            break;
        case 1:
            [self setupGrayShaderProgram];
            break;
        case 2:
            [self setupVortexShaderProgram];
            break;
        case 3:
            [self setupMosaicShaderProgram];
            break;
        case 4:
            [self setupHexagonMosaicShaderProgram];
            break;
        default:
            break;
    }
    
    // 重新开始滤镜动画
    [self startFileAnimation];
    
    //渲染
    //    [self render];
}

// 创建滤镜栏
- (void)setupFilterBar {
    CGFloat filterBarWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat filterBarHeight = 100;
    CGFloat filterBarY = [UIScreen mainScreen].bounds.size.height - filterBarHeight;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, filterBarWidth, filterBarHeight)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    
    NSArray *dataSource = @[@"无", @"灰度", @"旋转", @"矩形马赛克", @"六边形马赛克"];
    filerBar.itemList = dataSource;
}

- (void)filterInit {
    // 初始化上下文，并设置当前上下文
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    
    // 设置图层（CAEAGLLayer）
    CAEAGLLayer *layer = [[CAEAGLLayer alloc]init];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [UIScreen mainScreen].scale;
    [self.view.layer addSublayer:layer];
    
    // 绑定渲染缓冲区
    [self bindRenderLayer:layer];
    
    // 开辟顶点数组内存空间
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    // 初始化顶点数据以及纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"gaoyuanyuan.jpg"];
    
    // 读取图片
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    // 将图片转换成纹理图片
    GLuint textureID = [self createTextureWithImage:image];
    // 设置纹理ID
    self.textureID = textureID;
    
    // 设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    // 设置顶点缓存区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_DYNAMIC_DRAW);
    
    [self setupNormalShaderProgram];
    
    self.vertexBuffer = vertexBuffer;
    
}

// 默认着色器程序
- (void)setupNormalShaderProgram {
    [self setupShaderProgramWidthName:@"Normal"];
}

// 灰度滤镜着色器程序
- (void)setupGrayShaderProgram {
    [self setupShaderProgramWidthName:@"Gray"];
}

// 漩涡滤镜着色器程序
- (void)setupVortexShaderProgram {
    [self setupShaderProgramWidthName:@"Vortex"];
}

// 矩形马赛克滤镜着色器程序
- (void)setupMosaicShaderProgram {
    [self setupShaderProgramWidthName:@"Mosaic"];
}

// 六边形马赛克滤镜着色器程序
- (void)setupHexagonMosaicShaderProgram {
    [self setupShaderProgramWidthName:@"HexagonMosaic"];
}

- (void)setupShaderProgramWidthName:(NSString *)name {
    GLuint program = [self programWithShaderName:name];
    
    glUseProgram(program);
    
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetAttribLocation(program, "Texture");
    GLuint textureCoordSlot = glGetAttribLocation(program, "TextureCoord");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    glUniform1i(textureSlot, 0);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(textureCoordSlot);
    glVertexAttribPointer(textureCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    self.program = program;
    
}

- (GLuint)programWithShaderName:(NSString *)shaderName {
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[250];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program link 失败 %@", messageString);
        exit(1);
    }
    
    return program;
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh" ];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        //        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    GLuint shader = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shader);
    
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[250];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败： %@", messageString);
        exit(1);
    }
    return shader;
}

// 从图片中加载纹理
- (GLuint)createTextureWithImage:(UIImage *)image {
    CGImageRef cgImageRef = image.CGImage;
    
    if (!cgImageRef) {
        NSLog(@"Failed to load image");
        exit(1);
    }
    
    // 读取图片的大小，宽和高
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 获取图片的颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 获取图片字节数。宽*高*4（RGBA）
    void *imageData = malloc(width * height *4);
    
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    // 对图片进行重新绘制，得到一张新的解压缩后的位图
    CGContextDrawImage(context, rect, cgImageRef);
    
    // 设置图片纹理属性
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // 载入纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 释放context imageData
    CGContextRelease(context);
    free(imageData);
    
    // 返回纹理
    return textureID;
}

- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    // 渲染缓冲区、帧缓冲区对象
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    // 获取渲染缓冲区，绑定渲染缓存区以及将渲染缓冲区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 获取帧缓冲区名称， 绑定帧缓冲区以及将渲染缓冲区附着到帧缓冲区上
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

// 获取渲染缓存区的宽
- (GLint)drawableWidth {
    GLint backingWith;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWith);
    return backingWith;
}

// 获取渲染缓存区的高
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}

//释放
- (void)dealloc {
    //1.上下文释放
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    //顶点缓存区释放
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    //顶点数组释放
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

@end
