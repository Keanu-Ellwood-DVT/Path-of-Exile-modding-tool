//PRECOMPILE ps_4_0 PShad_AtlasGlowWave
//PRECOMPILE ps_gnm PShad_AtlasGlowWave
//PRECOMPILE ps_vkn PShad_AtlasGlowWave

CBUFFER_BEGIN( ctime )
float time;
float x_offset;
float y_offset;
float start_time;
float4 wave_colour;
CBUFFER_END

TEXTURE2D_DECL( tex );

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

float SmoothStep( float val, float center, float curve )
{
	float power = 2.0f / max( 1e-3f, 1.0f - curve ) - 1.0f;
	return 1.0f - center +
		(
			-pow( saturate( 1.0f - max( center, val ) ), power ) * pow( saturate( 1.0f - center ), -( power - 1.0f ) ) +
			pow( saturate( min( center, val ) ), power ) * pow( saturate( center ), -( power - 1.0f ) )
			);
}

float WaveFunc( float radius_diff )
{
	return 1.0f / ( 1.0f + pow( max( 0.0f, radius_diff * 1000.0f ), 2.0f ) + pow( -min( 0.0f, radius_diff * 50.0f ), 1.2f ) );
}

float4 PShad_AtlasGlowWave( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float atlas_ratio = 5689.0 / 3200.0;
	float animation_duration = 3.0;

	float altered_time = 10.0f * ( time - start_time );
	float new_time = log( 1 + altered_time ) * 0.15;

	float2 center = float2( x_offset * atlas_ratio, y_offset );
	float2 altered_uv = float2( input.texture_uv.x * atlas_ratio, input.texture_uv.y );
	// Distance to the center
	float center_dist = length( altered_uv - center );
	
	float wave_radius = new_time;
	float point_radius = center_dist;
	float radius_diff = point_radius - wave_radius;
	
	float texture_alpha = SAMPLE_TEX2D( tex, SamplerLinearClamp, input.texture_uv ).a;
	texture_alpha = SmoothStep( texture_alpha, 0.45f, 0.3f );

	float wave_shape = WaveFunc(radius_diff);
	float alpha_mult = pow( 1 - saturate( ( time - start_time ) / animation_duration ), 2 );
	float4 output_colour = lerp( float4( 0, 0, 0, 0 ), wave_colour, wave_shape * texture_alpha );
	return output_colour * alpha_mult;
	
}
