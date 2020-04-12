//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main

struct VS_OUT
{
	float4 Pos : SV_POSITION;
	float4 T0 : TEXCOORD0;
};

Texture2D tex0 : register( t0 );
Texture2D tex1 : register( t1 );
Texture2D tex2 : register( t2 );
Texture2D tex3 : register( t3 );

CBUFFER_BEGIN( cbink_psconstants )
	float4  consta;
	float4  crc;
	float4  cbc;
	float4  adj;
	float4  yscale;
CBUFFER_END

float4 main( VS_OUT In ) : PIXEL_RETURN_SEMANTIC
{
	float y = tex0.Sample( SamplerLinearClamp, In.T0.xy ).r;
	float cr = tex1.Sample( SamplerLinearClamp, In.T0.zw ).r;
	float cb = tex2.Sample( SamplerLinearClamp, In.T0.zw ).r;

	float4 p = y * yscale + cr * crc + cb * cbc + adj;
	p.w = tex3.Sample( SamplerLinearClamp, In.T0.xy ).r;
	p *= consta;

	// Our main render target is in srgb format so we do this to cancel out the gamma conversion in hardware
	p = pow( p, 2.2 );

	return p;
}