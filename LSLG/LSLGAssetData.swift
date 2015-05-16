//
//  LSLGModelData.swift
//  LSLG
//
//  Created by Morris on 5/16/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

let LSLGModelCubeVertex:[GLfloat] = [
    -0.5, -0.5, -0.0
  , -0.5,  0.5, -0.0
  ,  0.5,  0.5, -0.0
  ,  0.5, -0.5, -0.0
    
  , -0.5, -0.5,  1.0
  , -0.5,  0.5,  1.0
  ,  0.5,  0.5,  1.0
  ,  0.5, -0.5,  1.0
]

let LSLGModelCubeIndex:[GLuint] = [
    0, 1, 3 , 2, 3, 1
  , 3, 2, 7 , 6, 7, 2
  , 7, 4, 6 , 5, 6, 4
  , 4, 5, 0 , 1, 0, 5
  , 1, 5, 2 , 6, 2, 5
  , 0, 4, 3 , 7, 3, 4
]

let LSLGModelCubeVertexTest:[GLfloat] = [
    0.5,  0.5, 0.0,  // Top Right
    0.5, -0.5, 0.0,  // Bottom Right
    -0.5, -0.5, 0.0,  // Bottom Left
    -0.5,  0.5, 0.0   // Top Left 
]
let LSLGModelCubeIndexTest:[GLuint] = [  // Note that we start from 0!
    0, 1, 3,  // First Triangle
    1, 2, 3   // Second Triangle
]
