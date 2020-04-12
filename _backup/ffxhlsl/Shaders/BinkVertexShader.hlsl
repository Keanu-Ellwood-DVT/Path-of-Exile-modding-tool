//PRECOMPILE vs_4_0 main
//PRECOMPILE vs_gnm main
//PRECOMPILE vs_vkn main

struct VS_OUT
{
	float4 Pos : SV_POSITION;
	float4 T0 : TEXCOORD0;
};

CBUFFER_BEGIN( cbink_vsconstants )
	float4 coord_xy;
	float4 constuv[ 3 ];
CBUFFER_END


VS_OUT main( float2 st : POSITION )
{
	VS_OUT o;
	o.Pos = float4(st * coord_xy.xy + coord_xy.zw, 0.0, 1.0);
	o.T0 = st.x * constuv[0] + st.y * constuv[1] + constuv[2];
	return o;
}
