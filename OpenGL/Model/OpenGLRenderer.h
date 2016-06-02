//
//  OpenGLRenderer.hpp
//  OpenGL
//
//  Created by Fabrizio Duroni on 02/06/16.
//  Copyright © 2016 Fabrizio Duroni. All rights reserved.
//

#ifndef OpenGLRenderer_hpp
#define OpenGLRenderer_hpp

#include <OpenGLES/ES3/gl.h>
#include <GLKit/GLKit.h>
#include <stdio.h>
#include <string>

#include "Scene.hpp"
#include "OpenGLObjParser.hpp"
#include "OpenGLProgram.hpp"

#define VERTEX_POS_INDX       0
#define VERTEX_NORMAL_INDX    1

class OpenGLRenderer {
private:
    
    /// OpenGL ES program.
    OpenGLProgram openGLProgram;
    /// Model 3D.
    Model3D model;
    
    //Program.
    GLuint _vboIds[2];
    
    //Matrices.
    GLKMatrix4 _mvMatrix;
    GLKMatrix4 _mvpMatrix;
    GLKMatrix4 _normalMatrix;
    
    //Uniforms.
    GLint _mvLocation;
    GLint _mvpLocation;
    GLint _normalLocation;
    GLint _lightPosition;
    GLint _lightColor;
    GLint _materialAmbient;
    GLint _materialDiffuse;
    GLint _materialSpecular;
    GLint _materialSpecularExponent;
    
    float _rotation;

public:
    
    /*!
     Start OpenGL ES.
     
     @param vertexShaderSource source of the vertex shader.
     @param fragmentShaderSource source of the fragment shader.
     @param error log from error generated during setup.
     
     @returns true if OpenGL Es could start, else false.
     */
    bool startRenderer(const char* vertexShaderSource, const char* fragmentShaderSource, std::string& error);
    
    /*!
     Load current scene.
     */
    void loadScene();
    
    /*!
     Update data for draw.
     
     @param width viewport dimension.
     @param height viewport dimension.
     @param timeSinceLastUpdate
     */
    void update(float width, float height, double timeSinceLastUpdate);
    
    /*!
     Draw a specific model on screen.
     */
    void draw();
    
    /*!
     Shutdown renderer.
     */
    void shutdown();
};

#endif /* OpenGLRenderer_hpp */
