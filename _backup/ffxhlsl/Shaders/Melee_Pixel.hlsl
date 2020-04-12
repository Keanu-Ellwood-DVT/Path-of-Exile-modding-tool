//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main

CBUFFER_BEGIN( cline_vsconstants )
	float Position;
CBUFFER_END

struct VS_OUTPUT
{
	float4 Position : SV_POSITION;
	float2 Pos : POSITION0;
	float2 Forward : POSITION1;
	float Time : TEXCOORD0;
};

float4 main(VS_OUTPUT Input) : PIXEL_RETURN_SEMANTIC
{
	if( Input.Forward.x > 0 || Input.Forward.y > 0 )
	{
		float fdot = dot(Input.Forward, Input.Pos);
		clip(fdot);
	}

	if( Position >= Input.Time.x )
		return float4(0.5,0,0,0.4);

	return float4(0,0,0,0.4);
}
