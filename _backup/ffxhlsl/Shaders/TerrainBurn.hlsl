//PRECOMPILE ps_4_0 ComputeBurnIntensity
//PRECOMPILE ps_gnm ComputeBurnIntensity
//PRECOMPILE ps_vkn ComputeBurnIntensity

#define MAX_SOURCES_COUNT 10
CBUFFER_BEGIN( cterrain_burn )
	float4 tex_size;
	float4 scene_size;
	float4 fire_sources_data[MAX_SOURCES_COUNT];
	float time_step;
	float reset_data;
	int fire_sources_count;
CBUFFER_END

TEXTURE2D_DECL( prev_burn_sampler );

struct PS_INPUT
{
	float4 pixel_coord : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
};

float2 ComputeWind(float2 tex_pos, float2 prev_wind)
{
	float4 xp_sample = SAMPLE_TEX2D(prev_burn_sampler, SamplerLinearClamp, tex_pos + float2( 1.0f, 0.0f) / tex_size.xy);
	float4 xm_sample = SAMPLE_TEX2D(prev_burn_sampler, SamplerLinearClamp, tex_pos + float2(-1.0f, 0.0f) / tex_size.xy);
	float4 yp_sample = SAMPLE_TEX2D(prev_burn_sampler, SamplerLinearClamp, tex_pos + float2(0.0f,  1.0f) / tex_size.xy);
	float4 ym_sample = SAMPLE_TEX2D(prev_burn_sampler, SamplerLinearClamp, tex_pos + float2(0.0f, -1.0f) / tex_size.xy);
	float2 step_size = scene_size.xy / tex_size.xy;
	
	float2 new_wind = float2(abs(xp_sample.r) - abs(xm_sample.r), abs(yp_sample.r) - abs(ym_sample.r)) / (2.0f * step_size) * 5000.0f; //5000.0f is for using f16 range better
	return lerp(new_wind, prev_wind, exp(-time_step * 5.0f));	
}

float2 ComputeBurn(float2 tex_pos, float2 prev_burn)
{
	float2 world_pos = (tex_pos - float2(0.5f, 0.5f) / tex_size.xy) * scene_size.xy;

	float intensity = 0.0f;
	for(int source_index = 0; source_index < fire_sources_count; source_index++)
	{
		float4 data_entry = fire_sources_data[source_index];
		float2 source_pos = data_entry.xy;
		float source_size = data_entry.z;
		float source_intensity = data_entry.w;
		float norm_dist = length(source_pos - world_pos.xy) / (source_size + 1e-5f);
		intensity += lerp(source_intensity, 0.0f, saturate(norm_dist));
	}
	float new_burn_intensity = prev_burn.r * exp(-0.5f * time_step) + intensity;
	float new_burn_progress = prev_burn.g + abs(new_burn_intensity) * time_step;	
	return float2(new_burn_intensity, new_burn_progress);
}

float4 ComputeBurnIntensity( const PS_INPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float2 tex_pos = input.pixel_coord.xy / tex_size.xy;

	float4 prev_burn_sample = SAMPLE_TEX2D(prev_burn_sampler, SamplerLinearWrap, tex_pos);

	float4 new_burn_sample = float4(ComputeBurn(tex_pos, prev_burn_sample.xy), ComputeWind(tex_pos, prev_burn_sample.zw));
	return reset_data > 0.5f ? float4(0.0f, 0.0f, 0.0f, 0.0f) : new_burn_sample;
}