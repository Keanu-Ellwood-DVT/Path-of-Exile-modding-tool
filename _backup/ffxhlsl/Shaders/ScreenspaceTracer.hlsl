//PRECOMPILE ps_4_0 BuildReflection
//PRECOMPILE ps_gnm BuildReflection
//PRECOMPILE ps_vkn BuildReflection

CBUFFER_BEGIN( cscreenspace_tracer_desc )
	int viewport_width;
	int viewport_height;

	float4 scene_size;
	float4 coord_tex_offset;

	float4x4 projection_matrix;
	float4x4 inv_projection_matrix;

	float4x4 view_matrix;
	float4x4 inv_view_matrix;

	bool exp_fog_enabled;
	float4 exp_fog_color;
	float4 exp_fog_values;

	bool linear_fog_enabled;
	float4 linear_fog_color;
	float4 linear_fog_values;

	float numerical_normal;
	float current_time;

	float sum_longitude;
	float dist_to_color;

	float4 ambient_light_color;
	float4 ambient_light_dir;
CBUFFER_END

#define DETAIL_LEVEL 0

TEXTURE2D_DECL( surface_tex_sampler );
TEXTURE2D_DECL( framebuffer_sampler );
TEXTURE2D_DECL( gbuffer_normals_sampler );
TEXTURE2D_DECL( gbuffer_reflections_sampler );
TEXTURE2D_DECL( opaque_data_sampler );
TEXTURECUBE_DECL( environment_cube_sampler );
TEXTURE2D_DECL( coastline_data_sampler );

TEXTURE2D_DECL( wave_data_sampler );
TEXTURE2D_DECL( wave_gradient_sampler );
TEXTURE2D_DECL( distortion_sampler );
TEXTURE2D_DECL( water_tex_sampler );
TEXTURE2D_DECL( coastline_coord_tex_sampler );
TEXTURE2D_DECL( caustics_tex_sampler );

struct PInput
{
	float4 screen_coord : SV_POSITION;
	float2 tex_coord : TEXCOORD0;
};

float FixDepth(float raw_depth)
{
	return raw_depth > 0.0f ? raw_depth : 1e5f;
}

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

struct RaytraceResult
{
	bool is_found;
	float3 view_point;
};

float3 GetSunDir()
{
	const float3 sunDir = float3( -1.0f, 0.25f, -0.7f );
	return normalize( sunDir );
}

float3 GetSkyColor2(float3 e)
{
	float z = max(-e.z,0.0);
	float3 ret;
	ret.x = pow(1.0-z,2.0);
	ret.y = 1.0-z;
	ret.z = 0.6+(1.0-z)*0.4;
	return ret;
}

float3 GetSkyColor( float3 rayDir )
{
	const float3 sunColor = float3( 1.0, 0.85, 0.5 ) * 5.0;
	const float3 skyColor = float3( 0.1, 0.5, 1.0 ) * 1.0;
	const float3 bgSkyColorUp = skyColor * 4.0;
	const float3 bgSkyColorDown = skyColor * 6.0;

	float3 resultColor = lerp( bgSkyColorDown, bgSkyColorUp, clamp( -rayDir.z, 0.0, 1.0 ) );
	float sunDotView = dot(GetSunDir(), rayDir);
	float dirDot = clamp(sunDotView * 0.5 + 0.5, 0.0, 1.0);
	resultColor += sunColor * (1.0 - exp2(dirDot * -0.5)) * 0.5f;

	return resultColor;
}

void CalculateFog( float3 world_ray_start, float3 world_ray_end, float fog_height_level, float max_fog_length, out float out_fog )
{
	float3 dist = world_ray_start - world_ray_end;
	float fog_depth = max(world_ray_start.z, world_ray_end.z) - fog_height_level;

	float ray_percent = saturate( fog_depth / abs( dist.z ) );
	float fog_length = length( dist ) * ray_percent;
	out_fog = saturate( fog_length / max_fog_length );
}

float4 GetFogDensity(float3 world_ray_start, float3 world_ray_end, float3 cam_world_pos, float3 fog_color, float4 fog_values, float fog_power)
{
	float fog_height_level;
	if(fog_values.z > 0.0f)
	{
		fog_height_level = cam_world_pos.z + fog_values.x;
	}else
	{
		fog_height_level = fog_values.x;
	}

	float fog_ratio;
	CalculateFog(world_ray_start, world_ray_end, fog_height_level, fog_values.y, fog_ratio);
	fog_ratio = saturate( pow( fog_ratio, fog_power ) );
	return saturate( float4( fog_color * fog_ratio, fog_ratio ) );
}

float4 GetResFogDensity(float3 world_ray_start, float3 world_ray_end, float3 cam_world_pos)
{
	float4 exp_fog_density = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 linear_fog_density = float4(0.0f, 0.0f, 0.0f, 0.0f);

	if(exp_fog_enabled)
		exp_fog_density = GetFogDensity(world_ray_start, world_ray_end, cam_world_pos, exp_fog_color.rgb, exp_fog_values, exp_fog_values.w);
	if(linear_fog_enabled)
		linear_fog_density = GetFogDensity(world_ray_start, world_ray_end, cam_world_pos, linear_fog_color.rgb, linear_fog_values, 1.0f);
	float4 res_fog_density = saturate(float4(linear_fog_density.rgb + exp_fog_density.rgb, linear_fog_density.a + exp_fog_density.a));
	return res_fog_density;
}

float4 ApplyResultFog(float3 world_ray_start, float3 world_ray_end, float3 cam_world_pos, float4 surface_color)
{
	float4 res_fog_density = GetResFogDensity(world_ray_start, world_ray_end, cam_world_pos);
	return float4(surface_color.rgb * (1.0f - res_fog_density.a) + res_fog_density.rgb, surface_color.a);
}

float Spline(float val)
{
	return 3.0f * val * val - 2.0f * val * val * val;
}


float3 BuildRaytraceLightResult(float3 view_ray_origin, float3 view_ray_dir, RaytraceResult raytrace_result, float medium_density, float3 medium_color, float3 light_color, float ground_water_ratio, bool use_fade, bool use_sand)
{
	float3 world_ray_dir = (mul(float4(view_ray_dir, 0.0), inv_view_matrix)).xyz;
	float3 world_ray_end = (mul(float4(raytrace_result.view_point, 1.0), inv_view_matrix)).xyz;
	float3 world_ray_origin = (mul(float4(view_ray_origin, 1.0), inv_view_matrix)).xyz;
	float3 cam_world_pos = (mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0), inv_view_matrix)).xyz;

	float3 env_color = SAMPLE_TEXCUBELOD(environment_cube_sampler, SamplerPointClamp, float4(world_ray_dir.xyz/* * float3(-1.0f, -1.0f, -1.0f)*/, 0.0f)).xyz * 2.0f;
	//float3 env_color = GetSkyColor(world_ray_dir.xyz);
	//float3 env_color = GetSkyColor2(world_ray_dir.xyz);
	//float3 env_color = float3(0.5, 0.5, 0.5);
	float3 res_color = ApplyResultFog(world_ray_origin, world_ray_origin + world_ray_dir * 1e4f, cam_world_pos, float4(env_color, 1.0f)).rgb; //100m ray
	//float3 res_color = ApplyResultFog(world_ray_origin + world_ray_dir * 1e4f, world_ray_origin, float4(env_color, 1.0f)).rgb; //100m ray
	[branch]
	if(raytrace_result.is_found)
	{
		float3 res_view_point = raytrace_result.view_point;
		float2 res_screen_point = GetScreenPoint(res_view_point);

		/*if(true || !use_fade)
		{
			float2 start_screen_point = GetScreenPoint(view_ray_origin);
			res_screen_point += normalize(start_screen_point - res_screen_point) * 2.0f / viewport_width * (1.0f - derivative_fade);

			float3 dir = GetViewDir(res_screen_point);
			res_view_point = dir * FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(res_screen_point.xy, 0.0f, 0.0f)).a);
		}*/

		float res_fade = 1.0f;//use_fade ? 1.0f/* derivative_fade*/ : 1.0f * GetOffscreenFade(res_screen_point); //DEBUG
		float3 ray_color = SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(res_screen_point, 0.0f, 0.0f)).xyz;
		/*
		//water_caustic_add.dds
		if(medium_density > 0.0f)
		{
			float caustics_intensity = exp(-pow(abs(abs(world_ray_end.z - world_ray_origin.z) - 40.0f), 2.0f) * 0.5e-2f) * 1.8f;

		 	float2 distortion_pos = world_ray_end.xy * 1e-3f + float2(1.0f, 0.3f) * current_time * 0.05f;
			float2 distortion_vec = (SAMPLE_TEX2DLOD( distortion_sampler, SamplerLinearWrap, float4(distortion_pos, 0.0f, 0.0f) ).rg * 2.0f - float2(1.0f, 1.0f)) * 4e-1f * 1.0f;

			float2 tex_pos = world_ray_end.xy * 3e-3f + distortion_vec;
			float3 sample_color = SAMPLE_TEX2DLOD( caustics_tex_sampler, SamplerLinearWrap, float4(tex_pos, 0.0f, 0.0f) ).rgb;
			float3 caustic_diff = float3(1.0f, 1.0f, 1.0f) +
				(pow(sample_color, 1.0f / 3.2f) * 2.0f - float3(1.0f, 1.0f, 1.0f)) * caustics_intensity * light_color;
			ray_color *= caustic_diff;
		}*/
		float result_density = medium_density;
		float3 result_medium_color = medium_color;

		float travel_dist = length(view_ray_origin - res_view_point);
		float medium_ratio = exp(-travel_dist * result_density);

		//for water_caustics_2.dds
		if(medium_density > 0.0f)
		{
			float deep_caustics_intensity = saturate(abs(abs(world_ray_end.z - world_ray_origin.z)) * 0.02f) * medium_ratio * 1.3f;//exp(-pow(abs(abs(world_ray_end.z - world_ray_origin.z) - 40.0f), 2.0f) * 0.5e-2f) * 1.1f * 0.8f;
			//float deep_caustics_intensity = exp(-pow(abs(abs(world_ray_end.z - world_ray_origin.z) - 40.0f), 2.0f) * 0.5e-2f) * 1.1f * 0.8f;
			float shallow_depth = 10.0f;
			float shallow_caustics_intensity = Spline(saturate(abs(world_ray_end.z - world_ray_origin.z) / shallow_depth)) * 0.7f * saturate((ground_water_ratio - 0.5f) * 2.0f);
			float deep_freq_mult = 1.0f;
			float shallow_freq_mult = 3.0f;

			float caustics_intensity = lerp(deep_caustics_intensity, shallow_caustics_intensity, saturate(ground_water_ratio * 2.0f));
			float freq_mult = lerp(deep_freq_mult, shallow_freq_mult, saturate(ground_water_ratio * 2.0f));
			/*else
			{
				float shallow_depth = 10.0f;
				caustics_intensity = Spline(saturate(abs(world_ray_end.z - world_ray_origin.z) / shallow_depth)) * 0.7f;
				freq_mult = 3.0f;
			}*/


			caustics_intensity *= 1.0f - GetResFogDensity(world_ray_end, world_ray_end + float3(0.0f, 0.0f, -10000.0f), cam_world_pos).a; //caustics light source is 100m above surface

			float2 distortion_pos = world_ray_end.xy * 1e-3f * freq_mult + float2(1.0f, 0.3f) * current_time * 0.05f;
			float2 distortion_vec = (SAMPLE_TEX2DLOD( distortion_sampler, SamplerLinearWrap, float4(distortion_pos, 0.0f, 0.0f) ).rg * 2.0f - float2(1.0f, 1.0f)) * 4e-1f;

			float2 tex_pos = world_ray_end.xy * 2e-3f * freq_mult + distortion_vec;
			float3 sample_color = clamp(pow(SAMPLE_TEX2DLOD( caustics_tex_sampler, SamplerLinearWrap, float4(tex_pos, 0.0f, 0.0f) ).rgb, 1.0f / 4.2f) * 1.0f, 0.0f, 1.0f);
			sample_color = float3(1.0f, 1.0f, 1.0f) * sample_color.g;
			float3 caustic_diff = float3(1.0f, 1.0f, 1.0f) +
				(sample_color * 2.0f - float3(1.0f, 1.0f, 1.0f)) * caustics_intensity * light_color;
			ray_color *= caustic_diff;
		}

		res_color = ray_color * res_fade + env_color * (1.0f - res_fade);


		res_color = res_color * medium_ratio + result_medium_color * (1.0f - medium_ratio);
	}else
	if(medium_density > 0.0f)
	{
		res_color = medium_color;
	}
	return res_color;
}

RaytraceResult GetRaytracedLightViewStepping(float3 view_ray_origin, float3 view_ray_dir)
{
	const float depth_tolerance = 5e0f;


	float3 curr_view_point = view_ray_origin;
	float step_mult = 10.0f;

	bool intersection_found = true;

	float2 start_screen_point = GetScreenPoint(view_ray_origin);
	float start_gbuffer_depth = FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(start_screen_point.xy, 0.0f, 0.0f)).a);
	float3 intersection_view_point = normalize(view_ray_origin) * start_gbuffer_depth;

	for(int i = 0; (i < 3 + DETAIL_LEVEL / 2) /*&& !intersection_found*/; i++)
	{
		float3 new_view_point = curr_view_point + view_ray_dir * step_mult;
		float2 new_screen_point = GetScreenPoint(new_view_point);

		float gbuffer_depth = FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(new_screen_point.xy, 0.0f, 0.0f)).a);

		float new_depth = length(new_view_point);

		if(new_depth > gbuffer_depth)
		{
			step_mult *= 0.5f;

			//if(abs(gbuffer_depth - new_depth) < depth_tolerance)
			{
				intersection_found = true;
				//intersection_view_point = new_view_point;
				//break;
			}
		}else
		{
			curr_view_point = new_view_point;
			intersection_view_point = normalize(new_view_point) * gbuffer_depth;
		}
	}

	RaytraceResult res;
	res.is_found = intersection_found;
	res.view_point = intersection_view_point;
	return res;
}

float3 RayPlaneIntersect(float3 plane_point, float3 plane_norm, float3 ray_origin, float3 ray_dir)
{
	//((ray_origin + ray_dir * param) - plane_point) * plane_norm = 0
	float param = (dot(plane_norm, plane_point) - dot(ray_origin, plane_norm)) / dot(ray_dir, plane_norm);
	return ray_origin + ray_dir * param;
}

RaytraceResult GetRaytracedLightCheap(float3 view_ray_origin, float3 view_ray_dir)
{
	float2 screen_point = GetScreenPoint(view_ray_origin);
	float gbuffer_depth = FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(screen_point.xy, 0.0f, 0.0f)).a);
	float approx_travel_dist = max(0.0f, gbuffer_depth - length(view_ray_origin));
	RaytraceResult res;
	res.is_found = true;
	res.view_point = view_ray_origin + view_ray_dir * approx_travel_dist;
	return res;
}


RaytraceResult GetRaytracedLightScreenStepping(float3 view_ray_origin, float3 view_ray_dir)
{
	float object_width = 30.0f;

	float3 curr_view_point = view_ray_origin;
	float step_mult = 25.0f / viewport_width;

	float2 curr_screen_point = GetScreenPoint(view_ray_origin);
	float2 eps_screen_point = GetScreenPoint(view_ray_origin + view_ray_dir * 1e0f);
	float2 screen_ray_dir = normalize(eps_screen_point - curr_screen_point);

	bool intersection_found = false;
	float3 intersection_view_point = view_ray_origin;

	float3 ray_plane_view_norm = normalize(cross(view_ray_dir, cross(view_ray_dir, view_ray_origin - float3(0.0f, 0.0f, 0.0f))));

	for(int i = 0; (i < 30)/* && step_mult > 0.1f / viewport_width*/ /*!intersection_found*/; i++)
	{
		float2 new_screen_point = curr_screen_point + screen_ray_dir * step_mult;
		float3 new_view_point;
		{
			float3 dir = GetViewDir(new_screen_point);
			new_view_point = RayPlaneIntersect(view_ray_origin, ray_plane_view_norm, float3(0.0f, 0.0f, 0.0f), dir);
		}

		float gbuffer_depth = FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(new_screen_point.xy, 0.0f, 0.0f)).a);
		float new_depth = length(new_view_point);

		if(new_depth < gbuffer_depth)
		{
			curr_screen_point = new_screen_point;
			intersection_view_point = new_view_point;
		}else
		if(new_depth < gbuffer_depth + object_width)
		{
			step_mult *= 0.5f;
			intersection_found = true;
		}
	}



	RaytraceResult res;
	res.is_found = intersection_found;
	res.view_point = intersection_view_point;
	return res;
}

float3 GetReflectionCoefficient2( float3 vView, float3 vNormal, float n)
{
	float fGloss = 1.0f;
	float r0 = 0.1f;//0.01f / n;
	float3 vR0 = float3(r0, r0, r0);
	float NdotV = max( 0.0f, dot( normalize(vView), normalize(vNormal) ) );

	return vR0 + (float3(1.0f, 1.0f, 1.0f) - vR0) * pow( 1.0f - NdotV, 5.0f ) * pow( fGloss, 20.0f );
}

float GetReflectionCoefficient(float3 incidentLightDir, float3 surfaceNormal, float refractionCoefficient)
{
	return 0.02f + pow(1.0 + clamp(dot(normalize(incidentLightDir), normalize(surfaceNormal)), -1.0f, 0.0f), 3.0) * 0.8;
}

struct Field
{
	float value;
	float2 gradient;
};

Field FieldMul(in Field f, in Field g)
{
	Field res;
	res.value = f.value * g.value;
	res.gradient = float2(f.gradient.x * g.value + f.value * g.gradient.x, f.gradient.y * g.value + f.value * g.gradient.y);
	return res;
}

Field FieldMulScalar(in Field f, in float v)
{
	Field res;
	res.value = f.value * v;
	res.gradient = f.gradient * v;
	return res;
}

Field FieldAdd(in Field f, in Field g)
{
	Field res;
	res.value = f.value + g.value;
	res.gradient = f.gradient + g.gradient;
	return res;
}

Field FieldSub(in Field f, in Field g)
{
	Field res;
	res.value = f.value - g.value;
	res.gradient = f.gradient - g.gradient;
	return res;
}

Field FieldConst(in float v)
{
	Field res;
	res.value = v;
	res.gradient = float2(0.0f, 0.0f);
	return res;
}

Field FieldPow(in Field f, in float p)
{
	Field res;
	res.value = pow(saturate(f.value), p);
	res.gradient = f.gradient * pow(saturate(f.value), p - 1.0f) * p;
	return res;
}

Field GetSmoothNoise( float2 planarPoint );
float GetSmoothNoise3( float3 volumePoint );
float GetLinearNoise3( float3 volumePoint );
float GetVoronoiNoise( float2 planePoint );


//octaveDamping = 0.75
//selfAffection = 0.25, gradient. 0 is fine either, noise self-affection
Field GetWaterNoise( float2 planarPos, float2 flowPos, float octaveDamping, float selfAffection )
{
	Field result;
	result.value = 0.0f;
	result.gradient = float2(0.0f, 0.0f);
	float sumAmplitude = 0.0f;
	float octaveAmplitude = 1.0f;
	const int octavesCount = 10;
	float ampMult = 1.0f;
	float freqMult = 1.0f;
	for( int i = 0; i < octavesCount; i++)
	{
		planarPos += flowPos;
		flowPos *= -0.75f;
		Field octaveNoise = GetSmoothNoise( planarPos );
		result.value += octaveNoise.value * octaveAmplitude * ampMult;
		result.gradient += octaveNoise.gradient * octaveAmplitude * freqMult * ampMult;
		planarPos += octaveNoise.gradient * selfAffection;
		planarPos *= 2.0;
		freqMult *= 2.0f;
		ampMult *= 0.5f;
		sumAmplitude += octaveAmplitude;
		octaveAmplitude *= octaveDamping;
	}
	result.value /= sumAmplitude;
	result.gradient /= sumAmplitude;
	return result;
}

struct WaveState
{
	Field heightField;
	float4 foamColor;
	float2 turbulenceOffset;
	float groundWaterRatio;
	float waterToTerrainRatio;
	float foamRippleDampening;
};

struct WaterSurface
{
	WaveState waveState;
	float3 normal;
	float curvature;
	float2 planarPos;
};

float SafePow(float value, float power)
{
	return pow(clamp(value, 0.0f, 1.0f), power);
}

Field GetOceanWaterOctave(float2 planarPos, float spikiness)
{
	{
		Field res;
		//float freqMult = 8.0f;
		//float ampMult = 1.0f;
		float freqMult = 4.0f;
		float ampMult = 3.0f;
		/*float freqMult = 2.5f;
		float ampMult = 5.0f;*/
		//DEBUG
		float textureSize = 128.0f;
		float4 color_sample = SAMPLE_TEX2DLOD( surface_tex_sampler, SamplerLinearWrap, float4(planarPos / textureSize * freqMult, 0.0f, 0.0f));
		res.value = (color_sample.r - 0.4f) * ampMult;
		res.gradient = color_sample.gb * ampMult * freqMult;
		return res;
	}
	{
		Field res;
		float noiseValue = GetSmoothNoise(planarPos).value;
		planarPos += float2(noiseValue, noiseValue);
		float2 mixedWave = (abs(sin(planarPos)) + abs(cos(planarPos))) * (1.0f - abs(sin(planarPos)));
		res.value = SafePow(1.0 - SafePow(mixedWave.x * mixedWave.y, 0.65), spikiness) - 0.5f;
		res.gradient = float2(0.0f, 0.0f);
		return res;
	}
	/*{
		Field res;
		float s = sin(planarPos.x * 10.0f);
		res.value = s * sign(s);
		res.gradient = float2(cos(planarPos.x * 10.0f) * 10.0f * sign(s), 0.0f);
		return res;
	}*/
	float noiseValue = GetSmoothNoise(planarPos).value;
  planarPos += float2(noiseValue, noiseValue);
  /*float2 sineWave = 1.0 - abs(sin(planarPos));
  float2 cosineWave = abs(cos(planarPos));
  float2 mixedWave = lerp(sineWave, cosineWave, sineWave);*/

	float2 sinVal = sin(planarPos);
	float2 cosVal = cos(planarPos);

	float2 sinSign = sign(sinVal);
	float2 cosSign = sign(cosVal);

	float2 absSin = sinVal * sinSign;
	float2 absCos = cosVal * cosSign;

	float2 absSinDerivatives = cosVal * sinSign;//xx and yy
	float2 absCosDerivatives = -sinVal * cosSign;//xx and yy

	float2 mixedVal = (abs(sin(planarPos)) + abs(cos(planarPos))) * (1.0f - abs(sin(planarPos)));

	Field xMixedField;
	xMixedField.value = (absSin.x + absCos.x) * (1.0f - absSin.x);//mixedVal.x;
	xMixedField.gradient = float2((absSinDerivatives.x + absCosDerivatives.x) * (1.0f - absSin.x) + (absSin.x + absCos.x) * -absSinDerivatives.x, 0.0f);

	Field yMixedField;
	yMixedField.value = (absSin.y + absCos.y) * (1.0f - absSin.y);
	yMixedField.gradient = float2(0.0f, (absSinDerivatives.y + absCosDerivatives.y) * (1.0f - absSin.y) + (absSin.y + absCos.y) * -absSinDerivatives.y);

	//Field mixedField = FieldMul(xMixedField, yMixedField);

	//return FieldMul(xMixedField, yMixedField);
	Field res = FieldSub(FieldPow(FieldSub(FieldConst(1.0f), FieldPow(FieldMul(xMixedField, yMixedField), 0.65)), spikiness), FieldConst(0.5f));
	return res;

}

float4 Uberblend(float4 col0, float4 col1)
{
	return float4(
    (1.0 - col0.a) * (1.0 - col1.a) * (col0.rgb * col0.a + col1.rgb * col1.a) / (col0.a + col1.a + 1e-2f) +
    (1.0 - col0.a) * (0.0 + col1.a) * (col1.rgb) +
    (0.0 + col0.a) * (1.0 - col1.a) * (col0.rgb * (1.0 - col1.a) + col1.rgb * col1.a) +
    (0.0 + col0.a) * (0.0 + col1.a) * (col1.rgb),
    min(1.0, col0.a + col1.a));
}

float4 GetFoamColor2(float2 planarPos, float2 planarOffset, float2 travelDir, float trailIntensity, float frontIntensity, float constantFoam, float shallowRatio, float time)
{
	//depthGradient = float2(0.0f, -1.0f);
	float resIntensity = 0.0f;
	float sumAmplitude = 0.0f;
	float octaveAmplitude = 1.0f;
	const int octavesCount = 3;
	float selfAffection = 1.0f;
	float ampMult = 1.0f;
	float freqMult = 1.0f;
	float octaveDamping = 0.5f;
	float sumNoise = 0.0f;

	float maxScrollingSpeed = 1.1f;
	//trail
	float sumMult = 0.0f;
	float2 scrolledPos = planarPos;
	float2 offsetPos = scrolledPos + planarOffset;
	for( int i = 0; i < octavesCount; i++)
	{
		float octaveNoise = GetVoronoiNoise( offsetPos * 0.25f ) * ampMult;
		//float octaveNoise = (GetSmoothNoise( planarPos * 0.5f ).value * 0.5f + 0.5f) * ampMult;
		//float octaveNoise = (1.0f - GetOceanWaterOctave( planarPos * 0.25f, 4.0f )) * ampMult;
		sumMult += ampMult;
		sumNoise += octaveNoise;
		offsetPos *= 2.0f;
		freqMult *= 2.0f;
		//ampMult *= lerp(0.8f, 0.8f, pow(intensity, 1.0f));
		//ampMult *= lerp(0.5f, 1.3f, pow(trailIntensity, 1.0f));
		ampMult *= lerp(0.5f, 1.3f, pow(trailIntensity, 1.0f));
		//ampMult *= 0.5f;//lerp(0.5f, 1.3f, pow(intensity, 1.0f));
	}
	/*sumNoise = SAMPLE_TEX2DLOD( water_tex_sampler, SamplerLinearWrap, float4(offsetPos.xy * 0.1f, 0.0f, 0.0f)).a;
	sumMult = 1.0f;*/
	float clampedIntensity = clamp(trailIntensity - 0.03f/* + constantFoam*/, 0.0f, 1.0f);
	clampedIntensity = lerp(clampedIntensity, 0.0f, SafePow(shallowRatio, 7.0f));
	float threshold = (1.0 - pow(clamp(1.0f - clampedIntensity, 0.0f, 1.0f), 1.0)) * 0.4f + 0.05f;
	float slope = 10.0f;

	float transparencyFade = (1.0f - pow(1.0f - clampedIntensity, 1.0f));


	//front edge

	float ang = 0.5f;
	float2x2 octaveMatrix = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang)) * 1.2f;
	float2x2 resultMatrix = float2x2(1.0f, 0.0f, 0.0f, 1.0f);
	float4 leadingEdgeColor = float4(0.0f, 0.0f, 0.0f, 0.0f);

	if(frontIntensity >= 1e-2f)
	{
		const int iterationsCount = DETAIL_LEVEL > 5 ? 4 : 3;
		for(int j = 0; j < iterationsCount; j++)
		{
			float layerRatio = float(j) / float(iterationsCount - 1);
			resultMatrix = mul(resultMatrix, octaveMatrix);
			float4 distortionPos;
			//distortionPos.xy = planarPos * (1e-1f + j * 0.2e-1f) + float2(0.0f, -1.0f) * time * 1.1e-0f;
			//float layerScrollSpeed = j == 0 ? 0.0f : lerp(0.35f, 0.18f, layerRatio);
			float layerScrollSpeed = j == 0 ? 0.0f : lerp(0.35f, 0.15f, layerRatio);
			float layerScale = j == 0.0f ? 1.0f : 1.5f;//lerp(1.1f, 1.5f, layerRatio);


			float scrollPeriod = 1.0f;
			float scrollPhase = frac(time / scrollPeriod + sin(j * 42.0f));// - 0.5f;
			//scrollTime = time;

			float4 layerColor = float4(0.0f, 0.0f, 0.0f, 0.0f);

			float weights[2];
			weights[0] = min(scrollPhase * 2.0f, 2.0f - scrollPhase * 2.0f);
			weights[1] = 1.0f - weights[0];
			float localPhases[2];
			localPhases[0] = scrollPhase;
			localPhases[1] = frac(scrollPhase + 0.5f);

			for(int i = 0; i < 2; i++) //sublayers for continuous scrolling
			{
				//TODO: try tangential scrolling
				distortionPos.xy = mul(resultMatrix, planarPos * 0.5e-1f * layerScale + travelDir * (localPhases[i] - 0.5f) * scrollPeriod * layerScrollSpeed / layerScale);
				distortionPos.z = 0.0f;
				distortionPos.w = 0.0f;
				float4 distortionSample = SAMPLE_TEX2DLOD( distortion_sampler, SamplerLinearWrap, distortionPos) * 2.0f - float4(1.0f, 1.0f, 1.0f, 1.0f);

				float4 waterTexPos;
				//waterTexPos.xy = planarPos.xy * (1.3e-1f + j * 0.3e-1f) + float2(0.0f, -1.0f) * time * 1.4e-0f + float2(0.3f, 0.3f) * j;
				//waterTexPos.xy = planarPos.xy * (1.3e-1f + j * 0.3e-1f) + float2(0.0f, -1.0f) * time * 1.4e-0f + float2(0.3f, 0.3f) * j;
				float currPhase = scrollPhase;
				float scale = 2.0f * layerScale;
				waterTexPos.xy = mul(resultMatrix, planarPos * 0.25e-1f * scale + travelDir * (localPhases[i] - 0.5f) * scrollPeriod * layerScrollSpeed * scale);
				waterTexPos.z = 0.0f;
				waterTexPos.w = 0.0f;

				float2 layer_offset = distortionSample.rg * (0.05f + (1.0f - frontIntensity) * 0.1f);
				float2 distortion_offset = lerp(planarOffset * 0.1f, layer_offset, 1.0f - SafePow(1.0f - frontIntensity, 5.0f)) * ((j == 0) ? 0.0f : 0.5f);
				//float2 distortion_offset = layer_offset;
				waterTexPos.xy += distortion_offset;

				layerColor += SAMPLE_TEX2DLOD( water_tex_sampler, SamplerLinearWrap, waterTexPos) * weights[i];
			}

			float shallowAlphaSub = clamp(SafePow(shallowRatio, 14.0f), 0.0f, 1.0f);
			//if(j != 0)
			{
				layerColor.a = clamp((layerColor.a - shallowAlphaSub) / (1.0f - shallowAlphaSub + 1e-3f), 0.0f, 1.0f);
			}

			//float layerChunkinessPow = j == 0 ? 1.0f : lerp(2.0f, 1.0f, layerRatio);
			float layerChunkinessPow = j == 0 ? 2.0f : lerp(3.5f, 1.5f, layerRatio);
			//float threshold = pow(clamp(frontIntensity / 0.8f, 0.0f, 1.0f), layerChunkinessPow);
			float _threshold = pow(clamp(frontIntensity / 1.0f, 0.0f, 1.0f), layerChunkinessPow);
			layerColor.a = clamp(layerColor.a / _threshold, 0.0f, 1.0f);

			//float layerLengthPow = j == 0 ? 1.3f : lerp(1.0f, 3.5f, layerRatio);
			float layerLengthPow = j == 0 ? 1.0f : lerp(1.5f, 2.5f, layerRatio);
			float alphaSub = clamp(1.0f - SafePow(1.0f - frontIntensity, layerLengthPow * 1.0f), 0.0f, 1.0f);

			layerColor.a = clamp((layerColor.a - alphaSub) / (1.0f - alphaSub + 1e-3f), 0.0f, 1.0f);
			//layerColor.a *= 0.5f;
			layerColor.rgb *= lerp(0.3f, 1.0f, layerRatio);

			//leadingEdgeColor = Uberblend(layerColor, leadingEdgeColor);//max(layerColor, leadingEdgeColor);
			leadingEdgeColor = Uberblend(leadingEdgeColor, layerColor);//max(layerColor, leadingEdgeColor);
		}
	}
	//leadingEdgeColor.a *= clamp((trailIntensity - 0.5f) * 100.0f, 0.0f, 1.0f);
	//leadingEdgeColor.a *= clamp(trailIntensity * 10.0f, 0.0f, 1.0f);

	float clampedNoise = clamp(sumNoise / sumMult, 0.0f, 1.0f);
	//clampedNoise = SAMPLE_TEX2DLOD( water_tex_sampler, SamplerLinearWrap, float4((scrolledPos + planarOffset) * 0.3f, 0.0f, 0.0f)).a;
	//float addNoise = lerp(0.0f, (1.0f - leadingEdgeColor.a * 2.0f), frontIntensity);
	float addNoise = lerp(0.0f, (1.0f - leadingEdgeColor.a * 2.0f), frontIntensity);
	clampedNoise = clamp(clampedNoise + addNoise, 0.0f, 1.0f);
	//clampedNoise = 1.0f / (clampedNoise * clampedNoise + 1.0f);
	resIntensity = transparencyFade * (pow(clamp(1.0f - pow(clampedNoise, 1.0f) / threshold, 0.0f, 1.0f), lerp(1.0f, 0.2f, clampedIntensity)));



	float4 largeScaleNoise;
	largeScaleNoise.a = 0.6f * resIntensity;
	float3 trailColor = float3(1.0f, 1.0f, 1.0);
	//trailColor = SAMPLE_TEX2DLOD( water_tex_sampler, SamplerLinearWrap, float4((scrolledPos + planarOffset) * 0.1f, 0.0f, 0.0f)).rgb;
	largeScaleNoise.rgb = lerp(trailColor, leadingEdgeColor.rgb, 1.0f - pow(1.0f - frontIntensity, 3.0f));


	float4 smallScaleNoise;
	smallScaleNoise.rgb = float3(1.0f, 1.0f, 1.0f) * lerp(0.1f, 0.4f, clampedIntensity * 1.0f);
	smallScaleNoise.a = SafePow(clampedIntensity * (1.0f - pow(frontIntensity, 3.0f)), 1.3f) * 0.4f * (1.0f - shallowRatio);
	float4 resColor;
	resColor.rgba = lerp(smallScaleNoise.rgba, largeScaleNoise.rgba, clamp(largeScaleNoise.a + (1.0f - smallScaleNoise.a), 0.0f, 1.0f));

	return resColor;
}

float4 GetWaterColor(float scattering)
{
	float3 waterColor = pow(clamp(float3(0.1, 0.19, 0.22) + float3(0.8, 0.9, 0.6) * (scattering * 0.4f) * 1.5f * 1e2f, float3(0.0f, 0.0f, 0.0f), float3(1.0f, 1.0f, 1.0f)), 2.2f);
	return float4(waterColor.r, waterColor.g, waterColor.b, 0.0f); //add sand
}


Field GetOceanWaterHeight3(float2 planarPos, const float time)
{
	float freq = 0.16f;
	//float amp = 0.1f;
	float amp = 0.1f * 4.0f * 4.0f / 1.5f;
	//float spikiness = 4.0f;
	float spikiness = 2.0;

	float2 uv = planarPos * 8e-2f * 1.5f;
	//uv.x *= 0.75f;
	//uv.x *= 0.25f;

	float timePhase = 1.0f + time * 2.5f;

	//float octaveHeight = 0.0f;
	float totalHeight = 0.0f;
	float freq_mult = 1.9f * 1.6f;
	float time_mult = 0.5f;
	const int octavesCount = 3;//3;//DETAIL_LEVEL > 4 ? 4 : 3;

	//float2x2 octaveMatrix = float2x2(1.6f, 1.2f, -1.2f, 1.6f);
	//float2x2 octaveMatrix = float2x2(1.3f, 1.1f, -1.1f, 1.3f);
	//float ang = 0.3f;
	float ang = 0.2f;
	float2x2 octaveMatrix = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));

	Field resField;
	resField.value = 0.0f;
	resField.gradient = float2(0.0f, 0.0f);

	float2x2 phaseMatrix = float2x2(1.0f, 0.0f, 0.0f, 1.0f) * 8e-2f * 1.5f;
	float scrollSpeed = 1.25f;
	for(int i = 0; i < octavesCount; i++)
	{
		float2x2 octaveScale = float2x2(0.225f, 0.0f, 0.0f, 1.0f) * freq;
		float2x2 resOctaveMatrix = mul(phaseMatrix, octaveScale);
		Field octaveField =  GetOceanWaterOctave(mul(planarPos, resOctaveMatrix) - float2(timePhase * 0.5f, timePhase * 1.5f) * scrollSpeed * freq, spikiness);
		octaveField.value *= amp;
		octaveField.gradient = mul(octaveField.gradient, transpose(resOctaveMatrix)) * amp;
		resField.value += octaveField.value;
		resField.gradient += octaveField.gradient;

		phaseMatrix = mul(phaseMatrix, octaveMatrix);
		freq *= freq_mult;
		scrollSpeed /= sqrt(freq_mult);
		amp *= 0.25;
		spikiness = lerp(spikiness, 1.0f, 0.2f);
	}
	return FieldMulScalar(resField, 1.0f / 40e-2f);
}

struct ShorePhase
{
	float shoreDist;
	float oceanDist;
	float longitude;
	float intensity;
};

struct ShoreGradients
{
	float2 distGradient;
	float2 longitudeGradient;
};


WaveState GetTidalWaveState(float2 planarPos, ShorePhase shorePhase, ShoreGradients shoreGradients, float time, const bool computeHeightOnly)
{
	float2 travelDir = float2(1.0f, 0.0f);

	if(dot(shoreGradients.distGradient, shoreGradients.distGradient) > 0.0f)
		travelDir = normalize(shoreGradients.distGradient);

	float spatialMults[2];

	float pi = 3.1415f;

	float heightMult = 0.5e2f * 0.75f;
	float periodsCount = 25.0f;

	float tidePhase = 1.0f - frac(((1.0f - shorePhase.oceanDist) * periodsCount + time * 1.1f) / (2.0f * pi));

	/*tidePhases[0] = -planarPos.y * 1e-2f + time * 3.0f + 10.0f;
	tidePhases[1] = -planarPos.y * 1e-2f + time * 2.2f;*/
	//return abs(sin(tidePhase)) * heightMult;
	//float heightMult = (1.0f - pow(1.0f - distancePhase, 5.0f)) * (1.0f - pow(distancePhase, 5.0f)) * 0.3e2f;
	//float heightMult = pow(distancePhase, 10.1f) * pow(1.0f - distancePhase, 100.0f) * 1e2f * 0.01f;
	float resHeight = 0.0f;
	float2 resGradient = float2(0.0f, 0.0f);
	float4 foamColor = float4(0.0f, 1.0f, 0.0f, 0.0f);
	float2 turbulenceOffset = float2(0.0f, 0.0f);
	float foamRippleDampening = 0.0f;
	//for(int i = 0 ; i < 1; i ++)
	float3 noisePos;
	/*noisePos.xy = planarPos * 1e-3f + float2(10.0f, 10.0f) * i;
	noisePos.z = time * 0.1f;
	float spatialNoise = GetSmoothNoise3(noisePos) * 0.5f + 0.5f;*/
	//spatialNoise = 0.0f;

	float longitudeMult = 3e-3f;
	noisePos.x = shorePhase.longitude * longitudeMult + time * 0.1f;
	noisePos.y = time * 0.03f * 5.0f;
	Field spatialNoiseField = GetSmoothNoise(noisePos.xy);
	spatialNoiseField.value = spatialNoiseField.value * 0.5f + 0.5f;
	spatialNoiseField.gradient = spatialNoiseField.gradient * 0.5f;

	float spatialNoise = spatialNoiseField.value;

	noisePos.x = shorePhase.longitude * 1e-3f + 10.0f;
	noisePos.y = time * 0.02f;
	float phaseNoiseMult = 0.3f;
	float phaseNoise = spatialNoise * phaseNoiseMult;// + GetSmoothNoise(noisePos.xy).value * 0.5f + 0.5f;
	tidePhase = fmod(phaseNoise + tidePhase, 1.0f);

	float waveReduction = saturate(spatialNoise);//pow(clamp((spatialNoise - 0.01f) / 0.99f/* - phaseNoise * 0.3f*/, 0.0f, 1.0f), 1.0);
	float effectiveShoreDist = lerp(pow(clamp(1.0f - shorePhase.shoreDist, 0.0f, 1.0f), 1.0f + waveReduction * 2.5f), 0.0f, waveReduction * 0.4f) * shorePhase.intensity;

	float4 precomputedSample = SAMPLE_TEX2DLOD( wave_data_sampler, SamplerLinearWrapClampWrap, float4(tidePhase, effectiveShoreDist, 0.0f, 0.0f) );

	float octaveHeight = precomputedSample.r;

	resHeight += octaveHeight * heightMult;

	float trailFoamIntensity = saturate(precomputedSample.g);
	float frontFoamPhase = precomputedSample.a;


	bool leading_edge_area = ((tidePhase < 0.45f && frontFoamPhase < 1.0f) || (tidePhase > 0.55f && frontFoamPhase > 0.0f));

	foamRippleDampening = pow(trailFoamIntensity, 3.0f);
	foamRippleDampening *= leading_edge_area ? pow(saturate((0.8f - frontFoamPhase) / 0.8f * 2.0f), 2.0f) : 1.0f;

	float2 waveOffset = -travelDir * 20.1f / 0.5e-1f * (precomputedSample.b * 2.0f - 1.0f) * 1.0f;
	turbulenceOffset = waveOffset;

	[branch]
	if(!computeHeightOnly)
	{
		float constantFoamStart = 0.8f;
		float foamHeightMult = 0.05f;
		float distortionPhase = 1.0f - tidePhase;

		if(leading_edge_area && tidePhase < 0.45f)
		{
			distortionPhase = 0.0f;//lerp(distortionPhase, 0.0f, frontFoamPhase);
		}

		float periodColorLength = /*(1.0f / dist_to_color) * */(2.0f * pi) / periodsCount;
		float distGradientMult = 1.0f / periodColorLength;
			//float tidePhase = 1.0f - frac(((1.0f - shorePhase.oceanDist) * periodsCount + time * 1.1f) / (2.0f * pi));
		float2 phaseGradient = (-shoreGradients.distGradient/* / dist_to_color*/) * distGradientMult;

		float _spatialNoise = spatialNoiseField.value;
		float2 spatialNoiseGradient = -shoreGradients.longitudeGradient * spatialNoiseField.gradient.x * longitudeMult;

		//float phaseNoise = _spatialNoise * phaseNoiseMult;// + GetSmoothNoise(noisePos.xy).value * 0.5f + 0.5f;
		//tidePhase = fmod(phaseNoise + tidePhase, 1.0f);
		phaseGradient += spatialNoiseGradient * phaseNoiseMult;

		//float effectiveShoreDist = lerp(pow(clamp(1.0f - shorePhase.shoreDist, 0.0f, 1.0f), 1.0f + waveReduction * 2.5f), 0.0f, waveReduction * 0.4f) * shorePhase.intensity;
		float2 shoreDistGradient = float2(0.0f, 0.0f);


		float4 distortionPos;
		distortionPos.xy = (planarPos + waveOffset) * 0.002f;
		distortionPos.z = 0.0f;
		distortionPos.w = 0.0f;
		float4 distortionSample = SAMPLE_TEX2DLOD( distortion_sampler, SamplerLinearWrap, distortionPos) * 2.0f - float4(1.0f, 1.0f, 1.0f, 1.0f);
		//float4 distortionSample = SAMPLE_TEX2D( distortion_sampler, SamplerLinearWrap, distortionPos.xy) * 2.0f - float4(1.0f, 1.0f, 1.0f, 1.0f);
		float ang = distortionSample.b * 1.5f;
		float2x2 rotationMatrix = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));
		float2 rotationPoint = normalize(distortionSample.rg) * 1.0f;
		float2 rotationOffset = mul(rotationPoint, rotationMatrix) - rotationPoint;
		float2 translationOffset = distortionSample.rg * (2.0f + distortionPhase * 5.0f);
		float2 planarOffset = rotationOffset * 0.0f + translationOffset * 2.0f;

		float shallowRatio = clamp(1.0f - (shorePhase.shoreDist - 0.05f) * 3.0f, 0.0f, 1.0f);

		if(leading_edge_area)
		{
			//trailFoamIntensity = 1.0f;
		}
		else
			frontFoamPhase = 0.0f;

		float constantFoam = clamp((1.0f - shorePhase.shoreDist - constantFoamStart) / (1.0f - constantFoamStart) * 0.5f, 0.0f, 1.0f);
		foamColor = float4(1.0f, 0.0f, 0.0f, 0.0f);
		foamColor = GetFoamColor2(
			planarPos * 0.5e-1f,
			planarOffset + waveOffset * 0.5e-1f,
			travelDir,
			trailFoamIntensity,
			frontFoamPhase,
			constantFoam,
			shallowRatio,
			time);


		float4 gradientSample = SAMPLE_TEX2DLOD( wave_gradient_sampler, SamplerLinearWrapClampWrap, float4(tidePhase, effectiveShoreDist, 0.0f, 0.0f) );
		//resHeight += octaveHeight * heightMult;
		resGradient += gradientSample.r * phaseGradient * heightMult;
		resGradient += gradientSample.g * shoreDistGradient * heightMult;
	}
	//octaveHeight += clamp(foamColor.a * 1.0f, 0.0f, 1.0f) * foamHeightMult;
	//octaveHeight += clamp(foamColor.a * 1.0f, 0.0f, 1.0f) * foamHeightMult;

	WaveState res;
	res.heightField.value = resHeight;
	res.heightField.gradient = resGradient;
	res.foamColor = foamColor;
	//res.waterToTerrainRatio = clamp(1.0f - shorePhase.shoreDist * 5.1f - dot(turbulenceOffset, depthGradient) * 0.1f, 0.0f, 1.0f);
	res.waterToTerrainRatio = clamp(1.0f - (shorePhase.shoreDist - 0.03f) * 10.1f, 0.0f, 1.0f);
	res.foamRippleDampening = foamRippleDampening;


	/*float4 surface_pos;
	surface_pos.xy = planarPos / scene_size.xy;
	surface_pos.z = 0.0f;
	surface_pos.w = 0.0f;
	float4 debug_color = SAMPLE_TEX2DLOD( coastline_coord_tex_sampler, SamplerLinearWrap, surface_pos );
	float gray = frac(debug_color.b * 100.0f);
	res.foamColor = Uberblend(res.foamColor, float4(gray, gray, gray, 0.5f));*/
	/*float col = (shoreDist) / 0.05f;
	if(col < 0.0f || col > 1.0f) col = 0.0f;
	res.foamColor.rgba += float4(1.0f, 0.0f, 0.0f, 1.0f) * col;*/

	/*PHASE DEBUG*/
	float intensity = shorePhase.intensity;
	//res.foamColor.rgba += float4(0.0f, 1.0f, 0.0f, 0.5f) * frac(shorePhase.longitude / 100.0f) * intensity;
	//res.foamColor.rgba += float4(1.0f, 1.0f, 1.0f, 0.5f) * frac(shorePhase.intensity * 10.9f);
	//res.foamColor.rgba += float4(1.0f, 0.0f, 0.0f, 0.5f) * frac(shorePhase.shoreDist * 10.9f);
  //res.foamColor.rgba += float4(0.0f, 0.0f, 1.0f, 0.5f) * frac(shorePhase.oceanDist * 10.9f) * intensity;
	//res.foamColor.a = 0.5f;
	res.turbulenceOffset = turbulenceOffset;
	return res;
}

WaveState GetTotalWaveState(float2 planarPos, ShorePhase shorePhase, ShoreGradients shoreGradients, float time, const bool computeHeightOnly)
{
	WaveState resState = GetTidalWaveState(planarPos, shorePhase, shoreGradients, time, computeHeightOnly);

	resState.groundWaterRatio = 1.0f - saturate(1.0f + shorePhase.shoreDist * 10.0f);
	resState.heightField = FieldMulScalar(resState.heightField, 1.0 - resState.groundWaterRatio);
	resState.turbulenceOffset *= 1.0f - resState.groundWaterRatio;

	float shallowRippleMult = (1.0f - SafePow(1.0f - abs(shorePhase.shoreDist), 10.0f));
	float foamRippleMult = 1.0f - resState.foamRippleDampening;
	resState.heightField = FieldAdd(resState.heightField, FieldMulScalar(GetOceanWaterHeight3(planarPos + resState.turbulenceOffset, time), shallowRippleMult * foamRippleMult * 2.0f));
	//resState.foamColor.rgba = float4(resState.foamRippleDampening, 0.0f, 0.0f, 1.0f);
	//resState.height *= 5.0f;
	return resState;
}


ShorePhase GetShorePhase(float3 worldPos, float waterLevel)
{
	//return clamp((2000.0f - worldPos.y) / 1000.0f, 0.0f, 1.0f);
	/*float3 viewPos = (mul(float4(worldPos.x, worldPos.y, waterLevel, 1.0), view_matrix)).xyz;
	float2 screenPos = GetScreenPoint(viewPos);
	//return clamp(length(SAMPLE_TEX2DLOD( coastline_data_sampler, SamplerLinearWrap, float4(screenPos.xy, 0.0f, 0.0f) ).gb) / 2500.0f, 0.0f, 1.0f);
	float4 coast_sample = SAMPLE_TEX2DLOD( coastline_data_sampler, SamplerLinearWrap, float4(screenPos.xy, 0.0f, 0.0f) );
	ShorePhase res;
	res.dist = clamp(1.0f - coast_sample.g, 0.0f, 1.0f);
	res.longitude = coast_sample.b;
	return res;*/
	float4 surface_pos;
	surface_pos.xy = worldPos.xy / scene_size.xy + coord_tex_offset.xy;
	surface_pos.z = 0.0f;
	surface_pos.w = 0.0f;
	float4 phase_sample = SAMPLE_TEX2DLOD( coastline_coord_tex_sampler, SamplerLinearWrap, surface_pos);
	ShorePhase res;
	res.shoreDist = 1.0f - phase_sample.r;
	res.longitude = phase_sample.g * sum_longitude;
	res.oceanDist = phase_sample.b;
	res.intensity = phase_sample.a;
	return res;
}

WaveState GetTotalWaveStateWorld(float3 worldPos, float waterLevel, float time, const bool computeHeightOnly)
{
	ShorePhase shorePhase = GetShorePhase(worldPos, waterLevel);


	/*float3 cameraWorldPos = (mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0), inv_view_matrix)).xyz;
	float3 viewPos = (mul(float4(worldPos, 1.0), view_matrix)).xyz;
	float2 screenPoint = GetScreenPoint(viewPos);
	float opaqueDepth = FixDepth(SAMPLE_TEX2DLOD(opaque_data_sampler, SamplerPointClamp, float4(screenPoint.xy, 0.0f, 0.0f)).a);
	float3 worldBottomPoint = cameraWorldPos + normalize(worldPos - cameraWorldPos) * opaqueDepth;

	float gBufferDepth = worldBottomPoint.z - waterLevel;*/


	ShoreGradients shoreGradients;
	{
		//float3 centerOffset = float3(0.0f, 0.0f, shorePhase.shoreDist);
		float eps = 3e1f;

		ShorePhase xOffsetPhase = GetShorePhase(worldPos + float3(eps, 0.0f, 0.0f), waterLevel);
		ShorePhase yOffsetPhase = GetShorePhase(worldPos + float3(0.0f, eps, 0.0f), waterLevel);

		shoreGradients.distGradient = -(float2(xOffsetPhase.oceanDist - shorePhase.oceanDist, yOffsetPhase.oceanDist - shorePhase.oceanDist) / eps);
		shoreGradients.longitudeGradient = -(float2(xOffsetPhase.longitude - shorePhase.longitude, yOffsetPhase.longitude - shorePhase.longitude) / eps);

		/*float3 centerOffset = -float3(0.0f, 0.0f, shorePhase.oceanDist);
		float3 worldOffsets[2];
		worldOffsets[0] = float3(eps,  0.0f, 0.0f);
		worldOffsets[1] = float3(0.0f, eps,  0.0f);

		for(int i = 0; i < 2; i++)
		{
			float3 probeWorldPos = worldPos + worldOffsets[i];
			//worldOffsets[i].z = GetShorePhase(probeWorldPos, waterLevel).shoreDist;
			worldOffsets[i].z = -GetShorePhase(probeWorldPos, waterLevel).oceanDist;
		}*/
		//res.normal = normalize(cross(worldPos[1] - centerWorldPos, worldPos[0] - centerWorldPos));
		/*shoreGradients.distGradient = (float2(worldOffsets[0].z - centerOffset.z, worldOffsets[1].z - centerOffset.z) / eps);
		shoreGradients.lognitudeGradient = (float2(worldOffsets[0].z - centerOffset.z, worldOffsets[1].z - centerOffset.z) / eps);*/
		//tideDistGradient = dot(tideDistGradient, tideDistGradient) > 1e-7f ? normalize(tideDistGradient) : float2(1.0f, 0.0f);
	}
	//tideDistGradient = float2(1.0f, 0.0f);
	//tideDist = 0.0f;
	float2 planarPos = worldPos.xy;
	WaveState res = GetTotalWaveState(planarPos, shorePhase, shoreGradients, time, computeHeightOnly);
	///res.height += pow(saturate(1.0f - gBufferDepth / 3.0f), 2.0f) * 10.0f;
	return res;
}

WaterSurface GetTotalWaveSurfaceNumerical(float3 centerWorldPos, float3 cameraPos, const float time)
{
	float waterLevel = centerWorldPos.z;
	float3 intersectionPos = centerWorldPos;
	float3 initialPoint = centerWorldPos;
	float3 rayDir = normalize(centerWorldPos - cameraPos);
	WaterSurface res;

	float3 newIntersectionPos = intersectionPos;

	const int iterationsCount = 1 + DETAIL_LEVEL;

	for(int i = 0; i < iterationsCount; i++)
	{
		intersectionPos = newIntersectionPos;
		WaveState waveState = GetTotalWaveStateWorld(lerp(centerWorldPos, intersectionPos, 1.0f + 0.0f * float(i + 1) / float(iterationsCount)), waterLevel, time, i == iterationsCount - 1 ? false : true);
		res.waveState = waveState;

		float3 planePoint = centerWorldPos + float3(0.0f, 0.0f, -res.waveState.heightField.value);
		float3 planeNorm = float3(0.0f, 0.0f, 1.0f);
		//((o + dir * t) - p) * norm = 0
		//(rayOrigin - p) * norm + dir * norm * t = 0;
		float param = dot(planePoint - cameraPos, planeNorm) / dot(rayDir, planeNorm);

		newIntersectionPos = cameraPos + rayDir * param;
	}
	res.planarPos = newIntersectionPos.xy;
	/*float nearDist = 500.0;
	float farDist = 1000.0;
	float3 nearPoint = cameraPos + rayDir * nearDist;
	float nearErr = nearPoint.z +GetTotalWaveStateWorld(nearPoint, waterLevel, time, true, false).height;
	float3 farPoint = cameraPos + rayDir * farDist;
	float farErr = GetTotalWaveStateWorld(farPoint, waterLevel, time, true, false).height + farPoint.z;
	float midDist = 0.0;
	for(int i = 0; i < iterationsCount; i++)
	{
		float midDist = lerp(nearDist, farDist, nearErr / (nearErr - farErr));
		newIntersectionPos = cameraPos + rayDir * midDist;
		WaveState midState = GetTotalWaveStateWorld(newIntersectionPos, waterLevel, time, true, true);
		res.waveState = midState;
		res.planarPos = newIntersectionPos.xy;
		float midErr = midState.height + newIntersectionPos.z;
		if(midState.height < 0.0)
		{
			farDist = midDist;
			farErr = midErr;
		} else
		{
			nearDist = midDist;
			nearErr = midErr;
		}
	}
	intersectionPos = newIntersectionPos;*/

	float3 centerOffset = float3(0.0f, 0.0f, 0.0f);
	centerOffset.z -= res.waveState.heightField.value;
	//normal
	//[branch]
	/*if(numerical_normal > 0.5f)
	{
		float eps = 1e-0f;
		float3 worldOffsets[2];
		worldOffsets[0] = float3(eps,  0.0f, 0.0f);
		worldOffsets[1] = float3(0.0f, eps, 0.0f);

		float3 worldPos[2];
		for(int i = 0; i < 2; i++)
		{
			worldPos[i] = intersectionPos + worldOffsets[i];
			//worldPos[i].z -= GetTotalWaveHeightWorld(worldPos[i], time);
			worldOffsets[i].z -= GetTotalWaveStateWorld(worldPos[i], waterLevel, time, true, false).heightField.value;
		}
		//res.normal = normalize(cross(worldPos[1] - centerWorldPos, worldPos[0] - centerWorldPos));
		res.normal = normalize(cross(worldOffsets[1] - centerOffset, worldOffsets[0] - centerOffset));
	}else*/
	{
		float eps = 1e-1f;
		float3 gradientNorm = -cross(float3(eps, 0.0f, -res.waveState.heightField.gradient.x * eps), float3(0.0f, eps, -res.waveState.heightField.gradient.y * eps));

		res.normal = normalize(gradientNorm);
	}
	res.curvature = res.waveState.heightField.value * 5e-5f;
	return res;

	/*float3 xWorldPos[2] = centerWorldPos + float3(eps, 0.0f, 0.0f);
	float3 yWorldPos = centerWorldPos + float3(0.0f, eps, 0.0f);

	float3 centerViewPos = (mul(float4(centerWorldPos, 1.0), view_matrix)).xyz;
	float3 xViewPos = (mul(float4(xWorldPos, 1.0), view_matrix)).xyz;
	float3 yViewPos = (mul(float4(yWorldPos, 1.0), view_matrix)).xyz;

	float2 centerScreenPos = GetScreenPoint(centerViewPos);
	float2 xScreenPos = GetScreenPoint(xViewPos);
	float2 yScreenPos = GetScreenPoint(yViewPos);

	float centerWaterDepth = 1.0f - SAMPLE_TEX2DLOD( coastline_sampler, SamplerLinearWrap, float4(centerScreenPos.xy, 0.0f, 0.0f) ).g;
	float xWaterDepth = 1.0f - SAMPLE_TEX2DLOD( coastline_sampler, SamplerLinearWrap, float4(xScreenPos.xy, 0.0f, 0.0f) ).g;
	float yWaterDepth = 1.0f - SAMPLE_TEX2DLOD( coastline_sampler, SamplerLinearWrap, float4(yScreenPos.xy, 0.0f, 0.0f) ).g;

	float mult = 5e-2f;
	float2 centerPlanarPos = centerWorldPos.xy * mult;
	float2 xPlanarPos = xWorldPos.xy * mult;
	float2 yPlanarPos = yWorldPos.xy * mult;

	WaterSurface res;
	res.height = GetTidalHeight(centerPlanarPos, centerWaterDepth, time);
	centerWorldPos.z -= res.height;
	xWorldPos.z -= GetTidalHeight(xPlanarPos, xWaterDepth, time);
	yWorldPos.z -= GetTidalHeight(yPlanarPos, yWaterDepth, time);

	res.normal = normalize(cross(yWorldPos - centerWorldPos, xWorldPos - centerWorldPos));
	return res;*/
	/*WaterSurface res;
	res.height = centerWorldPos.z - worldPos[0].z;
	res.normal = normalize(cross(worldPos[2] - worldPos[1], worldPos[4] - worldPos[2]));
	res.curvature =
	return res;*/
}

float4 BuildReflection( PInput input ) : PIXEL_RETURN_SEMANTIC
{
	float2 viewport_size = float2(viewport_width, viewport_height);

	float2 tex_coord = input.screen_coord.xy / viewport_size;
	//float2 tex_coord = input.tex_coord;

	float4 framebuffer_color = SAMPLE_TEX2D( framebuffer_sampler, SamplerLinearWrap, tex_coord );

	float4 normal_sample = SAMPLE_TEX2DLOD( gbuffer_normals_sampler, SamplerLinearWrap, float4(tex_coord.xy, 0.0f, 0.0f) );
	float3 base_world_normal = normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f);
	base_world_normal = normalize(base_world_normal);
	//float3 base_world_normal = float3(0.0f, 0.0f, -1.0f);
	float3 world_normal = base_world_normal;


	float4 reflection_refraction_depth = SAMPLE_TEX2DLOD( gbuffer_reflections_sampler, SamplerLinearWrap, float4(tex_coord.x, tex_coord.y, 0.0f, 0.0f) );

	float surface_coef = reflection_refraction_depth.r;
	float surface_type = reflection_refraction_depth.g;

	bool has_reflection = false;
	bool has_refraction = false;

	int blend_type = 0; //0 is opaque, 1 is reflective, 2 is refractive


	float depth = FixDepth(reflection_refraction_depth.b);


	//float specular_amount = normal_specular.a;

	float3 view_pos = GetViewDir(tex_coord) * depth;
	//tex_coord = GetScreenPoint(view_pos);

	float3 view_dir = normalize(view_pos);

	float3 world_pos = (mul(float4(view_pos, 1.0), inv_view_matrix)).xyz;
	float3 cam_world_pos = (mul(float4(float3(0.0f, 0.0f, 0.0f), 1.0), inv_view_matrix)).xyz;

	float4 coastline_data = SAMPLE_TEX2DLOD( coastline_data_sampler, SamplerLinearWrap, float4(tex_coord.xy, 0.0f, 0.0f) );

	float4 opaque_color = SAMPLE_TEX2DLOD( opaque_data_sampler, SamplerPointClamp, float4(tex_coord.xy, 0.0f, 0.0f) );


	float4 refracted_color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 reflected_color = float4(0.0f, 0.0f, 0.0f, 0.0f);

	float3 surface_view_normal = (mul(float4(float3(0.0f, 0.0f, -1.0f), 0.0), view_matrix)).xyz;

	float4 medium_color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float medium_density = 5e-2f * 0.2f;
	float4 surface_color = opaque_color.rgba;//framebuffer_color.rgba;
	//float4 surface_color = framebuffer_color.rgba;


	float surface_opacity = 0.0f;

	float specular_ratio = 1.0f;
	float waterToTerrainRatio = 0.0f;
	float groundWaterRatio = 0.0f;
	[branch] if(surface_type > 0.99f) //is water
	{
		has_refraction = true;
		has_reflection = true;
		blend_type = 2;

		float3 lightColor = pow(ambient_light_color.rgb, 1.0f);
		WaterSurface resSurface = GetTotalWaveSurfaceNumerical(world_pos, cam_world_pos, current_time);
		float4 waterColor = GetWaterColor(resSurface.curvature) * float4(lightColor, 1.0f);

		float diffuseLightIntensity = clamp(-dot(ambient_light_dir.xyz, resSurface.normal), 0.0f, 1.0f) * 0.5f;
		float ambientLightIntensity = 0.5f;

		float4 foamColor = resSurface.waveState.foamColor *
			float4(lightColor * (diffuseLightIntensity + ambientLightIntensity), 1.0f);

		//waterToTerrainRatio = resSurface.waveState.waterToTerrainRatio;
		waterToTerrainRatio = saturate(1.0f - abs(opaque_color.a - depth) * 0.03f);
		groundWaterRatio = resSurface.waveState.groundWaterRatio;

		medium_density = lerp(medium_density, medium_density * 13.0f, groundWaterRatio);
		//medium_density = lerp(medium_density, 100.0f, groundWaterRatio);
		//waterColor.rgb = lerp(waterColor.rgb, pow(float3(98.0f, 81.0f, 38.0f) / 255.0f, 2.2f), groundWaterRatio);
		float3 def_light_color = float3(1.021f, 0.881f, 0.437f);
		//waterColor.rgb = lerp(waterColor.rgb, pow(float3(91.0f, 81.0f, 45.0f) / 255.0f, 2.2f) / def_light_color * ambient_light_color.rgb, saturate(groundWaterRatio * 20.0f));
		waterColor.rgb = lerp(waterColor.rgb, pow(float3(91.0f, 81.0f, 45.0f) / 255.0f, 2.2f) / def_light_color * ambient_light_color.rgb, saturate(groundWaterRatio * 20.0f));
		//waterColor.rgb = lerp(waterColor.rgb, pow(float3(91.0f, 81.0f, 45.0f) / 255.0f, 2.2f), saturate(groundWaterRatio * 20.0f));

		medium_color = waterColor;
		surface_color = foamColor;


		medium_color = ApplyResultFog(world_pos, cam_world_pos, cam_world_pos, medium_color);


		surface_color = ApplyResultFog(world_pos, cam_world_pos, cam_world_pos, surface_color);

		specular_ratio = (1.0f - foamColor.a);

		world_normal = resSurface.normal;
	}else
	{
		/*if(surface_coef > 1e-2f)
		{
			blend_type = 1;
			has_reflection = true;
			has_refraction = false;
		}*/
	}

	float3 view_normal = (mul(float4(world_normal, 0.0), view_matrix)).xyz;
	float3 reflected_view_dir = view_dir + view_normal * -dot(view_dir, view_normal) * 2.0f;


	/*float3 reflected_world_dir = (mul(float4(reflected_view_dir, 0.0), inv_view_matrix)).xyz;
	reflected_world_dir = min(0.0f, reflected_world_dir.z);
	reflected_world_dir = normalize(reflected_world_dir);
	reflected_view_dir = (mul(float4(reflected_world_dir, 0.0), view_matrix)).xyz;*/

	float3 base_view_normal = (mul(float4(base_world_normal, 0.0), view_matrix)).xyz;
	reflected_view_dir = reflected_view_dir + base_view_normal * max(0.0f, -dot(reflected_view_dir, base_view_normal));



	[branch] if(has_reflection)
	{
		RaytraceResult reflected_result;// = GetRaytracedLightScreenStepping(view_pos + reflected_view_dir * 5e-1f, reflected_view_dir);
		//if(dot(surface_view_normal, reflected_view_dir) < 0.0f)
		reflected_result.is_found = false;
		float reflected_medium_density = 0.0f;
		float3 reflected_medium_color = 0.0f;
		/*if(dot(view_dir, view_normal) > 0.0f)
		{
			reflected_medium_density = medium_density;
			reflected_medium_color = float3(1.0f, 0.0f, 0.0f);
		}*/
		reflected_color.rgb = BuildRaytraceLightResult(view_pos + reflected_view_dir * 5e-1f, reflected_view_dir, reflected_result, reflected_medium_density, reflected_medium_color, ambient_light_color.rgb, groundWaterRatio, true, false);
	}
	[branch] if(has_refraction)
	{
		float3 refracted_ray_dir = view_dir;

		float n1 = 1.0f;
		float n2 = 1.33f;

		float r = n1 / n2;
		float c = -dot(view_dir, view_normal);

		float tmp = 1.0f - r * r * (1.0f - c * c);
		if(tmp > 0.0f)
		{
			refracted_ray_dir = r * view_dir + (r * c - sqrt(tmp)) * view_normal;
		}

		RaytraceResult refracted_result = GetRaytracedLightViewStepping(view_pos, refracted_ray_dir);
		//RaytraceResult refracted_result = GetRaytracedLightCheap(view_pos, refracted_ray_dir);

		//if(dot(surface_view_normal, refracted_ray_dir) > 0.0f)
		//refracted_result.is_found = false;
		refracted_color.rgb = BuildRaytraceLightResult(view_pos, refracted_ray_dir, refracted_result, medium_density, medium_color.rgb, ambient_light_color.rgb, groundWaterRatio, false, true);
	}
	float4 res = float4(0.0f, 0.0f, 0.0f, 0.0f);
	if(blend_type == 0)
	{
		res.rgb = surface_color.rgb;
		res.a = 1.0f;

		//res.rgb += float3(0.0f, 0.0f, 0.2f);
	}
	if(blend_type == 1)
	{
		res.rgb = surface_color.rgb * (1.0f - surface_coef) + reflected_color.rgb * surface_coef;
		res.a = 1.0f;

		//res.rgb += float3(0.2f, 0.0f, 0.0f);
	}
	if(blend_type == 2)
	{

		float inner_refraction = 1.33f;//1.33f;
		float reflection_ratio = GetReflectionCoefficient(view_dir, view_normal, inner_refraction) * specular_ratio * (1.0f - waterToTerrainRatio);
		float3 inner_ray_color = surface_color.rgb * surface_color.a + refracted_color.rgb * (1.0f - surface_color.a);
		res.rgb = inner_ray_color.rgb * (1.0f - reflection_ratio) + reflected_color.rgb * reflection_ratio;
		//res.rgb = surface_color.rgb;
		//res.rgb += float3(1.0f, 0.0f, 0.0f) * abs(length(normal_sample.rgb * 2.0f - float3(1.0f, 1.0f, 1.0f)) - 1.0f) * 10.0f;
		res.a = 1.0f;
		//res.rgb = surface_color.rgb;
		//res.rgb += float3(0.0f, 0.2f, 0.0f);
	}

	//ShorePhase shorePhase = GetShorePhase(world_pos, 0.0f);
	/*PHASE DEBUG*/
	//float intensity = shorePhase.intensity * 0.3f;
	//res += float4(0.0f, 1.0f, 0.0f, 0.5f) * frac(shorePhase.longitude / 100.0f) * intensity;
	//res += float4(1.0f, 1.0f, 1.0f, 0.5f) * frac(shorePhase.intensity * 10.9f);
	//res += float4(1.0f, 0.0f, 0.0f, 0.5f) * frac(shorePhase.shoreDist * 10.9f);
  //res += float4(0.0f, 0.0f, 1.0f, 0.5f) * frac(shorePhase.oceanDist * 10.9f) * intensity;
	if(blend_type == 2)
	{
		//res += float4(0.2f, 0.0f, 0.0f, 0.0f);
	}
	//res.rgb += float3(0.2f, 0.0f, 0.0f) * frac(GetShorePhase(world_pos, 0.0f).shoreDist * 10.0f);
	//res.rgb = lerp(res.rgb, float3(1.0f, 1.0f, 1.0f) * frac(coastline_data.b / 200.0f), 0.5f);
	//res.rgb = lerp(res.rgb, float3(0.0f, frac(coastline_data.g/* - world_pos.xy*/ * 250.0f), 0.0f), 0.5f);
	//res.rgb = lerp(res.rgb, float3(0.0f, 0.0f, frac(coastline_data.b/* - world_pos.xy*/ / 25.0f)), 0.5f);
	//res = opaque_color;
	//res = framebuffer_color;
	return res;
	//float3 opaque_color = SAMPLE_TEX2D( opaque_data_sampler, SamplerPointClamp, tex_coord ).rgb;

	//float4 reflected_color = GetRaytracedLightViewStepping(view_pos + reflected_view_dir * 5e-1f, reflected_view_dir);

}


#define MOD2 float2(4.438975, 3.972973)

float Hash( float p )
{
	// https://www.shadertoy.com/view/4djSRW - Dave Hoskins
	float2 p2 = frac(float2(p, p) * MOD2);
	p2 += dot(p2.yx, p2.xy + 19.19);
	return frac(p2.x * p2.y);
	//return fract(sin(n)*43758.5453);
}

//------------------------------------------------------------------------
float2 Hash2(float2 planePoint)
{
	/*float t = fract(iGlobalTime*.0003);
	return texture2D(iChannel0, p*vec2(.135+t, .2325-t), -100.0).xy;*/


	float r = 523.0 * sin(dot(planePoint, float2(53.3158, 43.6143)));
	return float2(frac(15.32354 * r), frac(17.25865 * r));
}


float Hash3( float3 volumePoint )
{
	float h = dot(volumePoint, float3(127.1,311.7, 424.24));
	return frac(sin(h) * 43758.5453123);
}


Field GetSmoothNoise(float2 planarPoint)
{
	float2 intPoint = floor(planarPoint);
	float2 fractPoint = frac(planarPoint);

	float hasSeed = intPoint.x + intPoint.y * 57.0;

	float v00 = Hash(hasSeed +  0.0);
	float v01 = Hash(hasSeed +  1.0);
	float v10 = Hash(hasSeed + 57.0);
	float v11 = Hash(hasSeed + 58.0);

	float2 fractSquared = fractPoint * fractPoint;
	float2 fractCubic = fractSquared * fractPoint;

	//y = 3 * x * x - 2 * x * x -- smooth polynome 0..1 with zero derivatives
	float2 polynome = 3.0 * fractSquared - 2.0 * fractCubic;
	float2 derivatives = 6.0 * fractPoint - 6.0 * fractSquared;

	float u = polynome.x;
	float v = polynome.y;
	float du = derivatives.x;
	float dv = derivatives.y;

	/*
	v00 * (1.0f - polynome.x) * (1.0f - polynome.y) +
	v01 * polynome.x * (1.0f - polynome.y) +
	v10 * (1.0f - polynome.x) * polynome.y +
	v11 * polynome.x * polynome.y;

	p.x * p.y * (v00 -v01 - v10 + v11) +
	p.x * (v01 - v00) +
	p.y * (-v00 + v10) +
	v00

	//same for partial derivatives
	*/
	Field noise;
	/*noise.value =
		v00 * (1.0f - u) * (1.0f - v) +
		v01 *         u  * (1.0f - v) +
		v10 * (1.0f - u) *         v  +
		v11 *         u  *         v;
	noise.gradient.x =
		v00 * -du * (1.0f - v) +
		v01 *  du * (1.0f - v) +
		v10 * -du *         v  +
		v11 *  du *         v;
	noise.gradient.y =
		v00 * (1.0f - u) * -dv +
		v01 *         u  * -dv +
		v10 * (1.0f - u) *  dv +
		v11 *         u  *  dv;*/
	noise.value = (v00 + (v01-v00)*u +(v10-v00)*v + (v00-v01+v11-v10)*u*v) * 2.0f - 1.0f;
	noise.gradient.x = ((v01-v00)*du + (v00-v01+v11-v10)*du*v) * 2.0f;
	noise.gradient.y = ((v10-v00)*dv + (v00-v01+v11-v10)*u*dv) * 2.0f;
	/*float res = a + (b-a)*u +(c-a)*v + (a-b+d-c)*u*v;

	float dx = (b-a)*du + (a-b+d-c)*du*v;
	float dy = (c-a)*dv + (a-b+d-c)*u*dv;*/
	//return vec3(dx, dy, res);
	return noise;
}


float GetLinearNoise3( float3 volumePoint )
{
	float3 floorPoint = floor( volumePoint );
	float3 fractPoint = frac( volumePoint );

	float3 fractSquared = fractPoint * fractPoint;
	float3 fractCubic = fractSquared * fractPoint;

	//y = 3 * x * x - 2 * x * x -- smooth polynome 0..1 with zero derivatives
	//float3 polynome = 3.0 * fractSquared - 2.0 * fractCubic;
	float3 polynome = fractPoint;
	//float2 derivatives = 6.0 * fractPoint - 6.0 * fractSquared;

	return -1.0f + 2.0f *
		lerp
		(
			lerp
			(
				lerp( Hash3( floorPoint + float3(0.0f, 0.0f, 0.0f) ), Hash3( floorPoint + float3(1.0f, 0.0f, 0.0f) ), polynome.x),
				lerp( Hash3( floorPoint + float3(0.0f, 1.0f, 0.0f) ), Hash3( floorPoint + float3(1.0f, 1.0f, 0.0f) ), polynome.x),
				polynome.y
			),
			lerp
			(
				lerp( Hash3( floorPoint + float3(0.0f, 0.0f, 1.0f) ), Hash3( floorPoint + float3(1.0f, 0.0f, 1.0f) ), polynome.x),
				lerp( Hash3( floorPoint + float3(0.0f, 1.0f, 1.0f) ), Hash3( floorPoint + float3(1.0f, 1.0f, 1.0f) ), polynome.x),
				polynome.y
			),
			polynome.z
		);
}

float GetSmoothNoise3( float3 volumePoint )
{
	float3 floorPoint = floor( volumePoint );
	float3 fractPoint = frac( volumePoint );

	float3 fractSquared = fractPoint * fractPoint;
	float3 fractCubic = fractSquared * fractPoint;

	//y = 3 * x * x - 2 * x * x -- smooth polynome 0..1 with zero derivatives
	float3 polynome = 3.0 * fractSquared - 2.0 * fractCubic;
	//float3 polynome = fractPoint;
	//float2 derivatives = 6.0 * fractPoint - 6.0 * fractSquared;

	return -1.0f + 2.0f *
		lerp
		(
			lerp
			(
				lerp( Hash3( floorPoint + float3(0.0f, 0.0f, 0.0f) ), Hash3( floorPoint + float3(1.0f, 0.0f, 0.0f) ), polynome.x),
				lerp( Hash3( floorPoint + float3(0.0f, 1.0f, 0.0f) ), Hash3( floorPoint + float3(1.0f, 1.0f, 0.0f) ), polynome.x),
				polynome.y
			),
			lerp
			(
				lerp( Hash3( floorPoint + float3(0.0f, 0.0f, 1.0f) ), Hash3( floorPoint + float3(1.0f, 0.0f, 1.0f) ), polynome.x),
				lerp( Hash3( floorPoint + float3(0.0f, 1.0f, 1.0f) ), Hash3( floorPoint + float3(1.0f, 1.0f, 1.0f) ), polynome.x),
				polynome.y
			),
			polynome.z
		);
}

float GetVoronoiNoise( float2 planePoint )
{
	float minDist0 = 1.0e2f;
	float minDist1 = 1.0e2f;
	for (int x = -1; x <= 1; x++)
	{
		for (int y = -1; y <= 1; y++)
		{
			float2 gridPoint = floor(planePoint) + float2(x, y);
			float2 offsetPoint = planePoint - gridPoint - float2(0.5, 0.5) * 2.0f + Hash2(gridPoint);
			float currDist = dot(offsetPoint, offsetPoint);
			if(minDist0 > currDist)
			{
				minDist1 = minDist0;
				minDist0 = currDist;
			}else
			if(minDist1 > currDist)
			{
				minDist1 = currDist;
			}
		}
	}
	return abs(sqrt(minDist0) - sqrt(minDist1));
	//return 1.0f - sqrt(minDist0) * 1.7f;
}
