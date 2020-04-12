//PRECOMPILE ps_4_0 PShad_RageDisplay
//PRECOMPILE ps_gnm PShad_RageDisplay
//PRECOMPILE ps_vkn PShad_RageDisplay

CBUFFER_BEGIN( ctime )
	float rage_value;
CBUFFER_END

TEXTURE2D_DECL( tex );
TEXTURE2D_DECL( rage_tex );

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

bool PointInTriangle( float2 p, float2 p0, float2 p1, float2 p2 )
{
    float s = p0.y * p2.x - p0.x * p2.y + ( p2.y - p0.y ) * p.x + ( p0.x - p2.x ) * p.y;
    float t = p0.x * p1.y - p0.y * p1.x + ( p0.y - p1.y ) * p.x + ( p1.x - p0.x ) * p.y;

    if( ( s < 0 ) != ( t < 0 ) )
        return false;

    float A = -p1.y * p2.x + p0.y * ( p2.x - p1.x ) + p0.x * ( p1.y - p2.y ) + p1.x * p2.y;

    if( A < 0 ) 
    	return ( s <= 0 && s + t >= A );
    else 
    	return ( s >= 0 && s + t <= A );
}

float4 PShad_RageDisplay( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float value = rage_value;
	float2 point_to_check = input.texture_uv.xy;

	bool render_fill = false;
	if( value <= 0.5 )
		render_fill = PointInTriangle( point_to_check, float2( 1.0f, 1.0f ), float2( 0.0f, 1.0f ), float2( 0.0f, 1.0f - ( value * 2.0f ) ) );
	else
		render_fill = !PointInTriangle( point_to_check, float2( 1.0f, 1.0f ), float2( 1.0f, 0.0f ), float2( ( value - 0.5f ) / 0.5f, 0.0f ) );

	float4 final = SAMPLE_TEX2D( tex, SamplerLinearWrap, point_to_check );
	if( render_fill )
		final = SAMPLE_TEX2D( rage_tex, SamplerLinearWrap, point_to_check );

	return final;
}
