//PRECOMPILE ps_4_0 BuildCoastline
//PRECOMPILE ps_gnm BuildCoastline
//PRECOMPILE ps_vkn BuildCoastline

#define shoreline_points_count 64
CBUFFER_BEGIN( ccoastline_builder )
	float4 shoreline_points[shoreline_points_count];
	float4 shoreline_point_longitudes[shoreline_points_count];

	float4x4 projection_matrix;
	float4x4 inv_projection_matrix;

	float4x4 view_matrix;
	float4x4 inv_view_matrix;

	int viewport_width;
	int viewport_height;


	float algorithm_phase;
	float step_size;
CBUFFER_END


/*float GetSegmentRatio(float2 testPoint, float2 prevPoint, float2 currPoint, float2 nextPoint)
{
	return asin()
}*/

TEXTURE2D_DECL( gbuffer_reflections_sampler );
TEXTURE2D_DECL( opaque_data_sampler );
TEXTURE2D_DECL( blurred_coastline_sampler );

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
	float4 view_pos = mul( projected_pos, inv_projection_matrix );
	view_pos /= view_pos.w;
	return view_pos.xyz;
}

float2 GetScreenPoint(float3 view_point)
{
	float4 view_point4;
	view_point4.xyz = view_point;
	view_point4.w = 1.0f;
	float4 normalized_pos = mul(view_point4, projection_matrix);
	normalized_pos /= normalized_pos.w;
	float2 screen_point = normalized_pos.xy * 0.5f + float2(0.5f, 0.5f);
	screen_point.y = 1.0f - screen_point.y;
	return screen_point;
}

float3 GetViewDir(float2 screenspace_point)
{
	return normalize(GetViewPoint(screenspace_point, 0.0f));
}


float GetOffscreenFade(float2 screenCoord)
{
	float boundary = 0.1;
	float res = 1.0;
	res *= clamp(screenCoord.x / boundary, 0.0, 1.0);
	res *= clamp((1.0 - screenCoord.x) / boundary, 0.0, 1.0);
	res *= clamp(screenCoord.y / boundary, 0.0, 1.0);
	res *= clamp((1.0 - screenCoord.y) / boundary, 0.0, 1.0);
	return res;
}


float4 BuildCoastline( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float max_dist = 50.0f;
	float2 viewport_size = float2(viewport_width, viewport_height);

	float2 tex_coord = input.screen_coord.xy / viewport_size;

	float4 reflection_refraction_depth = SAMPLE_TEX2DLOD( gbuffer_reflections_sampler, SamplerLinearWrap, float4(tex_coord.xy, 0.0f, 0.0f) );

	float reflection_amount = reflection_refraction_depth.r;
	float refraction_amount = reflection_refraction_depth.g;
	float depth = reflection_refraction_depth.b;


	[branch] if(algorithm_phase < 0.5f)
	{
		bool is_water = refraction_amount > 1e-2f;
		[branch] if(!is_water)
		{
			return float4(1.0f, 1.0f, 0.0f, 1.0f);
		}

		float4 opaque_sample = SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(tex_coord.xy, 0.0f, 0.0f));

		float3 opaque_normal = opaque_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
		float  opaque_depth  = opaque_sample.a;

		float2 offsets[4];
		offsets[0] = float2(-1.0f,  0.0f);
		offsets[1] = float2( 0.0f,  1.0f);
		offsets[2] = float2( 1.0f,  0.0f);
		offsets[3] = float2( 0.0f, -1.0f);

		bool is_coastline = false;

		for(int i = 0; i < 4; i++)
		{
			float4 neighbour_sample = SAMPLE_TEX2DLOD( gbuffer_reflections_sampler, SamplerLinearWrap, float4((tex_coord + offsets[i] / float2(viewport_width, viewport_height)).xy, 0.0f, 0.0f));
			is_coastline = is_coastline || (neighbour_sample.g < 0.5f && abs(neighbour_sample.b - depth) < 15.0f); //neighbour is opaque and close to surface
		}

		float3 view_dir = GetViewDir(tex_coord);
		float3 opaque_view_point = view_dir * opaque_depth;
		float3 water_view_point  = view_dir * depth;

		float3 opaque_world_point = (mul(float4(opaque_view_point, 1.0), inv_view_matrix)).xyz;
		float3 water_world_point  = (mul(float4(water_view_point,  1.0), inv_view_matrix)).xyz;

		float water_depth = max(0.0f, opaque_world_point.z - water_world_point.z);
		//float water_depth = max(0.0f, abs(opaque_depth - depth));

		float3 coastline_data = float3(0.0f, 0.0f, 0.0f);
		if(is_coastline)
			coastline_data = float3(1.0f, 0.0f, 0.0f);
		else
			coastline_data = float3(0.0f, 0.0f, 0.0f);

		//float3 tidal_data = float3(0.0f, max(0.0f, 1.0f - water_depth / 150.0f), 0.0f);
		float min_dist = 1e10f;
		float2 closest_point = float2(0.0f, 0.0f);

		float sum_longitude = 0.0f;
		float sum_longitude_weight = 0.0f;
		float closest_point_longitude = 0.0f;

		float charges_count = 0.0f;
		float potential = 0.0f;

		for(int point_index = 0; point_index < shoreline_points_count - 1; point_index++)
		{
			float curr_point_longitude = shoreline_point_longitudes[point_index].x;
			float next_point_longitude = shoreline_point_longitudes[point_index + 1].x;
			float3 curr_point = shoreline_points[point_index].xyz;
			float3 next_point = shoreline_points[point_index + 1].xyz;
			float edge_length = length(next_point.xy - curr_point.xy) ;
			if(length(curr_point.xy) < 1e-2f || length(next_point.xy) < 1e-2f || edge_length < 1e-2f || edge_length > 1e2f * 10.0f) //skip uninitialized points
				continue;
			float3 edge_normal = normalize(cross(float3(0.0f, 0.0f, 1.0f), curr_point - next_point));
			float point_dist = length(water_world_point.xy - curr_point.xy);

			//float longitude_weight = clamp(1.0f - point_dist / 1000.0f, 0.0f, 1.0f);
			float longitude_weight = 1.0f / (pow(point_dist / 1000.0f, 3.0f) + 1e-8f);
			sum_longitude += curr_point_longitude * longitude_weight;
			sum_longitude_weight += longitude_weight;
			//min_dist = min(min_dist, point_dist);
			if(point_dist < min_dist)
			{
				min_dist = point_dist;
				//closest_point = curr_point.xy;
				closest_point_longitude = curr_point_longitude;
			}
			float ratio = dot(water_world_point.xy - curr_point.xy, next_point.xy - curr_point.xy) / (dot(next_point.xy - curr_point.xy, next_point.xy - curr_point.xy) + 1e-5f);
			if(ratio > 0.0f && ratio < 1.0f)
			{
				float2 edge_point = curr_point.xy + (next_point.xy - curr_point.xy) * ratio;
				float edge_dist = abs(dot(water_world_point.xy - curr_point.xy, edge_normal.xy));
				if(edge_dist < min_dist)
				{
					min_dist = edge_dist;
					//closest_point = edge_point;
					//closest_point_longitude = curr_point_longitude + ratio * length(next_point.xy - curr_point.xy);
					closest_point_longitude = lerp(curr_point_longitude, next_point_longitude, ratio);
				}
				//min_dist = min(min_dist, edge_dist);
			}

			float _step = 0.1f;
			float norm_step = edge_length / _step;
			for(float param = 0.0f; param < 1.0f; param += 0.1f)
			{
				float3 charge_pos = curr_point + (next_point - curr_point) * param;
				potential += 1.0f / (length(charge_pos.xy - water_world_point.xy));
				charges_count += 1.0f;
			}
		}
		//closest_point_longitude = shoreline_point_longitudes[15];
		//min_dist = 0.43f / (potential / charges_count);
		//closest_point = water_world_point.xy;
		if(water_depth > 50.0f) water_depth = 1e5f;
		float ratio = 1.0f - pow(1.0f -  clamp(1.0f - water_depth / 50.0f, 0.0f, 1.0f), 1.0f);
		//ratio = 0.0f;
		float slope = 0.2f;
		//float3 tidal_data = float3(0.0f, max(0.0f, 1.0f - lerp((min_dist) * slope, water_depth, ratio) / 250.0f / 2.0f), sum_longitude / (sum_longitude_weight + 1e-8f));
		float3 tidal_data = float3(0.0f, max(0.0f, 1.0f - lerp((min_dist) * slope, water_depth, ratio) / 250.0f / 2.0f), closest_point_longitude);
		//float3 tidal_data = float3(0.0f, closest_point.x - water_world_point.x, closest_point.y - water_world_point.y);
		//float3 tidal_data = float3(0.0f, max(0.0f, 1.0f - (min_dist + 300.0f) * slope / 125.0f), 0.0f);
		//float3 tidal_data = float3(0.0f, min_dist < 300.0f ? 0.0f : 1.0f, 0.0f);

		float4 res;
		res.rgb = coastline_data + tidal_data;
		res.a = 1.0f;
		return res;
	}else
	{
		float4 center_coastline_sample = SAMPLE_TEX2DLOD( blurred_coastline_sampler, SamplerLinearWrap, float4(tex_coord.xy, 0.0f, 0.0f) );
		//return center_coastline_sample;
		float2 center_screen_pos = tex_coord;
		float3 center_depth = depth;
		float3 center_view_pos = GetViewDir(center_screen_pos) * center_depth;
		float3 center_world_pos = (mul(float4(center_view_pos, 1.0), inv_view_matrix)).xyz;


		float2 offsets[8];
		offsets[0] = float2(-1.0f, -1.0f);
		offsets[1] = float2( 0.0f, -1.0f);
		offsets[2] = float2( 1.0f, -1.0f);
		offsets[3] = float2( 1.0f,  0.0f);
		offsets[4] = float2( 1.0f,  1.0f);
		offsets[5] = float2( 0.0f,  1.0f);
		offsets[6] = float2(-1.0f,  1.0f);
		offsets[7] = float2(-1.0f,  0.0f);
		float closest_dist = 1.0f - center_coastline_sample.r;

		float tidal_depth = center_coastline_sample.g;
		float tidal_longitude = center_coastline_sample.b;
		//float2 mid_nearest_point = center_coastline_sample.gb;
		float neighbours_count = 1.0f;
		float valid_neighbours_count = 1.0f;
		for(int i = 0; i < 8; i++)
		{
			float2 neighbour_screen_pos = tex_coord + offsets[i] / float2(viewport_width, viewport_height);

			float4 neighbour_refraction_sample = SAMPLE_TEX2DLOD( gbuffer_reflections_sampler, SamplerLinearWrap, float4(tex_coord + offsets[i] * step_size / float2(viewport_width, viewport_height), 0.0f, 0.0f));
			float neighbour_depth = neighbour_refraction_sample.b;
			float neighbour_refraction = neighbour_refraction_sample.g;
			float3 neighbour_view_pos = GetViewDir(neighbour_screen_pos) * neighbour_depth;
			float3 neighbour_world_pos = (mul(float4(neighbour_view_pos, 1.0), inv_view_matrix)).xyz;
			float delta_dist = length(neighbour_world_pos - center_world_pos) / max_dist;

			float4 neighbour_sample = SAMPLE_TEX2DLOD( blurred_coastline_sampler, SamplerLinearWrap, float4(neighbour_screen_pos, 0.0f, 0.0f));
			float neighbour_dist = 1.0f - neighbour_sample.r;

			float weight = 1.0f;//neighbour_refraction > 1e-1f ? 1.0f : 0.0f;
			tidal_depth += neighbour_sample.g * weight;
			neighbours_count += weight;

			float valid_weight = neighbour_refraction > 1e-1f ? 1.0f : 0.0f;
			tidal_longitude += neighbour_sample.b * valid_weight;
			valid_neighbours_count += valid_weight;

			//mid_nearest_point += neighbour_sample.gb * weight;
			float curr_dist = neighbour_dist + delta_dist;
			//closest_dist = min(closest_dist, curr_dist);
			closest_dist = min(closest_dist, curr_dist);
		}
		return float4(max(1.0f - closest_dist, 0.0f), max(center_coastline_sample.g, tidal_depth / neighbours_count), tidal_longitude / valid_neighbours_count, 1.0f);
		//return float4(max(1.0f - closest_dist, 0.0f), mid_nearest_point.x / neighbours_count, mid_nearest_point.y / neighbours_count, 1.0f);
	}
}
