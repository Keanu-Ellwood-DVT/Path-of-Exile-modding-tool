//PRECOMPILE vs_4_0 BaseVertexTransform
//PRECOMPILE vs_4_0 TexturedVertexTransform
//PRECOMPILE vs_4_0 PointOfInterestVertexTransform
//PRECOMPILE vs_gnm BaseVertexTransform
//PRECOMPILE vs_gnm TexturedVertexTransform
//PRECOMPILE vs_gnm PointOfInterestVertexTransform
//PRECOMPILE vs_vkn BaseVertexTransform
//PRECOMPILE vs_vkn TexturedVertexTransform
//PRECOMPILE vs_vkn PointOfInterestVertexTransform

CBUFFER_BEGIN(cminimap_vertex_transform)
	float4 x_basis;
	float4 y_basis;
	float4 z_basis;
	float4 tiles_count;
	float4x4 transform;

	float4 map_center_pos;
	float4 poi_center_pos;
	float icon_scale;
	float4 viewport_size;
	float4 render_circle;
CBUFFER_END

struct VS_BASE_INPUT
{
	float2 tile_index : POSITION;
	float height : TEXCOORD0;
};

struct VS_TEXTURED_INPUT
{
	float2 tile_index : POSITION;
	float height : TEXCOORD0;
	float2 uv : TEXCOORD1;
	float2 projection_offset : TEXCOORD2;
};

struct VS_OUTPUT
{
	float4 pos : SV_POSITION;
	float2 texture_uv : TEXCOORD1;
	float4 untransformed_pos : TEXCOORD2;
};

/*VS_OUTPUT BaseVertexTransform( const VS_BASE_INPUT input )
{
	float2 projected_pos = 
		y_basis.xy * -(tiles_count.x - input.tile_index.x) + 
		x_basis.xy * -(tiles_count.y - input.tile_index.y) +
		z_basis.xy * -input.height;
	VS_OUTPUT output;
	output.pos = mul( float4( projected_pos, 0.0f, 1.0f ), transform );
	output.texture_uv = float2(0.0f, 0.0f);
	output.untransformed_pos = float4(input.tile_index.xy, input.height, 1.0);
	return output;
}*/

VS_OUTPUT BaseVertexTransform( const VS_BASE_INPUT input )
{
	float2 projected_pos = 
		x_basis.xy * input.tile_index.x + 
		y_basis.xy * input.tile_index.y +
		z_basis.xy * input.height;
	projected_pos.y = -projected_pos.y;
	VS_OUTPUT output;
	output.pos = mul( float4( projected_pos, 0.0, 1.0f ), transform );
	output.pos /= output.pos.w;
	output.pos.z = 0.5f - input.height * 0.001f;
	output.texture_uv = float2(0.0f, 0.0f);
	output.untransformed_pos = float4(input.tile_index.xy, input.height, 1.0);
	return output;
}


VS_OUTPUT TexturedVertexTransform( const VS_TEXTURED_INPUT input )
{
	float2 projected_pos = 
		x_basis.xy * input.tile_index.x + 
		y_basis.xy * input.tile_index.y +
		z_basis.xy * input.height;
	projected_pos.y = -projected_pos.y;
	projected_pos += input.projection_offset;
	VS_OUTPUT output;
	output.pos = mul( float4( projected_pos, 0.0f, 1.0f ), transform );
	output.texture_uv = input.uv;
	output.untransformed_pos = float4(input.tile_index.xy, input.height, 1.0);
	return output;
}


VS_OUTPUT PointOfInterestVertexTransform( const VS_TEXTURED_INPUT input )
{
	VS_OUTPUT output;

//	float4 map_center_projected_offset = mul( float4( map_center_pos.xy, 0.0f, 0.0f ), transform );
//	float4 poi_center_projected_pos = mul( float4( poi_center_pos.xy, 0.0f, 1.0f ), transform );
	float4 poi_center_projected_pos = float4( poi_center_pos.xy, 0.0f, 1.0f );

	/*float2 poi_delta_projected = poi_center_projected_pos.xy - map_center_projected_offset.xy;
	//float ang = atan(poi_delta_projected.y, poi_delta_projected.x);

	float max_dist = 100.0f;//render_circle.z;
	float2 poi_delta_pixels = poi_delta_projected * viewport_size * 0.5f - render_circle.xy;
	float dist = length(poi_delta_pixels);
	if(dist > max_dist)
	{
		poi_delta_pixels *= max_dist / dist;
	}*/

	//output.pos.xy = (poi_delta_pixels + render_circle.xy) / (viewport_size * 0.5f) + mul( float4( input.projection_offset * icon_scale, 0.0f, 0.0f ), transform ).xy;
	output.pos.xy = poi_center_projected_pos.xy + mul( float4( input.projection_offset * icon_scale, 0.0f, 0.0f ), transform ).xy;
	output.pos.zw = float2(1.0f, 1.0f);
	output.texture_uv = input.uv;
	output.untransformed_pos = float4(input.tile_index.xy, input.height, 1.0);
	return output;
}