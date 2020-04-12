//PRECOMPILE vs_4_0 EdgeDetectionVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_gnm EdgeDetectionVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_vkn EdgeDetectionVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_4_0 BlendingWeightCalculationVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_gnm BlendingWeightCalculationVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_vkn BlendingWeightCalculationVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_4_0 NeighborhoodBlendingVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_gnm NeighborhoodBlendingVShad SMAA_PRESET_HIGH
//PRECOMPILE vs_vkn NeighborhoodBlendingVShad SMAA_PRESET_HIGH
//PRECOMPILE ps_4_0 ColorEdgeDetectionPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_gnm ColorEdgeDetectionPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_vkn ColorEdgeDetectionPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_4_0 BlendingWeightCalculationPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_gnm BlendingWeightCalculationPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_vkn BlendingWeightCalculationPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_4_0 NeighborhoodBlendingPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_gnm NeighborhoodBlendingPShad SMAA_PRESET_HIGH
//PRECOMPILE ps_vkn NeighborhoodBlendingPShad SMAA_PRESET_HIGH
//PRECOMPILE vs_4_0 EdgeDetectionVShad SMAA_PRESET_LOW
//PRECOMPILE vs_gnm EdgeDetectionVShad SMAA_PRESET_LOW
//PRECOMPILE vs_vkn EdgeDetectionVShad SMAA_PRESET_LOW
//PRECOMPILE vs_4_0 BlendingWeightCalculationVShad SMAA_PRESET_LOW
//PRECOMPILE vs_gnm BlendingWeightCalculationVShad SMAA_PRESET_LOW
//PRECOMPILE vs_vkn BlendingWeightCalculationVShad SMAA_PRESET_LOW
//PRECOMPILE vs_4_0 NeighborhoodBlendingVShad SMAA_PRESET_LOW
//PRECOMPILE vs_gnm NeighborhoodBlendingVShad SMAA_PRESET_LOW
//PRECOMPILE vs_vkn NeighborhoodBlendingVShad SMAA_PRESET_LOW
//PRECOMPILE ps_4_0 ColorEdgeDetectionPShad SMAA_PRESET_LOW
//PRECOMPILE ps_gnm ColorEdgeDetectionPShad SMAA_PRESET_LOW
//PRECOMPILE ps_vkn ColorEdgeDetectionPShad SMAA_PRESET_LOW
//PRECOMPILE ps_4_0 BlendingWeightCalculationPShad SMAA_PRESET_LOW
//PRECOMPILE ps_gnm BlendingWeightCalculationPShad SMAA_PRESET_LOW
//PRECOMPILE ps_vkn BlendingWeightCalculationPShad SMAA_PRESET_LOW
//PRECOMPILE ps_4_0 NeighborhoodBlendingPShad SMAA_PRESET_LOW
//PRECOMPILE ps_gnm NeighborhoodBlendingPShad SMAA_PRESET_LOW
//PRECOMPILE ps_vkn NeighborhoodBlendingPShad SMAA_PRESET_LOW

#define LinearSampler SamplerLinearClampNoBias
#define PointSampler SamplerPointClampNoBias

#define SMAATexture2D(tex) TEXTURE2D_DECL(tex)
#define SMAASampleLevelZero(tex, coord) SAMPLE_TEX2DLOD(tex, LinearSampler, float4(coord.xy, 0.0f, 0.0f))
#define SMAASampleLevelZeroPoint(tex, coord) SAMPLE_TEX2DLOD(tex, PointSampler, float4(coord.xy, 0.0f, 0.0f))
#define SMAASample(tex, coord) SMAASampleLevelZero(tex, coord)
#define SMAASamplePoint(tex, coord) SMAASampleLevelZeroPoint(tex, coord)
#define SMAASampleLevelZeroOffset(tex, coord, offset) SMAASampleLevelZero(tex, (coord + (SMAA_PIXEL_SIZE * (offset))))
//#define SMAASampleLevelZeroOffset(tex, coord, offset) tex.SampleLevel(LinearSampler, coord, 0, offset)
#define SMAALerp(a, b, t) lerp(a, b, t)
#define SMAASaturate(a) saturate(a)
#define SMAAMad(a, b, c) mad(a, b, c)
#define SMAA_FLATTEN [flatten]
#define SMAA_BRANCH [branch]
#define SMAALoad(tex, pos, sample) tex.Load(pos, sample)

CBUFFER_BEGIN( csmaa_desc )
	int target_width;
	int target_height;
CBUFFER_END

// TODO: make uniform
#define SMAA_PIXEL_SIZE float2(1.0 / target_width, 1.0 / target_height)
#define SMAA_RT_METRICS float4(1.0 / target_width, 1.0 / target_height, target_width, target_height)

#include "Shaders/SMAA.hlsl"

/**
 * Input textures
 */
TEXTURE2D_DECL(colorTex);
TEXTURE2D_DECL(colorTexGamma);

/**
 * Temporal textures
 */
TEXTURE2D_DECL(edgesTex);
TEXTURE2D_DECL(blendTex);

/**
 * Pre-computed area and search textures
 */
TEXTURE2D_DECL(areaTex);
TEXTURE2D_DECL(searchTex);


void EdgeDetectionVShad(float4 position : POSITION,
                              out float4 svPosition : SV_POSITION,
                              inout float2 texcoord : TEXCOORD0,
                              out float4 offset[3] : TEXCOORD1)
{
    svPosition = position;
    SMAAEdgeDetectionVS(texcoord, offset);
}

void BlendingWeightCalculationVShad(float4 position : POSITION,
                                          out float4 svPosition : SV_POSITION,
                                          inout float2 texcoord : TEXCOORD0,
                                          out float2 pixcoord : TEXCOORD1,
                                          out float4 offset[3] : TEXCOORD2) 
{
    svPosition = position;
    SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}

void NeighborhoodBlendingVShad(float4 position : POSITION,
                                     out float4 svPosition : SV_POSITION,
                                     inout float2 texcoord : TEXCOORD0,
                                     out float4 offset[2] : TEXCOORD1) 
{
    svPosition = position;
    SMAANeighborhoodBlendingVS(texcoord, offset);
}

float4 ColorEdgeDetectionPShad(float4 position : SV_POSITION,
                                     float2 texcoord : TEXCOORD0,
                                     float4 offset[3] : TEXCOORD1
                                     ) : PIXEL_RETURN_SEMANTIC 
{
    return SMAAColorEdgeDetectionPS(texcoord, offset, colorTexGamma);
}

float4 BlendingWeightCalculationPShad(float4 position : SV_POSITION,
                                            float2 texcoord : TEXCOORD0,
                                            float2 pixcoord : TEXCOORD1,
                                            float4 offset[3] : TEXCOORD2) : PIXEL_RETURN_SEMANTIC 
{
    return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesTex, areaTex, searchTex, int4(0, 0, 0, 0));
}

float4 NeighborhoodBlendingPShad(float4 position : SV_POSITION,
                                       float2 texcoord : TEXCOORD0,
                                       float4 offset[2] : TEXCOORD1) : PIXEL_RETURN_SEMANTIC 
{
    return SMAANeighborhoodBlendingPS(texcoord, offset, colorTex, blendTex);
}
