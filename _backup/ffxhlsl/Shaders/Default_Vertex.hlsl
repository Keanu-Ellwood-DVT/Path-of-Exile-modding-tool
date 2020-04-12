//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_gnm main
//PRECOMPILE vs_vkn main


CBUFFER_BEGIN( cdefault ) 
	float4x4 view_projection_transform; // Same as cpass in Common.ffx
	float4x4 world_transform; // Same as ctype in Common.ffx
CBUFFER_END


struct VS_INPUT
{
	float3 Position : POSITION0;
};

struct VS_OUTPUT
{
	float4 Position : SV_POSITION;
};

VS_OUTPUT main( VS_INPUT input )
{
	VS_OUTPUT output;
	output.Position = mul(mul(float4(input.Position.xyz, 1), world_transform), view_projection_transform);
	return output;
}
