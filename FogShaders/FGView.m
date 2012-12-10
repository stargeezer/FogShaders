//
//  FGView.m
//  FogShaders
//
//  Created by Mark Strand on 12/5/12.
//  Copyright (c) 2012 Mark Strand. All rights reserved.
//

#import "FGView.h"


// texture vertex data
typedef struct
{
    GLfloat Position[2];
} texCoord;

typedef struct
{
    GLfloat Position[2];
} Vertex2D;

const Vertex2D texVertices[] =
{
    {1, 1},
    {-1, 1},
    {-1, -1},
    {1, -1},
};

const texCoord texCoords[] =
{
    {1,1},
    {0,1},
    {0,0},
    {1,0}
};

const GLubyte texIndices[] =
{
    0, 1, 2,
    2, 3, 0
};

@implementation FGView

// this function takea a shader file name & type, then compiles the shader and returns the
//  handle. 
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    NSString* shaderPath;
    
    shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    
    NSError* error;
    
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    // generate the handle, and retrieve the file as a UTF8 string
    GLuint shaderHandle = glCreateShader(shaderType);
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // now compile the shader and check the results
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // if we made it here, all is well.   return the shader handle.
    return shaderHandle;
}

// this function will compile each of the shaders, then create & link an opengl program
- (void)compileShaders
{
    GLuint vertexShader = [self compileShader:@"Vertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"Fragment" withType:GL_FRAGMENT_SHADER];
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // it is possible to have multiple programs in an opengl app.  just call
    // glUseProgram(...) before using each one.
    glUseProgram(programHandle);
    
    // query the program to find the handles for different attibutes & uniforms
    // contained in the shaders.
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    _textureUniformTex = glGetUniformLocation(programHandle, "Texture");
    glEnableVertexAttribArray(_positionSlot);
   
    glEnableVertexAttribArray(_texCoordSlot);
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
}

// create a texture from the passed-in image. in the case of this app, this is the photo taken
// by the user to create her space.
-(GLuint)newTexture:(UIImage*)newImage
{
    CGImageRef spriteImage = newImage.CGImage;
    if(!spriteImage)
    {
        NSLog(@"Failed to load image from UIImagePicker");
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    NSLog(@"texture width: %zu",width);
    NSLog(@"texture height: %zu",height);
    
    // we have to get the raw pixel data from the image to create an opengl texture
    GLubyte * imgData = (GLubyte*) calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(imgData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgData);
    
    // we are done with the data, release it
    free(imgData);
    
    return texName;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
    // initialize opengl
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupDisplayLink];
    }
    
    // get the file path for the texture, then call newTexture() to load it.
    NSString* texturePath;
    texturePath = [[NSBundle mainBundle] pathForResource:@"interiorTexture" ofType:@"png"];
    
    UIImage* tImage = [UIImage imageWithContentsOfFile:texturePath];
    _texture = [self newTexture:tImage];
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

-(void) setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

-(void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    _context = [[EAGLContext alloc] initWithAPI:api];
    if(!_context)
    {
        NSLog(@" failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

-(void)setupDepthBuffer
{
    glGenRenderbuffers(1,&_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

-(void)setupRenderBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupFrameBuffer
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

-(void)setupDisplayLink
{
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

// render will do the actual drawing.  it first clears the display, draws objects to it,
// and finally presents it to the user. 
- (void)render:(CADisplayLink*)displayLink
{
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    CATransform3D projection;
    projection = CATransform3DIdentity;
    
    projection = CATransform3DScale(projection, 1.0, 1.0, 0.0);
    
    glUniformMatrix4fv(_projectionUniform, 1, 0,(GLfloat*)&projection);

    glViewport(0,0,640.0, 960.0);
    
    glVertexAttribPointer(_texCoordSlotTex, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(_texCoordSlotTex);
    
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 0, texVertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_textureUniformTex, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(texIndices)/sizeof(texIndices[0]), GL_UNSIGNED_BYTE, texIndices);
    
    // drawing is done on a hidden surface; this call swaps out the buffers so the
    // newly drawn surface is presented to the user. 
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
