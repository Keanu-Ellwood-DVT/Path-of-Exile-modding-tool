//PRECOMPILE ps_4_0 PShad_NodeGlow
//PRECOMPILE ps_4_0 PShad_PathGlow
//PRECOMPILE ps_4_0 PShad_BackgroundGlow
//PRECOMPILE ps_4_0 PShad_IconGlow
//PRECOMPILE ps_gnm PShad_NodeGlow
//PRECOMPILE ps_gnm PShad_PathGlow
//PRECOMPILE ps_gnm PShad_BackgroundGlow
//PRECOMPILE ps_gnm PShad_IconGlow
//PRECOMPILE ps_vkn PShad_NodeGlow
//PRECOMPILE ps_vkn PShad_PathGlow
//PRECOMPILE ps_vkn PShad_BackgroundGlow
//PRECOMPILE ps_vkn PShad_IconGlow

CBUFFER_BEGIN( ctime )
float time;
float alpha;
float dissolve_cutoff;
float brightness_percent;
CBUFFER_END

TEXTURE2D_DECL( tex );
TEXTURE2D_DECL( noise_map );

#include "Shaders/Include/Util.hlsl"

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

float2 GetDisplacement( const VS_OUTPUT input, float2 speed, float intensity, float uv_scale )
{
	float2 disp_time_offset = speed * time;
	float2 disp = SAMPLE_TEX2D( noise_map, SamplerLinearWrap, disp_time_offset + input.position.xy + input.texture_uv * uv_scale ).xy;
	disp = ( ( disp * 2 ) - 1 ) * intensity;

	return disp;
}

float4 AnimatedDisplacement( const VS_OUTPUT input, float2 velocity, float intensity, float uv_scale )
{
	float2 disp = GetDisplacement( input, velocity, intensity, uv_scale );
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv + disp );

	tex_colour.a -= max( abs(disp.x), abs(disp.y) );
	return tex_colour;
}

float4 FadingGlow( const VS_OUTPUT input )
{
	float2 offset_x = float2( 0.05 * time, 0 );
	float2 offset_y = float2( 0, 0.2 * time );
	float4 base_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv );

	float uv_scale = 7.0f;
	float4 disp_x = SAMPLE_TEX2D( noise_map, SamplerLinearWrap, offset_x + input.position.xy + input.texture_uv * uv_scale );
	float4 disp_y = SAMPLE_TEX2D( noise_map, SamplerLinearWrap, offset_y + input.position.xy + input.texture_uv * uv_scale );

	float average = saturate( disp_x.r - disp_y.r ) * 1.5;

	float brightness_val = 1.0 + 0.35 * sin( time * 2 );
	float4 glow_colour = SetBrightness( float4( 0.6, 0.45, 0.044, 1 ), brightness_val );
	float4 dim_colour = SetBrightness( float4( 0.35, 0.25, 0.03, 1 ), brightness_val );

	float lerp_val = SmoothStep( saturate( 2 * saturate( average - 0.25 ) / 0.5 ), 0.5, 0.3 );
	return lerp( dim_colour, glow_colour, lerp_val );
}

float4 HighlightedNode( const VS_OUTPUT input )
{
	float4 base_colour =  SetBrightness( SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv ), 2.0 );
	float4 fading_glow = ( base_colour + FadingGlow( input ) ) * base_colour.a ;
	float4 mist_colour = SetBrightness( float4( 0.85, 0.81, 0.67, 1 ), 10 );

	// Depends on distance to center of sprite
	float4 mist_alpha = 1 - SmoothStep( distance( input.sat_scale_localuv.zw, float2( 0.5, 0.5 ) ) * 2, 0.55, 0.8 );

	float4 final_colour = lerp( base_colour, fading_glow, 0.1 );

	return final_colour + mist_colour * AnimatedDisplacement( input, float2( 0.2, -0.1 ), 0.004, 10.0 ).a * saturate( 1 - final_colour.a ) * mist_alpha ;
}

float WaveFunc( float radius_diff )
{
	return 1 / ( 1.0f + pow( max( 0.0f, radius_diff * 10.0f ), 3.0f ) );
}

float4 DissolvedColour( float4 base_colour, float alpha_cutoff, float2 uv, float dissolve_scale )
{
	float noise_cutoff = SAMPLE_TEX2D( noise_map, SamplerLinearClamp, uv * dissolve_scale ).r;
	float dist_from_center = distance( float2( 0.5, 0.5 ), uv ) * 1.4;

	float diff = max( 0.0f, ( alpha_cutoff * 1.4 ) - dist_from_center );
	float wave_alpha = WaveFunc( diff );

	wave_alpha = saturate( wave_alpha + ( noise_cutoff * wave_alpha ) );
	float colour_alpha = saturate( wave_alpha * 2 );

	float4 clear_colour = float4( 0, 0, 0, 0 );
	float4 outline_colour = float4( 0.95, 0.18, 0.08, 1.0 );

	float4 output_colour = lerp( base_colour, outline_colour, colour_alpha ) * base_colour.a;
	return lerp( output_colour, clear_colour, wave_alpha );
}

// === NODE EFFECT ENTRY POINT ===
// ===============================
float4 PShad_NodeGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	return DissolvedColour( HighlightedNode( input ), dissolve_cutoff, input.sat_scale_localuv.zw, 1 ) * alpha;
}

// === BACKGROUND EFFECT ENTRY POINT ===
// ===============================
float4 PShad_BackgroundGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	//return float4( 0,0,0,0 );
	float4 base_colour = SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv );
	float brightness = 0.4f + ( ( GetGreyscale( base_colour ).a * 30.0 ) + ( 8 * sin( time ) ) ) * pow( brightness_percent, 10 );
	float4 glowing_colour = SetBrightness( base_colour, brightness );
	return DissolvedColour( glowing_colour, dissolve_cutoff, input.sat_scale_localuv.zw, 1.0 ) * alpha;
}

// === PATH EFFECT ENTRY POINT ===
// ===============================
float4 PShad_PathGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	//return float4( 0,0,0,0 );
	float time_offset = 3.14159;
	float4 base_colour = SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv ) * float4( 1.0, 0.6, 0.6, 1 );
	return DissolvedColour( SetBrightness( base_colour, 10.5 + 2 * sin( time + time_offset ) ), dissolve_cutoff, input.texture_uv.xy, 0.5 ) * alpha;
}

// === ICON EFFECT ENTRY POINT ===
// ===============================
float4 PShad_IconGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 base_colour = SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv );
	float4 output_colour = DissolvedColour( SetBrightness( base_colour, 1.3 + 0.3 * sin(time) ), dissolve_cutoff, input.texture_uv.xy, 1.0 ) * alpha;
	float4 black = float4( 0, 0, 0, 0 );

	float distance_cutoff = 0.8;
	float center_dist = distance( input.sat_scale_localuv.zw, float2( 0.5, 0.5 ) );
	float to_show = floor( ( min( center_dist * 2.0f, distance_cutoff ) ) / distance_cutoff );
	return lerp( output_colour, black, to_show );
}