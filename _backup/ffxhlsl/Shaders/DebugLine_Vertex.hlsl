//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_gnm main
//PRECOMPILE vs_vkn main


CBUFFER_BEGIN( cline_vsconstants )
	float4x4 m_WorldViewProj;
CBUFFER_END


struct VS_INPUT
{
	float3 Position		: POSITION0;
	float4 Color		: COLOR0;
};

struct VS_OUTPUT
{
	float4 Position		: SV_POSITION;
	float4 Color		: TEXCOORD0;
};

VS_OUTPUT main( VS_INPUT Input )
{
	VS_OUTPUT Output;
	Output.Position = mul(float4(Input.Position.xyz, 1), m_WorldViewProj);
	Output.Color = Input.Color;
	return Output;
}
