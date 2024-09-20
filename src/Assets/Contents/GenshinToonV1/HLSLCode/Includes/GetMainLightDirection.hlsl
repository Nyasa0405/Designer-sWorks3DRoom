#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED


void GetMainLightDirection_float(out float3 LightColor, out float3 Direction, out float LightIntensity)
{

#ifdef SHADERGRAPH_PREVIEW
  Direction = half3(0.5, 0.5, 0);
  LightColor =1;
  LightIntensity =1.0f;

#else 
     Light light = GetMainLight(0);
  Direction = light.direction;
  LightColor = light.color;
  LightIntensity = length(light.color);
#endif
}

#endif
