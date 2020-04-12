TEXTURE2D_DECL( life_globe_layer_sampler );
TEXTURE2D_DECL( life_globe_normal_sampler );
TEXTURE2D_DECL( turbulence_sampler );

struct Intersection
{
	bool exists;
	float min_scale;
	float max_scale;
};

Intersection GetRaySphereIntersection(float3 ray_origin, float3 ray_dir, float3 sphere_pos, float3 sphere_radius)
{
	Intersection res;

	float a = dot(ray_dir, ray_dir);
	float3 delta = ray_origin - sphere_pos;
	float b = 2.0f * dot(delta, ray_dir);
	float c = dot(sphere_pos, sphere_pos) + dot(ray_origin, ray_origin) - 2.0f * dot(ray_origin, sphere_pos) - sphere_radius * sphere_radius;
	float disc = b * b - 4.0f * a * c;
	if (disc > 0.0f)
	{
		float sqrt_disc = sqrt(disc);

		res.min_scale = (-b - sqrt_disc) / (2.0f * a);
		res.max_scale = (-b + sqrt_disc) / (2.0f * a);
		res.exists = true;
	}
	else
	{
		res.exists = false;
	}
	return res;
}

float2 GetSphereSurfaceUv(float2 planar_pos, float radius)
{
	float2 dir = planar_pos;
	float dist = length(dir) / radius;
	float sin_ang = clamp(dist, 0.0f, 1.0f);
	float ang = asin(sin_ang);
	return normalize(dir) * ang / (3.1415f * 0.5f);
}

float3 GetFullViewSpherePos(float radius, float fov)
{
	float t = radius / fov * 2.0f;
	return float3(0.0f, 0.0f, sqrt(radius * radius + t * t));
}

float3 GetViewRayDir(float2 planar_pos, float2 fov)
{
	return float3(planar_pos.x * fov.x, planar_pos.y * fov.y, 1.0f);
}

float2 GetSphereUv(float3 sphere_delta)
{
	float2 uv;
	uv.x = atan2(sphere_delta.z, sphere_delta.x);
	uv.y = atan2(sphere_delta.y, length(sphere_delta.xz));	
	return uv;
}

float3x3 GetSphereTBN(float3 sphere_delta)
{
	float3x3 tbn;
	tbn[0] = normalize(cross(float3(0.0f, 1.0f, 0.0f), sphere_delta));
	tbn[2] = normalize(sphere_delta);
	tbn[1] = cross(tbn[0], tbn[2]);
	return tbn;
}

float4 GetSurfaceLight(float3 view_dir, float3 surface_normal, float glossiness, float3 specular_color)
{
	float3 reflected_dir = view_dir - 2.0f * surface_normal * dot(view_dir, surface_normal);
	float3x3 vert_flip = float3x3(
		1.0f, 0.0f, 0.0f,
		0.0f, -1.0f, 0.0f,
		0.0f, 0.0f, 1.0f);
	float3x3 env_transform = mul(GetCubemapTransform(1.5f, 0.2f), vert_flip);
	float4 prefiltered_light = GetGGXPrefilteredLight(view_dir, surface_normal, glossiness, specular_color, specular_cube, env_transform);
	float3 specular_light = 0.0f;
	specular_light += prefiltered_light.rgb * 0.1f;
	//specular_light.rgb *= 0.0f;
	//specular_light += GGXSpecular(normalize(float3(1.0f, -1.0f, -1.0f)), surface_normal, view_dir, glossiness, specular_color) * 10.3f;
	return float4(specular_light, prefiltered_light.a);
}

float4 GetResourceOrbColor(float2 uv_coord)
{
	float4 res_color = 0.0f;
	float mults[4] = {0.65f, 0.6f, 0.8f, 1.5f};
	//float outer_radii[4] = {0.5f, 0.5f, 0.5f, 0.1f};
	//float fade_radii[4] = {0.03f, 0.03f, 0.02f, 0.1f};
	float2 color_scrolls[4] = {float2(-0.12f, 0.0f), float2(-0.24f, 0.08f), float2(-0.28f, 0.12f), float2(-0.1f, 0.1f)};
	//float2 turbulence_scrolls[4] = {float2(0.00f, 0.05f), float2(0.05f, 0.00f), float2(0.08f, 0.03f), float2(0.1f, 0.1f)};
	float2 smoothsteps[4] = {float2(0.9f, 0.55f), float2(0.9f, 0.5f), float2(0.001f, 0.3f), float2(0.1f, 0.9f)};

	float2 fov = 1.0f;
	
	float2 uv_delta = (uv_coord - float2(0.5f, 0.5f));
	float3 ray_origin = 0.0f;
	float3 ray_dir = GetViewRayDir(uv_delta, fov);

	float sphere_radius = 0.3f;
	float3 sphere_pos = GetFullViewSpherePos(sphere_radius, fov.x);
	
	Intersection inter = GetRaySphereIntersection(ray_origin, ray_dir, sphere_pos, sphere_radius);
	if(!inter.exists) return 0.0f;
	
	
	float3 hit_point = ray_origin + ray_dir * inter.min_scale;
	float3 sphere_delta = hit_point - sphere_pos;
	float2 hit_uv = GetSphereUv(sphere_delta);
	float3x3 tbn_basis = GetSphereTBN(sphere_delta);

  //float3 color = VibranceEx(uv_coord.y, float3(1.0f, 1.0f, 1.0f), 1.0f, 1.0f);// Vibrance(layer_sample.r, float3(1.0f, 0.0f, 0.0f));
  //float3 color = Vibrance(layer_sample.r * 1.5f, float3(1.0f, 0.0f, 0.0f));
	float4 background;
	
	background.rgb = (Checkerboard(uv_coord * 50.0f) * 0.2f + 0.8f) * 0.0f;
	background.a = 1.0f;
	float4 res = 0.0f;

	float surface_diff = uv_coord.y - (sin(time) * 0.5f * 0.0f + 0.5f);
	float vert_velocity_mult = 1.0f - pow(saturate(1.0f - surface_diff * 5.0f), 2.0f);

	float ripple_height = 0.0f;
	for(int i = 0; i < 3; i++)
	{
		float2 delta = (uv_coord - float2(0.5f, 0.5f));
		//float2 sphere_uv = uv_coord;//GetSphereSurfaceUv(delta, outer_radius) * 0.8f * float2(0.5f, 1.0f) + float2(0.0f, 0.5f);
		float2 sphere_uv = hit_uv * 0.8f * float2(0.5f, 1.0f) + float2(0.0f, 0.5f);
		
		
		float layer_index = i;
		
		//float mip_level = log(res.a * 500.0f + 1.0f);
		float mip_level = res.a * 10.6f;
		float2 scrolled_uv = sphere_uv + color_scrolls[i] * 0.3f * time;
		float4 flow_sample = SAMPLE_TEX2D(turbulence_sampler, SamplerLinearWrap, scrolled_uv);
		float2 flow_vec = (flow_sample.rg - 0.5f) / 3.0f * 2.0f;// + color_scrolls[i] * 6.0f;
		flow_vec.y *= 0.5f + 0.5f * vert_velocity_mult;
		float flow_phase = time * 0.5f + flow_sample.r * 0.3f;
		
		float4 layer_sample = GetEvolvingTex(scrolled_uv, flow_vec, mip_level, flow_phase, life_globe_layer_sampler);//SAMPLE_TEX2DLOD(life_globe_layer_sampler, SamplerLinearWrap, float4(sphere_uv/* * float2(0.5f, 1.0f)*/ + color_scrolls[i] * time * 2.0f + flow_offset, 0.0f, mip_level));
		float layer_density = layer_sample[layer_index];//;//pow(layer_sample[layer_index], 1.0f / 5.0f);
		//layer_density = (layer_index == 1) ? saturate((layer_density - 0.4f) * 2.0f) : layer_density;
		/*float4 layer_color = float4(Vibrance(pow(layer_density, 0.3f) * mults[layer_index], float3(1.0f, 0.0f, 0.0f)) , saturate(layer_density));
		layer_color.a = saturate((pow(layer_density, 0.1f) - 0.3f) / 0.7f);*/
		float4 layer_color = float4(Vibrance(SmoothStep(layer_sample[layer_index], smoothsteps[i].x, smoothsteps[i].y) * mults[layer_index], float3(1.0f, 0.0f, 0.0f)) , saturate(layer_density));
		//layer_color *= 1.0f- pow(1.0f - NoV, 2.0f);
		//layer_color.a = SmoothStep(layer_density, smoothsteps[i].x, smoothsteps[i].y);
		//float fade = GetSphereFade(delta, inner_radius, outer_radius);
		//layer_color *= 1.0f - pow(1.0f - fade, 1.0f);
		//layer_color.a = 1;
		//layer_color.rgb = Checkerboard((sphere_uv * float2(0.6f, 1.0f) * 10.0f + color_scrolls[i] * time * 1.0f) * 3.0f);
		/*layer_color.a = 1.0f;
		float path_length = GetSpherePath(outer_planar_pos) * outer_radius - GetSpherePath(inner_planar_pos) * inner_radius;
		layer_color *= 1.0f - exp(-layer_density * path_length * 50.0f);*/
		//res = OverlayPremult(res, layer_color);
		if(i == 0)
		{
			//ripple_height += flow_offset.y * -0.1f;
			//ripple_height += flow_offset.y * -0.1f;
			//ripple_height += (layer_density - 0.5f) * 0.1f;
			ripple_height += (GetEvolvingTex(scrolled_uv, flow_vec, 4.0f, flow_phase, life_globe_layer_sampler)[layer_index] - 0.5f) * 0.1f;
		}
		res = OverlayPremult(layer_color, res);
		//res = vert_velocity_mult;
	}
	res = OverlayPremult(background, res);
	res = lerp(res, float4(0.9f, 0.02f, 0.01f, 1.0f), 0.4f);

	for(int i = 0; i < 0; i++)
	{
		float3 hash = hash33(float3(i + 13.0f, 0.0f, 0.0f));
		float wavelength = (hash.x - 0.5f) * 3.0f;
		float amp = wavelength * (0.5f + 0.5f * hash.y) * 0.01f;
		float speed = sqrt(abs(wavelength)) * (wavelength > 0.0f ? 1.0f : -1.0f) * 0.3f;
		for(int j = 0; j < 2; j++)
		{
			ripple_height += sin(2.0f * 3.1415f * (uv_coord.x + speed * time * (j == 0 ? 1.0f : -1.0f)) / wavelength) * amp;
		}
	}
	//res *= 1.0f - pow(1.0f - saturate((surface_diff + ripple_height) * 50.0f + 1.0f), 2.0f);
	res *= pow(saturate((surface_diff + ripple_height) * 30.0f + 1.0f), 2.0f);
	float NoV = saturate(-dot(tbn_basis[2], ray_dir));
	res.rgb *= 0.1f + 0.9f * pow(NoV, 1.5f);
	float4 inner_light = float4(pow(res.rgb, 2.2f), res.a);
	
	//float4 normal_sample  = SAMPLE_TEX2D(life_globe_normal_sampler, SamplerLinearWrap, hit_uv * 0.5f + float2(-0.35f, 0.0f));
	float4 normal_sample  = SAMPLE_TEX2DLOD(life_globe_normal_sampler, SamplerLinearWrap, float4(hit_uv * 0.5f + float2(-0.35f, 0.0f), 0.0f, 0.0f));
	
	float3 tbn_normal;
	tbn_normal.xy = (normal_sample.rg - 0.5f) * 2.0f;
	tbn_normal.z = sqrt(1.0f - dot(tbn_normal.xy, tbn_normal.xy));
	//tbn_normal.xyz = (normal_sample.rgb - 0.5f) * 2.0f;
	float glossines = normal_sample.a;
	float3 view_normal = mul(tbn_normal, tbn_basis);
	
	float4 surface_light = GetSurfaceLight(normalize(ray_dir), normalize(view_normal), pow(glossines, 1.0f), 0.04f);
	//return GetOrbSurfaceColor(uv_coord).a;
	return OverlayPremult(inner_light, surface_light);// + 1.0f - surface_light.a;//OverlayPremult(background, layer0);//OverlayPremult(background, OverlayPremult(layer1, layer0));
	//return float4(float4(0.05f, 0.0f, 0.0f, 1.0f).rgb * (1.0f - surface_light.a) + surface_light.rgb, 1.0f);// + 1.0f - surface_light.a;//OverlayPremult(background, layer0);//OverlayPremult(background, OverlayPremult(layer1, layer0));
}
