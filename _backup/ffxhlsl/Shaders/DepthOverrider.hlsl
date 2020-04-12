//PRECOMPILE ps_4_0 OverrideDepth
//PRECOMPILE ps_4_0 OverrideDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 2
//PRECOMPILE ps_4_0 OverrideDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 4
//PRECOMPILE ps_4_0 OverrideDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 8
//PRECOMPILE ps_4_0 OverrideDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 16
//PRECOMPILE ps_gnm OverrideDepth
//PRECOMPILE ps_vkn OverrideDepth

CBUFFER_BEGIN( cdepth_overrider )
	int viewport_width;
	int viewport_height;
CBUFFER_END

struct VOut
{
	float4 pos : SV_POSITION;
};

float4 OverrideDepth(VOut vertex_input, out float out_depth : SV_DEPTH ) : PIXEL_RETURN_SEMANTIC
{
	out_depth = 1.0f;
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}
