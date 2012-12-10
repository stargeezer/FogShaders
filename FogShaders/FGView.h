//
//  FGView.h
//  FogShaders
//
//  Created by Mark Strand on 12/5/12.
//  Copyright (c) 2012 Mark Strand. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface FGView : UIView
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    
    // variables used by the shaders & rendering code:
    GLuint _positionSlot;
    GLuint _texCoordSlot;
    GLuint _texCoordSlotTex;
    GLuint _textureUniformTex;
    GLuint _texture;
    
    GLuint _projectionUniform;
}

@end
