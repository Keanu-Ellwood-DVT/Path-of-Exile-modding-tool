//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_vkn main


CBUFFER_BEGIN( cline_vsconstants )
	float4x4 m_WorldViewProj;
CBUFFER_END


struct VS_INPUT
{
	float2 Position : POSITION0;
	float2 Forward : POSITION1;
	float Time : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 Position : SV_POSITION;
	float2 Pos : POSITION0;
	float2 Forward : POSITION1;
	float Time : TEXCOORD0;
};

VS_OUTPUT main( VS_INPUT Input )
{
	VS_OUTPUT Output;
	Output.Position = mul(float4(Input.Position.xy, 0, 1), m_WorldViewProj);
	Output.Pos = Input.Position;
	Output.Forward = Input.Forward;
	Output.Time = Input.Time;
	return Output;
}
