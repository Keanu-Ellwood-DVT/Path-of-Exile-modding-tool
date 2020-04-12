//PRECOMPILE ps_4_0 ResolveDepth
//PRECOMPILE ps_4_0 ResolveDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 2
//PRECOMPILE ps_4_0 ResolveDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 4
//PRECOMPILE ps_4_0 ResolveDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 8
//PRECOMPILE ps_4_0 ResolveDepth MULTISAMPLED_DEPTH 1 SAMPLE_COUNT 16
//PRECOMPILE ps_gnm ResolveDepth
//PRECOMPILE ps_vkn ResolveDepth

CBUFFER_BEGIN( clinear_depth_builder_desc )
	int viewport_width;
	int viewport_height;
	float4x4 inv_projection_matrix;
CBUFFER_END

#if defined( MULTISAMPLED_DEPTH )
// Note: declare the Texture2DMS after all the sampler/texture objects have been declared
// since their sampler slot and resource slot uses the same value
TEXTURE2DMS_DECL( depth_sampler, SAMPLE_COUNT );
#else
TEXTURE2D_DECL( depth_sampler );
#endif

float ReadNonlinearDepth(float2 tex_coord)
{
	#if defined( MULTISAMPLED_DEPTH )
		float2 uv = tex_coord * float2(float(viewport_width), float(viewport_height));
		int2 uv_int = int2(int(uv.x), int(uv.y));
		return depth_sampler.Load( uv_int, 0 ).x;
	#else
		return SAMPLE_TEX2D( depth_sampler, SamplerLinearWrap, tex_coord ).x;
	#endif
}

float3 GetViewPoint(float2 screenspace_point, float nonlinear_depth)
{
	float4 projected_pos;
	projected_pos.x = screenspace_point.x * 2.f - 1.f;
	projected_pos.y = ( 1.f - screenspace_point.y ) * 2.f - 1.f;
	projected_pos.z = nonlinear_depth;
	projected_pos.w = 1.f;
	float4 world_pos = mul( projected_pos, inv_projection_matrix );
	world_pos /= world_pos.w;
	return world_pos.xyz;
}

float3 ReadViewPoint(float2 screenspace_point)
{
	float nonlinear_depth = ReadNonlinearDepth(screenspace_point);
	return GetViewPoint(screenspace_point, nonlinear_depth);
}

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

float4 ResolveDepth( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 viewport_size = float2(viewport_width, viewport_height);

	float2 tex_coord = input.screen_coord.xy / viewport_size;
	//float2 tex_coord = input.tex_coord;
	float depth = ReadNonlinearDepth(tex_coord);

	/*float2 eps = float2(1.0, 1.0) / viewport_size;
	float3 view_tangent0 = (ReadViewPoint(tex_coord + float2(eps.x, 0.0f)) - ReadViewPoint(tex_coord + float2(-eps.x, 0.0f))) / eps.x;
	float3 view_tangent1 = (ReadViewPoint(tex_coord + float2(0.0f, eps.y)) - ReadViewPoint(tex_coord + float2(0.0f, -eps.y))) / eps.y;
	float3 view_normal = normalize(cross(view_tangent0, view_tangent1));*/

	float4 res;
	//res.r = length(ReadViewPoint(tex_coord));
	res.gba = float3(1.0f, 1.0f, 1.0f);
	res.r = ReadNonlinearDepth(tex_coord);
	return res;
}
