//PRECOMPILE ps_4_0 RenderWalkability
//PRECOMPILE ps_4_0 RenderTiles
//PRECOMPILE ps_gnm RenderWalkability
//PRECOMPILE ps_gnm RenderTiles
//PRECOMPILE ps_vkn RenderWalkability
//PRECOMPILE ps_vkn RenderTiles

CBUFFER_BEGIN( cminimap_vertex_transform )
	float4 x_basis;
	float4 y_basis;
	float4 z_basis;
	float4 tiles_count;
	float tile_world_size;

	float4 render_circle;
	
	float4 decay_map_minmax;
	float4 decay_map_size;
	float4 stabiliser_position;
	float decay_map_time;
	float creation_time;
	float global_stability;
	
	float alpha_override;
CBUFFER_END

TEXTURE2D_DECL( tilemap_sampler );

TEXTURE2D_DECL( walkability_sampler );
TEXTURE2D_DECL( visibility_sampler );
TEXTURE2D_DECL( decay_map_sampler );
TEXTURE2D_DECL( stable_map_sampler );
TEXTURE2D_DECL( crack_sampler );

struct PS_INPUT
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD1;
	float4 untransformed_pos : TEXCOORD2;
};

float2x2 inverse(in float2x2 m)
{
	float2x2 cof = { m[1][1], -m[0][1], -m[1][0], m[0][0] };
	return cof / determinant(transpose(m));
}

float4 Uberblend(float4 col0, float4 col1)
{
	/*return float4(
    (1.0 - col0.a) * (1.0 - col1.a) * (col0.rgb * col0.a + col1.rgb * col1.a) / (col0.a + col1.a + 1e-2f) +
    (1.0 - col0.a) * (0.0 + col1.a) * (col1.rgb) +
    (0.0 + col0.a) * (1.0 - col1.a) * (col0.rgb * (1.0 - col1.a) + col1.rgb * col1.a) +
    (0.0 + col0.a) * (0.0 + col1.a) * (col1.rgb),
    min(1.0, 1.0f - (1.0f - col0.a) * (1.0f - col1.a)));*/
	return float4(
		lerp(
    	lerp((col0.rgb * col0.a + col1.rgb * col1.a) / (col0.a + col1.a + 1e-2f), (col1.rgb), col1.a),
    	lerp((col0.rgb * (1.0 - col1.a) + col1.rgb * col1.a), (col1.rgb), col1.a),
		col0.a),
    min(1.0, 1.0f - (1.0f - col0.a) * (1.0f - col1.a)));
}


float4 ReadWalkabilitySample(float4 untransformed_pos)
{
	float2 planar_pos = untransformed_pos.xy;
	float2 map_coord = planar_pos / tiles_count.xy;
	map_coord.x = map_coord.x;
	map_coord.y = map_coord.y;	
	return lerp(float4(0.0f, 1.0f, 0.0f, 1.0f), float4(1.0f, 0.0f, 0.0f, 1.0f), SAMPLE_TEX2D( walkability_sampler, SamplerLinearClamp, frac(map_coord) ).r);
}

float GetGlobalDecayTime()
{
	//return fmod(time, 5.0f) * 1.0f + 28.0f;
	return decay_map_time;
}

struct DecayField
{
	float stability;
	float decay_time;
	float3 gradient;
	float curvature;
	float temp_mult;
	float glow_mult;
};

DecayField GetDecayField(float3 world_pos)
{
	float2 uv_pos = (world_pos.xy - decay_map_minmax.xy) / (decay_map_minmax.zw - decay_map_minmax.xy + 1e-5f);
	float4 decay_sample = SAMPLE_TEX2DLOD(decay_map_sampler, SamplerLinearClamp, float4(uv_pos, 0.0f, 0.0f));
	DecayField decay_field;
	float start_time = decay_sample.x;
	float decay_time = GetGlobalDecayTime() - start_time;
	float stability = SAMPLE_TEX2DLOD(stable_map_sampler, SamplerLinearClamp, float4(uv_pos, 0.0f, 0.0f)).x;

	float2 step_size = (decay_map_minmax.zw - decay_map_minmax.xy) / decay_map_size.xy;
	decay_field.gradient = float3(decay_sample.yz / step_size, 0.0f);

	decay_field.stability = stability;

	decay_field.temp_mult = 0.3f + 0.7f / (0.9f + 5.0f * length(decay_field.gradient));
	decay_field.temp_mult = lerp(decay_field.temp_mult, 0.5f, global_stability);
	{
		float stability_wave = (1.0f - (length(world_pos - stabiliser_position.xyz) - 300.0f - pow(max(0.0f, creation_time), 2.0f) * 1000.0f) * 0.0005f);
		//non-constant width
		//decay_time = max(decay_time, 50.0f - stability_wave * 50.0f);
		//constant width
		float transition_len = 1.0f / 70.0f;
		decay_time = max(decay_time / (length(decay_field.gradient) + 1e-4f) * transition_len + 1.0f, 50.0f - stability_wave * 50.0f);
		decay_field.gradient *= 1.0f / (length(decay_field.gradient) + 1e-4f) * transition_len;
	}
		
	decay_field.curvature = decay_sample.w / (step_size.x);

	decay_field.glow_mult = saturate(start_time + 8.0f);
	decay_field.decay_time = decay_time;
 
	return decay_field;
}

float ReadDecayRatio(float4 untransformed_pos)
{
	float2 world_planar_pos = untransformed_pos.xy * tile_world_size;
	DecayField decay_field = GetDecayField(float3(world_planar_pos, 0.0f));
	return (GetGlobalDecayTime() > 0.0f) ? ((decay_field.decay_time) * 0.2f) : 0.0f;
}

float GetCheckerboardPattern(float4 untransformed_pos)
{
	float2 world_planar_pos = untransformed_pos.xy * tile_world_size;
	float pattern = 1.0f;
	pattern *= abs(frac((world_planar_pos.x + world_planar_pos.y * 1.0f) / 50.0) - 0.5f) * 2.0f;
	pattern *= abs(frac((world_planar_pos.x - world_planar_pos.y * 1.0f) / 50.0) - 0.5f) * 2.0f;
	pattern *= 2.0f;

	return pattern;
}

float GetCrackPattern(float4 untransformed_pos)
{
	float2 world_planar_pos = untransformed_pos.xy * tile_world_size;
	
	return pow(saturate(SAMPLE_TEX2D( crack_sampler, SamplerLinearWrap, world_planar_pos.xy * 0.5e-3f ).b * 1.2f), 4.0f);

}

float4 ReadVisibilitySample(float4 untransformed_pos)
{
	float2 planar_pos = untransformed_pos.xy;
	float2 map_coord = planar_pos / tiles_count.xy;
	map_coord.x = map_coord.x;
	map_coord.y = map_coord.y;	
	return SAMPLE_TEX2D( visibility_sampler, SamplerLinearClamp, frac(map_coord) );
}

float4 RenderWalkability( const PS_INPUT input ) : PIXEL_RETURN_SEMANTIC
{
	//return float4(frac(input.untransformed_pos.xy / 10.0f),  0.0f, 0.1f);
	//texcolour = lerp(texcolour, float4(walkability_sample.rgb, 1.0f), 0.5f);//float4(input.untransformed_pos.xy / 1000.0f, 0.0f, 1.0f);
	float dist = distance( input.pos.xy, render_circle.xy );
	if( dist > render_circle.z )
		discard;

	float4 walkability_sample = ReadWalkabilitySample(input.untransformed_pos);

	float walkable_dist = walkability_sample.r;
	float visibility = ReadVisibilitySample(input.untransformed_pos).x;
	float decay = ReadDecayRatio(input.untransformed_pos);
	//float checkerboard = GetCheckerboardPattern(input.untransformed_pos);
	float crack_pattern = GetCrackPattern(input.untransformed_pos);


	//if(walkable_dist > 0.999f) discard;
	

	return float4(walkable_dist, visibility, decay, crack_pattern);
	//return float4(walkable_dist, visibility, frac(input.untransformed_pos.z * 1.1f), 1.0f) * 1e-3f + lerp(float4(1.0f, 0.0f, 0.0f, 0.5f), float4(0.0f, 1.0f, 0.0f, 0.5f), frac(input.untransformed_pos.z * 1.0f));//float4(walkable_dist, visibility, frac(input.untransformed_pos.z * 1.1f), 1.0f);
}

float4 RenderTiles( const PS_INPUT input ) : PIXEL_RETURN_SEMANTIC
{
	//return float4(frac(input.untransformed_pos.xy / 10.0f),  0.0f, 0.1f);
	float dist = length( input.pos.xy - render_circle.xy );
	if( dist > render_circle.z)
		discard;

	float4 texcolour = SAMPLE_TEX2D( tilemap_sampler, SamplerLinearClamp, input.texture_uv );
	//texcolour.rgb /= 0.5f;
	//texcolour.a /= 0.5f;
	//texcolour.a = 0.5;
	if(length(texcolour.rgb) < 1e-3f && texcolour.a > 2e-1) //no lerp for color key
	{
		texcolour.a = 1.0;
		texcolour.rgb = float3(0.0f, 0.0f, 0.0f);
	}
	texcolour.rgb = saturate(texcolour.rgb / (texcolour.a + 1e-5));
	//texcolour.a *= 0.9f;
	//texcolour.a = 0.5f;

	float color = texcolour.r + texcolour.g + texcolour.b;
	color = (color < -1.0000) ? 0.0 : 1.0;
	//texcolour.a *= alpha;
	//texcolour.a *= color;
	/*texcolour.rgb = float3(0.0f, 1.0f, 0.0f);
	texcolour.a += 0.5f;*/
	
	texcolour.a *= alpha_override;
	return texcolour;
}