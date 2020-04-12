//PRECOMPILE ps_4_0 PShad
//PRECOMPILE ps_gnm PShad
//PRECOMPILE ps_vkn PShad

CBUFFER_BEGIN( cminimap_vertex_transform )
	float4 x_basis;
	float4 y_basis;
	float4 z_basis;
	float4 tiles_count;

	float4 render_circle;
	float alpha;	
CBUFFER_END

TEXTURE2D_DECL( walkability_sampler );

struct PS_INPUT
{
	float4 pos : SV_POSITION;
	float2 location : TEXCOORD0;
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


float4 PShad( const PS_INPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float2x2 isometric_transform;
	isometric_transform[0] = x_basis.xy;
	isometric_transform[1] = y_basis.xy;
	//float2 planar_pos = mul(inverse(isometric_transform), input.untransformed_pos);
	float2 planar_pos = mul(input.untransformed_pos.xy, inverse(isometric_transform));
	float t = planar_pos.x;
	planar_pos.x = planar_pos.y;
	planar_pos.y = t;

	//texcolour = lerp(texcolour, float4(frac(planar_pos.xy), 0.0f, 1.0f), 0.1f);//float4(input.untransformed_pos.xy / 1000.0f, 0.0f, 1.0f);
	float2 map_coord = planar_pos / tiles_count.xy; //no clue what's going on here
	map_coord.x = 1.0 - map_coord.x;
	map_coord.y = 1.0 - map_coord.y;
	//map_coord.y = 1.0 - map_coord.y;
	//texcolour = lerp(texcolour, float4(frac(planar_pos.xy), 0.0f, 1.0f), 0.3f);//float4(input.untransformed_pos.xy / 1000.0f, 0.0f, 1.0f);
	float4 walkability_sample = SAMPLE_TEX2D( walkability_sampler, SamplerLinearClamp, frac(map_coord) );
	//texcolour = lerp(texcolour, float4(walkability_sample.rgb, 1.0f), 0.5f);//float4(input.untransformed_pos.xy / 1000.0f, 0.0f, 1.0f);

	float walkable_dist = walkability_sample.b;
	float4 res_color;
	float eps = 4.5e-1f;
	float aa_width = 2e-1f;

	float walkable_to_edge_ratio = saturate((walkable_dist - (eps - aa_width)) / aa_width);
	float edge_to_unwalkable_ratio = saturate((walkable_dist - (1.0f - eps)) / aa_width);

	//res_color = lerp(float4(1.0f, 1.0f, 1.0f, 0.01f), float4(1.0f, 1.0f, 1.0f, 0.3f), walkable_to_edge_ratio);
	res_color = lerp(float4(1.0f, 1.0f, 1.0f, 0.01f), float4(0.5f, 0.5f, 1.0f, 0.3f), walkable_to_edge_ratio);
	res_color = lerp(res_color, float4(res_color.rgb, 0.0f), edge_to_unwalkable_ratio);

	return res_color;
}