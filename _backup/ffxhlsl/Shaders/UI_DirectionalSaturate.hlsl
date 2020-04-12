//PRECOMPILE ps_4_0 PShad_DirectionalSaturate
//PRECOMPILE ps_gnm PShad_DirectionalSaturate
//PRECOMPILE ps_vkn PShad_DirectionalSaturate

CBUFFER_BEGIN( ctime )
float fill_amount;
float alpha;
CBUFFER_END

TEXTURE2D_DECL( tex );

#include "Shaders/Include/Util.hlsl"

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

float4 ProgressLineAlpha( const VS_OUTPUT input )
{
	float line_thickness = 0.02;

	float image_y = 1 - input.sat_scale_localuv.w;
	float line_alpha = clamp( abs( fill_amount - image_y ), 0.0, line_thickness  ) / line_thickness;

	return 1 - line_alpha;
}

float4 PShad_DirectionalSaturate( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv );	

	float progress_line_side_fade = 1 - ( abs( input.sat_scale_localuv.z - 0.5 ) * 2 );
	float4 progress_line_colour = float4( 0.609, 0.945, 0.97, 1.0 ) * progress_line_side_fade;
	float4 grey_scale_colour = SetBrightness( GetGreyscale( tex_colour ), 0.7 ) * 0.8;

	float lerp_val = saturate( SmoothStep( fill_amount, 1 - input.sat_scale_localuv.w, 0.9 ) );
	float4 faded_colour =  lerp( grey_scale_colour, tex_colour, lerp_val );

	return( lerp( faded_colour, progress_line_colour, ProgressLineAlpha( input ) ) ) * alpha;
}
