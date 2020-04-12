//PRECOMPILE ps_4_0 PShad_SynthesisCollapse
//PRECOMPILE ps_gnm PShad_SynthesisCollapse
//PRECOMPILE ps_vkn PShad_SynthesisCollapse


CBUFFER_BEGIN( ctime )
	float time;
	float start_time;
	bool full_decay;
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

float4 PShad_SynthesisCollapse( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ) ;
	float4 final = input.colour * lerp( float4( 1, 1, 1, 1 ), tex_colour, input.sat_scale_localuv.y )  ;
	final.rgb = lerp( dot( final.rgb, float3( 0.30, 0.59, 0.11 ) ), final.rgb, input.sat_scale_localuv.x ) ;

	float alpha_value = 0;

	if( full_decay )
	{
		alpha_value = SAMPLE_TEX2D( alpha_map, SamplerLinearWrap, input.sat_scale_localuv.zw ).x - saturate( ( time - start_time ) / 3.f ) + 0.2;
		clip( alpha_value );
	}
	else
	{
		float sin_value = sin( time );
		float square_sin = sin_value * sin_value;
		float range = ( square_sin + 0.25f ) * 1.25f;
		float t_value = range / 10.0f;

		alpha_value = SAMPLE_TEX2D( alpha_map, SamplerLinearWrap, input.sat_scale_localuv.zw ).x - t_value;

		clip( alpha_value );

		alpha_value -= 0.0025f;
	}

	final.rgb = lerp( float3( 0.1, 0.5, 1.0 ) * final.a, final.rgb, saturate( alpha_value * 20.f ) );
	return final;
}
 