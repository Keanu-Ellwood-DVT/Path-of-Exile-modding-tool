//PRECOMPILE ps_4_0 PShad_SythesisDistortion
//PRECOMPILE ps_gnm PShad_SythesisDistortion
//PRECOMPILE ps_vkn PShad_SythesisDistortion

CBUFFER_BEGIN( ctime )
float time;
float x_offset;
float y_offset;
float start_time;
CBUFFER_END

TEXTURE2D_DECL( tex );

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

float calcWaveFalloff(in float wave_radius, in float coeff, in float power)
{
	return 1.0 / pow( ( 1.0 + coeff * wave_radius), power );
}

float4 PShad_SythesisDistortion( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	// Sawtooth calc of time
	float slowTime = ( time - start_time ) / 7.0f;
	float offset = ( slowTime - floor( slowTime ) ) / slowTime;
	float new_time = slowTime * offset;
		
	float2 center = float2( x_offset, y_offset );
	
	// Distance to the center
	float center_dist = distance( input.texture_uv, center );
	
	float2 distorted_uv = input.texture_uv;

	float coef1 = 0.01;	
	float distortion = 2.0f;
	
	float wave_radius = new_time;
	float point_radius = center_dist;
	float radius_diff = point_radius - wave_radius;
	float wave_falloff = calcWaveFalloff( wave_radius, 2.0, 0.25 );
	
	float dir = normalize( input.texture_uv - center ) * 0.01;
	distorted_uv += ( distortion * dir * wave_falloff * ( coef1 / ( coef1 + radius_diff ) ) );

	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, distorted_uv.xy );
	
	return tex_colour;

}
