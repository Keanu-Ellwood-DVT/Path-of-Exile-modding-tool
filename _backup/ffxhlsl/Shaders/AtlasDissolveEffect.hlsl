//PRECOMPILE ps_4_0 PShad_AtlasDissolveEffect
//PRECOMPILE ps_gnm PShad_AtlasDissolveEffect
//PRECOMPILE ps_vkn PShad_AtlasDissolveEffect

CBUFFER_BEGIN( ctime )
float alpha_cutoff;
float4 outline_colour;
CBUFFER_END

TEXTURE2D_DECL( tex );
TEXTURE2D_DECL( alpha_map );

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

float4 PShad_AtlasDissolveEffect( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	//float4 edge_colour = float4( 1.3, 1.2, 0.96, 1.0 );  // White
	//float4 edge_colour = float4( 3.4, 0.30, 0.24, 1.0 ); // Red
	//float4 edge_colour = float4( 0.15, 0.8, 0.12, 1.0 ); // Green
	//float4 edge_colour = float4( 0.25, 0.54, 3.4, 1.0 ); // Blue
	//float4 edge_colour = float4( 1.5, 1.0, 0.24, 1.0 );  // Gold

	float cutoff = 0.02;
	float dissolve_alpha = SAMPLE_TEX2D( alpha_map, SamplerLinearWrap, input.texture_uv ).r;

	float cut_alpha = alpha_cutoff - dissolve_alpha;
	if( cut_alpha < 0 )
		return float4( 0, 0, 0, 0 );

	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv );	
	float lerp_val = tex_colour.a * saturate( ( cut_alpha - cutoff ) * - 1 ) / cutoff;

	float fade_in_alpha = SmoothStep( alpha_cutoff, 0.5, 0.8 );
	return lerp( tex_colour, outline_colour, lerp_val );
}
