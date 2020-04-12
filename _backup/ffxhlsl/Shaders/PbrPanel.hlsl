//PRECOMPILE ps_4_0 PbrPanelPixelMain
//PRECOMPILE ps_gnm PbrPanelPixelMain
//PRECOMPILE ps_vkn PbrPanelPixelMain

#include "Shaders/Include/Util.hlsl"
#include "Shaders/Include/Lighting.hlsl"

CBUFFER_BEGIN( cconstants )
	float time;
CBUFFER_END

TEXTURE2D_DECL( albedo_tex );
TEXTURE2D_DECL( normal_tex );
TEXTURE2D_DECL( roughness_tex );

float3 GetSurfaceLight(float3 view_dir, float3 surface_normal, float3 bent_normal, float ambient_occlusion, float glossiness, float3 albedo_color, float3 specular_color)
{
  float env_brightness = 4.1f;
  //float3x3 mirror_transform = float3x3();
  float3x3 env_transform = GetCubemapTransform(1.5f + time * 3.0f, 0.0f);
	float3 res_light = 0.0f;
	res_light += GetEnvDiffuseLight(bent_normal, diffuse_cube, env_transform) * albedo_color * env_brightness * ambient_occlusion;
  float4 env_specular_light = GetGGXPrefilteredLight(view_dir, surface_normal, glossiness, specular_color, specular_cube, env_transform);
  float spec_ao = lerp(ambient_occlusion, 1.0f, glossiness);
	res_light += env_specular_light.rgb * env_brightness * spec_ao;
  //res_light +=           
  
	//specular_light.rgb *= 0.0f;
	//specular_light += GGXSpecular(normalize(float3(1.0f, -1.0f, -1.0f)), surface_normal, view_dir, glossiness, specular_color) * 10.3f;
	return res_light;
}

float4 GetPbrPixelColor(float2 uv_coord)
{
  return SAMPLE_TEX2D(roughness_tex, SamplerLinearWrap, uv_coord.xy);
  return float4(uv_coord.xy, 0.0f, 0.0f);
}

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

float3 UnpackNormal(float2 rg)
{
  float3 normal;
  normal.xy = rg * 2.0f - 1.0f;
  normal.z = sqrt(max(0.0f, 1.0f - dot(normal.xy, normal.xy)));
  return normal;
}

float4 PbrPanelPixelMain( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
  float2 uv = input.texture_uv.xy;
  float4 albedo_sample = SAMPLE_TEX2D(albedo_tex, SamplerLinearWrap, uv);
  float4 normal_sample = SAMPLE_TEX2D(normal_tex, SamplerLinearWrap, uv);
  float4 roughness_sample = SAMPLE_TEX2D(roughness_tex, SamplerLinearWrap, uv);
  
  float3 surface_normal = UnpackNormal(normal_sample.xy);
  float3 bent_normal = UnpackNormal(normal_sample.zw);
  
  float3 view_dir = float3(0.0f, 0.0f, -1.0f);
  
  float glossiness = 0.0f;//1.0f - roughness_sample.r;
  float metalness = roughness_sample.g;
  float ao = roughness_sample.a;
  float3 albedo_color = lerp(albedo_sample.rgb, 0.0f, metalness);
  float3 specular_color = lerp(0.04f, albedo_sample.rgb, metalness);
  float3 surface_light = GetSurfaceLight(view_dir, surface_normal, bent_normal, ao, glossiness, albedo_color, specular_color);
	return float4(surface_light * albedo_sample.a, albedo_sample.a);//abs(normal_sample.x - 0.5f) > 0.02f ? float4(1.0f, 0.0f, 0.0f, 1.0f) : float4(0.0f, 1.0f, 0.0f, 1.0f);//frac(normal_sample.x);
}