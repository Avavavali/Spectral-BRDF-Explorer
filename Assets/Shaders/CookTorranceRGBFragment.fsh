#version 300 es

precision mediump float;

/**
 RGB material definition.
 */
struct RGBMaterial {
    
    /// Ambient component.
    vec4 ka;
    /// Diffuse component.
    vec4 kd;
    /// Specular component.
    vec4 ks;
    /// Shiness.
    float sh;
};

/**
 RGB light definition.
 It it composed of a direction and a color.
 */
struct DirectionalRGBLight {
    
    /// Light direction.
    vec3 direction;
    /// Light rgb color.
    vec4 color;
};

/// Normal (from vertex shader) interpolated per fragment.
in vec3 normalInterp;
/// Vertex position.
in vec3 vertPos;
/// Texture coordinated (If the 3D model has texture data).
in vec2 textureCoordinate;
/// Shadow coordinate (calculated using mvp from light position).
in vec4 shadowCoordinate;

/// Final fragment color.
out vec4 fragmentColor;

/// View position.
uniform vec3 viewPosition;
/// Light data.
uniform DirectionalRGBLight light;
/// Material data.
uniform RGBMaterial surfaceMaterial;
/// Shadow sampler.
uniform lowp sampler2DShadow shadowMapSampler;
/// Texture sampler.
uniform sampler2D textureSampler;
/// Flag used to check if the model has a texture.
uniform int textureActive;

/*************** Shadow ***************/

/**
 Calculate shadows using percentage closer filtering.
 Shadow texture has been obatined using shadow mapping
 technique (see OpenGLShadowMapProgram.cpp).
 
 @param shadowCoordinate the shadow coordinate on the shadow texture.
 
 @return percentage of shadow.
 */
float shadow(vec4 shadowCoordinate) {
    
    //Shadow calculate using PCF (percentage closer filtering).
    vec4 offset;
    float pixelSize = 0.00195; // 1.0/512.0
    float pixelSizeHomogenous = pixelSize * shadowCoordinate.w;
    float bias = -0.001 * shadowCoordinate.w;
    float shadowPercentage = 0.0;
    
    for (float x = -2.0; x <= 2.0; x += 2.0) {
        
        for (float y = -2.0; y <= 2.0; y += 2.0) {
            
            offset = vec4(x * pixelSizeHomogenous, y * pixelSizeHomogenous, bias, 0.0);
            shadowPercentage += textureProj(shadowMapSampler, shadowCoordinate + offset);
        }
    }
    
    shadowPercentage = shadowPercentage / 9.0;
    
    return shadowPercentage;
}

/*************** Main ***************/

/**
 Cook torrance lighting model.
 
 @param lightDirection.
 @param viewDirection.
 @param normal.
 
 @returns cook torrance specular factor.
 */
float cookTorrance(vec3 lightDirection, vec3 viewDirection, vec3 normal) {
    
    //Input.
    float roughness = 0.2;
    float fresnel = pow((1.0 - 1.180) / (1.0 + 1.180), 2.0);
    
    vec3 halfVector = normalize(lightDirection + viewDirection);
    
    float nDotV = max(0.0, dot(normal, viewDirection));
    float nDotL = max(0.0, dot(normal, lightDirection));
    float vDotH = max(0.0, dot(viewDirection, halfVector));
    float lDotH = max(0.0, dot(lightDirection, halfVector));
    
    //D term.
    float nDotH = max(0.0, dot(halfVector, normal));
    float cos2Alpha = pow(nDotH, 2.0);
    float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha; //already * -1
    float D = exp(tan2Alpha / pow(roughness, 2.0)) / (pow(roughness, 2.0) * pow(nDotH, 4.0));
    
    //G term.
    float g1 = (2.0 * nDotH * nDotV) / vDotH;
    float g2 = (2.0 * nDotH * nDotL) / lDotH;
    float G = min(1.0, min(g1, g2));
    
    //F term.
    float F = fresnel + (1.0 - fresnel) * pow(vDotH, 5.0);
    
    float cookTorranceValue = (D * G * F) / (4.0 * nDotV * nDotL);
 
    return max(0.0, cookTorranceValue);
}

/*************** Main ***************/

void main() {
    
    //Calculate light direction and view direction.
    vec3 lightDirection = normalize(light.direction);
    vec3 viewDirection = normalize(viewPosition - vertPos);
    
    //Cosine theta diffuse lambertian component.
    float cosTheta = max(0.0, dot(normalInterp, normalize(lightDirection)));
    
    vec4 ambient = surfaceMaterial.ka * light.color;
    vec4 diffuse = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 specular = vec4(0.0, 0.0, 0.0, 1.0);

    if (cosTheta > 0.0) {
        
        if (textureActive == 0) {
            
            //No texture. Standard lighting.
            diffuse = surfaceMaterial.kd * light.color * cosTheta;
        } else {
            
            //Lighting using texture.
            diffuse = surfaceMaterial.kd * texture(textureSampler, textureCoordinate) * cosTheta;
        }
        
        specular = surfaceMaterial.ks * light.color * cookTorrance(lightDirection, viewDirection, normalInterp);
    }
    
    fragmentColor = ambient + (diffuse + specular) * shadow(shadowCoordinate);
}
