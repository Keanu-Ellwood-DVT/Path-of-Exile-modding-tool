float Luminance(float3 color)
{
	return dot(float3(0.299, 0.587, 0.114), color);
}

float3 Vibrance(float val, float3 color)
{
	// "+ 1e-5" is a workaround for xbox issue
	// https://redmine.office.grindinggear.com/issues/93564
	// pow() function didn't work correctly when a component was equal to 0.25 so need to make an offset
	return pow(saturate(3.0f * val * val - 2.0f * val * val * val), 1.0f / (color + 1e-5));
}

float3 VibranceEx(float val, float3 color, float brightness, float contrast)
{
	return Vibrance(val, color);
}

float4 OverlayPremult(float4 col0, float4 col1)
{
	return float4(col0.rgb * (1.0f - col1.a) + col1.rgb, col0.a * (1.0f - col1.a) + col1.a);
}

float Checkerboard(float2 uv)
{
	return ((frac(uv.x) > 0.5f ? 1 : 0) + (frac(uv.y) > 0.5f ? 1 : 0)) == 1 ? 1.0f : 0.0f;
}

float4 SetBrightness( float4 base_colour, float brightness )
{
	float4 added_brightness = float4( brightness, brightness, brightness, 1 ) * base_colour.a;
	return base_colour * added_brightness;
}

float4 GetGreyscale( float4 base_colour )
{
	float3 luminosity = float3( 0.199, 0.257, 0.094 );
	float whiteness = dot( base_colour.rgb, luminosity );

	return float4( whiteness, whiteness, whiteness, base_colour.a );
}

float SmoothStep(float val, float center, float curve)
{
	float eps = 1e-7f;
	val = min(val, 1.0f - eps);
	val = max(val , eps);
	float power = 2.0f / max(1e-3f, 1.0f - curve) - 1.0f;
	return 1.0f - center + 
	(
		-pow(saturate(1.0f - max(center, val)), power) * pow(saturate(1.0f - center), -(power - 1.0f)) +
		 pow(saturate(       min(center, val)), power) * pow(saturate(       center), -(power - 1.0f))
	);
}


struct InterpNodes2
{
	float2 phases;
	float2 seeds;
	float2 weights;
};
InterpNodes2 GetLinearInterpNodes(float global_phase)
{
	float2 global_phases = float2(0.5f, 0.0f) + global_phase * 0.5f;
	InterpNodes2 interp_nodes2;
	interp_nodes2.phases = frac(global_phases);
	interp_nodes2.seeds = floor(global_phases) * 2.0f + float2(0.0f, 1.0f);
	interp_nodes2.weights = min(interp_nodes2.phases, 1.0f - interp_nodes2.phases) * 2.0; 
	return interp_nodes2; 
}

float3 hash33(float3 p3)
{
	p3 = frac(p3 * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz+19.19);
	return frac((p3.xxy + p3.yxx)*p3.zyx);
}

//from Qizhi Yu, et al [2011]. Lagrangian Texture Advection: Preserving Both Spectrum and Velocity Field. 
//IEEE Transactions on Visualization and Computer Graphics 17, 11 (2011), 1612–1623
float4 PreserveVariance(float4 linear_color, float4 mean_color, float moment2)
{
    return (linear_color - mean_color) / sqrt(moment2) + mean_color;
}

float4 GetEvolvingTex(float2 uv_coord, float2 flow_vec, float mip_level, float phase, uniform TEXTURE2D_DECL(tex))
{
	float4 mean_color = SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(0.5f, 0.5f, 0.0f, 10.0f));
	float4 res = 0.0f;
	InterpNodes2 interp_nodes = GetLinearInterpNodes(phase);
	float moment2 = 0.0f;
	for(int i = 0; i < 2; i++)
	{
		float2 uv = uv_coord + hash33(float3(interp_nodes.seeds[i], 0.0f, 0.0f)).xy + flow_vec * (interp_nodes.phases[i] - 0.5f);
		float weight = interp_nodes.weights[i];
		//weight = 3.0f * weight * weight - 2.0f * weight * weight * weight;
		res += SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(uv, 0.0f, mip_level)) * weight;
		moment2 += weight * weight;
	}
	return PreserveVariance(res, mean_color, moment2);
	//return SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(uv_coord, 0.0f, mip_level));
	//return res;
}

	static const float2 hex_ratio = float2(1.0, sqrt(3.0));

	//credits for hex tiling goes to Shane (https://www.shadertoy.com/view/Xljczw)
	//center, index
	float4 GetHexGridInfo(float2 uv)
	{
		float4 hex_index = round(float4(uv, uv - float2(0.5, 1.0)) / hex_ratio.xyxy);
		float4 hex_center = float4(hex_index.xy * hex_ratio, (hex_index.zw + 0.5) * hex_ratio);
		float4 offset = uv.xyxy - hex_center;
		return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? 
			float4(hex_center.xy, hex_index.xy) : 
			float4(hex_center.zw, hex_index.zw);
	}

	float GetHexSDF(in float2 p)
	{
		p = abs(p);
		return 0.5 - max(dot(p, hex_ratio * 0.5), p.x);
	}

	//xy: node pos, z: weight
	float3 GetTriangleInterpNode(in float2 pos, in float freq, in int node_index)
	{
		float2 node_offsets[3] = {
			float2(0.0, 0.0),
			float2(1.0, 1.0),
			float2(1.0,-1.0)};

		float2 uv = pos * freq + node_offsets[node_index] / hex_ratio.xy * 0.5;
		float4 hex_info = GetHexGridInfo(uv);
		float dist = GetHexSDF(uv - hex_info.xy) * 2.0;
		return float3(hex_info.xy / freq, dist);
	}
