#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// CustomLighting.hlsl
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile _ _SHADOWS_SOFTD


void GetMainLightDrawShadow_float(in float3 WorldPos,out float3 LightColor, out float3 Direction,out float DistanceAtten, out float ShadowAtten, out float LightIntensity)
{

#ifdef SHADERGRAPH_PREVIEW
  Direction = half3(0.5, 0.5, 0);
  LightColor =1;
  LightIntensity =1.0f;
  DistanceAtten = 1.0f;
  ShadowAtten =1.0f;

#else 
    
    float4 ShadowCoord = TransformWorldToShadowCoord(WorldPos);
     Light light = GetMainLight();
  Direction = light.direction;
  LightColor = light.color;
  DistanceAtten = light.distanceAttenuation;
  ShadowAtten = light.shadowAttenuation;
  LightIntensity = length(light.color);
#endif
}

#endif
