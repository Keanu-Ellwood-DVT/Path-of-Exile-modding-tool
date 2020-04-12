//PRECOMPILE ps_4_0 ApplyAmbientOcclusion
//PRECOMPILE ps_gnm ApplyAmbientOcclusion
//PRECOMPILE ps_vkn ApplyAmbientOcclusion

CBUFFER_BEGIN( cscreenspace_ao )
	int viewport_width;
	int viewport_height;
	float4x4 proj_matrix;
	float4x4 inv_proj_matrix;
	float4x4 view_matrix;
	int supersampling_scale;
CBUFFER_END




TEXTURE2D_DECL( color_sampler );
TEXTURE2D_DECL( depth_sampler );
TEXTURE2D_DECL( normal_sampler );

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

float3 GetViewPoint(float2 screenspace_point, float nonlinear_depth)
{
	float4 projected_pos;
	projected_pos.x = screenspace_point.x * 2.f - 1.f;
	projected_pos.y = ( 1.f - screenspace_point.y ) * 2.f - 1.f;
	projected_pos.z = nonlinear_depth;
	projected_pos.w = 1.f;
	float4 world_pos = mul( projected_pos, inv_proj_matrix );
	world_pos /= world_pos.w;
	return world_pos.xyz;
}


float3 ReadViewPoint(float2 screenspace_point)
{
	return GetViewPoint(screenspace_point, SAMPLE_TEX2DLOD( depth_sampler, SamplerLinearClamp, float4(screenspace_point.xy, 0.0f, 0.0f) ).x);
}

float IsInfinite(float2 screenspace_point)
{
	float depth = SAMPLE_TEX2DLOD( depth_sampler, SamplerLinearClamp, float4(screenspace_point.xy, 0.0f, 0.0f) ).x;
	return depth < 0.55f && depth > 0.45f;
}


float ComputeAmbientLight(float2 screenspace_point)
{
	float pi = 3.141592f;

	int dirs_count = 60;
	int occlusion_radius = 30; //screenspace radius. should not matter since projection is orthogonal

	float3 base_view_point = ReadViewPoint(screenspace_point);

	/*float eps = 1e-3f;
	float3 x_offset_point = ReadViewPoint(screenspace_point + float2(eps, 0.0f));
	float3 y_offset_point = ReadViewPoint(screenspace_point + float2(0.0f, eps));
	float3 view_normal = normalize(cross(x_offset_point - base_view_point, y_offset_point - base_view_point));*/
	//float3 view_normal = float3(0.0f, 0.0f, -1.0f);
	float4 sample_normal = SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, screenspace_point );
	float4 world_normal = float4(sample_normal.xyz * 2.0f - float3(1.0f, 1.0f, 1.0f), 0.0f);
	
	/*float debug_color = 0.0f;
	if(abs(length(world_normal.xyz) - 1.0f) > 1e-2f)
		debug_color = 1e-2f;
	else
		debug_color = 1.0f;*/
	
	
	float3 view_normal = mul(world_normal, view_matrix).xyz;
	if(view_normal.z > 0.0f)
		view_normal = -view_normal;
	view_normal = normalize(view_normal); //just in case. should not matter though.

	//float3 view_normal = float3(0.0f, 0.0f, -1.0f);


	float2 viewport_size = float2(viewport_width, viewport_height);
	float2 inv_viewport_size = float2(1.0f, 1.0f) / viewport_size;

	float sum_light = 0.0f;
	for(int dir_index = 0; dir_index < dirs_count; dir_index++)
	{
		float ang = 2.0f * pi * float(dir_index) / float(dirs_count);
		float2 dir = float2(cos(ang), sin(ang));

		float dir_tangent = 0.0f;

		float2 pix_point = screenspace_point * viewport_size;
		for(int step_index = 0; step_index < occlusion_radius; step_index++)
		{
			float2 offset_pix_point = pix_point + dir * float(step_index + 1) * float(supersampling_scale);
			float2 offset_screenspace_point = offset_pix_point * inv_viewport_size;

			if(IsInfinite(offset_screenspace_point))
				break;
			float3 offset_view_point = ReadViewPoint(offset_screenspace_point);

			float3 diff = offset_view_point - base_view_point;
			float y_proj = max(0.0f, dot(diff, view_normal));
			float x_proj = length(diff - view_normal * dot(view_normal, diff));
			float curr_tangent = y_proj / (x_proj + 1e-5f);
			//dir_tangent = max(dir_tangent, curr_tangent * float(step_index) / float(occlusion_radius - 1.0f));
			dir_tangent = max(dir_tangent, curr_tangent);
		}

		//float dir_light = 1.0f - atan(dir_tangent) / (pi / 2.0f);
		float occlusion_ang = atan(dir_tangent);

		float dir_light = /*2.0f * pi * R * R */ (1.0f - sin(occlusion_ang)) /* / 2.0f * pi * R * R*/; //non-cosine diffuse light
		//float dir_light = /*2.0f * pi * R * R */ 0.5f * (1.0f + cos(2.0f * occlusion_ang)) /* / 2.0f * pi * R * R*/; //cosine diffuse light
		sum_light += dir_light / float(dirs_count);
	}
	return sum_light;
}

float4 ApplyAmbientOcclusion( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 viewport_size = float2(viewport_width, viewport_height);
	float2 tex_coord = (input.screen_coord.xy) / viewport_size;
	//float2 tex_coord = input.tex_coord;
	float4 albedo_color = SAMPLE_TEX2D( color_sampler, SamplerLinearClamp, tex_coord );
	//albedo_color.rgb = lerp(albedo_color.rgb, float3(1.0f, 1.0f, 1.0f), 0.7f);
	//return float4(albedo_color.rgb * (0.3f + 3.0f * pow(saturate(ComputeAmbientLight(tex_coord)), 3.0f)), 1.0f);

	//return lerp(float4(0.0f, 1.0f, 0.0f, 1.0f), float4(1.0f, 0.0f, 0.0f, 1.0f), err_ratio);
	//return float4(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).rgb, 1.0f);
	//return float4(lerp(float3(0.0f, 1.0f, 0.0f), float3(1.0f, 0.0f, 0.0f), frac(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).a / 100.0f)), 1.0f);
	//float height_threshold = -5.0f; //5cm
	//float height = SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).a;

	//DEBUG
	//ambient_light = float3(1.0f, 1.0f, 1.0f);
	/*if(height < height_threshold)
		res_color.rgb *= float3(1.0f, 0.0f, 0.0f);
	else
		res_color.rgb *= float3(0.0f, 1.0f, 0.0f);*/
	//albedo_color.rgb = (normalize(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).xyz - float3(0.5f, 0.5f, 0.5f))) * 2.0f;
	//albedo_color.rgb = lerp(float3(0.0f, 1.0f, 0.0f), float3(1.0f, 0.0f, 0.0f), saturate(length(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).xyz - float3(1.0f, 0.5f, 0.75f)) * 10.0f));

	float3 ambient_light = float3(1.0f, 1.0f, 1.0f) * pow(saturate(ComputeAmbientLight(tex_coord)), 3.0f);

	if(length(albedo_color.rgb - float3(0.0f, 0.0f, 0.0f)) < 1e-3f) //black color is color key
		return albedo_color;

	float4 res_color = float4(ambient_light * albedo_color.rgb, albedo_color.a);


	if(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).a < 0.5f)
		res_color += albedo_color * 0.5f;

	/*float4 world_normal = float4((pow(SAMPLE_TEX2D( normal_sampler, SamplerLinearClamp, tex_coord ).xyz, 2.2f) * 2.0f - float3(1.0f, 1.0f, 1.0f)), 0.0f);
	ambient_light = (abs(length(world_normal) - 1.0f) < 0.1f) ? float3(0.0f, 1.0f, 0.0f) : float3(1.0f, 0.0f, 0.0f);*/
	
	return res_color;

	/*float dist = ReadLinearDepth( tex_coord );
	//float dist = SAMPLE_TEX2D( depth_sampler, SamplerLinearClamp, tex_coord ).x;//length(SAMPLE_TEX2D( depth_sampler, SampleLinearClamp, tex_coord ).rgb);
	float3 debug_color = lerp(float3(1.0f, 0.0f, 0.0f), float3(0.0f, 1.0f, 0.0f), frac(dist * 0.01f));
	return lerp(float4(debug_color, 1.0f), albedo_color, 0.5f);*/
}