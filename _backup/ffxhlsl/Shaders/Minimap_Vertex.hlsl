//PRECOMPILE vs_4_0 VShad
//PRECOMPILE vs_gnm VShad
//PRECOMPILE vs_vkn VShad

CBUFFER_BEGIN(cminimap_vertex_transform)
	float4x4 transform;
CBUFFER_END

struct VS_INPUT
{
	float2 position : POSITION;
	float2 texture_uv : TEXCOORD0;
	float visibility : TEXCOORD1;
};

struct VS_OUTPUT
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 untransformed_pos : TEXCOORD1;
};

VS_OUTPUT VShad( const VS_INPUT input )
{
	float2 pos = input.position * input.visibility;
	VS_OUTPUT output;
	output.pos = mul( float4( pos, 0.0f, 1.0f ), transform );
	output.texture_uv = input.texture_uv;
	output.untransformed_pos = float4(input.position, 0.0, 1.0);
	return output;
}