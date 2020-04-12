//PRECOMPILE vs_4_0 VShad
//PRECOMPILE ps_4_0 PShad
//PRECOMPILE ps_4_0 PShad_Holo
//PRECOMPILE ps_4_0 PShad_Shaper
//PRECOMPILE ps_4_0 PShad_Elder
//PRECOMPILE ps_4_0 PShad_Mask
//PRECOMPILE ps_4_0 PShad_Tentacles
//PRECOMPILE ps_4_0 PShad_Synthesized
//PRECOMPILE ps_4_0 PShad_Fractured
//PRECOMPILE ps_4_0 PShad_Outline
//PRECOMPILE ps_4_0 PShad_Conqueror
//PRECOMPILE ps_4_0 PShad_ConquerorGlow
//PRECOMPILE ps_4_0 PShad_Basilisk
//PRECOMPILE ps_4_0 PShad_BasiliskGlow
//PRECOMPILE ps_4_0 PShad_Crusader
//PRECOMPILE ps_4_0 PShad_CrusaderGlow
//PRECOMPILE ps_4_0 PShad_Eyrie
//PRECOMPILE ps_4_0 PShad_EyrieGlow
//PRECOMPILE ps_4_0 PShad_ConquerorRegion
//PRECOMPILE ps_4_0 PShad_BasiliskRegion
//PRECOMPILE ps_4_0 PShad_CrusaderRegion
//PRECOMPILE ps_4_0 PShad_EyrieRegion
//PRECOMPILE vs_gnm VShad
//PRECOMPILE ps_gnm PShad
//PRECOMPILE ps_gnm PShad_Holo
//PRECOMPILE ps_gnm PShad_Shaper
//PRECOMPILE ps_gnm PShad_Elder
//PRECOMPILE ps_gnm PShad_Mask
//PRECOMPILE ps_gnm PShad_Tentacles
//PRECOMPILE ps_gnm PShad_Synthesized
//PRECOMPILE ps_gnm PShad_Fractured
//PRECOMPILE ps_gnm PShad_Outline
//PRECOMPILE ps_gnm PShad_Conqueror
//PRECOMPILE ps_gnm PShad_ConquerorGlow
//PRECOMPILE ps_gnm PShad_Basilisk
//PRECOMPILE ps_gnm PShad_BasiliskGlow
//PRECOMPILE ps_gnm PShad_Crusader
//PRECOMPILE ps_gnm PShad_CrusaderGlow
//PRECOMPILE ps_gnm PShad_Eyrie
//PRECOMPILE ps_gnm PShad_EyrieGlow
//PRECOMPILE ps_gnm PShad_ConquerorRegion
//PRECOMPILE ps_gnm PShad_BasiliskRegion
//PRECOMPILE ps_gnm PShad_CrusaderRegion
//PRECOMPILE ps_gnm PShad_EyrieRegion
//PRECOMPILE vs_vkn VShad
//PRECOMPILE ps_vkn PShad
//PRECOMPILE ps_vkn PShad_Holo
//PRECOMPILE ps_vkn PShad_Shaper
//PRECOMPILE ps_vkn PShad_Elder
//PRECOMPILE ps_vkn PShad_Mask
//PRECOMPILE ps_vkn PShad_Tentacles
//PRECOMPILE ps_vkn PShad_Synthesized
//PRECOMPILE ps_vkn PShad_Fractured
//PRECOMPILE ps_vkn PShad_Outline
//PRECOMPILE ps_vkn PShad_Conqueror
//PRECOMPILE ps_vkn PShad_ConquerorGlow
//PRECOMPILE ps_vkn PShad_Basilisk
//PRECOMPILE ps_vkn PShad_BasiliskGlow
//PRECOMPILE ps_vkn PShad_Crusader
//PRECOMPILE ps_vkn PShad_CrusaderGlow
//PRECOMPILE ps_vkn PShad_Eyrie
//PRECOMPILE ps_vkn PShad_EyrieGlow
//PRECOMPILE ps_vkn PShad_ConquerorRegion
//PRECOMPILE ps_vkn PShad_BasiliskRegion
//PRECOMPILE ps_vkn PShad_CrusaderRegion
//PRECOMPILE ps_vkn PShad_EyrieRegion

CBUFFER_BEGIN( DefaultConstants )
	float4x4 transform;
CBUFFER_END

CBUFFER_BEGIN( ctime )
	float time;
	float seed;
	float has_mask;
	float has_background;
	float4 aspect_ratio;
	float4 tex_scale;
	float muddle_frequency;
	float4 muddle_intensity;
	float4 tex_clamp;
	float4 effect_params;
	float shader_type;
	float layers_count;
	float4 item_size;

	float4 layer_0_speed;
	float4 layer_1_speed;
	float4 layer_2_speed;
	float4 layer_3_speed;
CBUFFER_END

TEXTURE2D_DECL( tex );
TEXTURE2D_DECL( mask_tex );


TEXTURE2D_DECL( color_layer_0_tex );
TEXTURE2D_DECL( color_layer_1_tex );
TEXTURE2D_DECL( color_layer_2_tex );
TEXTURE2D_DECL( color_layer_3_tex );

TEXTURE2D_DECL( influence_layer_0_tex );
TEXTURE2D_DECL( influence_layer_1_tex );
TEXTURE2D_DECL( influence_layer_2_tex );
TEXTURE2D_DECL( influence_layer_3_tex );

TEXTURE2D_DECL( mask_layer_0_tex );
TEXTURE2D_DECL( mask_layer_1_tex );
TEXTURE2D_DECL( mask_layer_2_tex );
TEXTURE2D_DECL( mask_layer_3_tex );

TEXTURE2D_DECL( muddle_tex );
TEXTURE2D_DECL( influence_noise_tex );
TEXTURE2D_DECL( fractal_tex );
TEXTURE2D_DECL( turbulence_tex );
TEXTURE2D_DECL( background_tex );

TEXTURE2D_DECL( bg_tex );
TEXTURE2D_DECL( bg_mask_tex );

#include "Shaders/Include/Util.hlsl"

struct VS_INPUT
{
	float2 position   : POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

struct VS_OUTPUT
{
	float4 position   : SV_POSITION;
	float2 texture_uv : TEXCOORD0;
	float4 colour     : COLOR0;
	float4 sat_scale_localuv  : TEXCOORD1;
};

VS_OUTPUT VShad( const VS_INPUT input )
{
	VS_OUTPUT output;
	float4 pos4 = float4(input.position.xy, 0.0f, 1.0f);
	output.position   = mul( pos4, transform ) ;
	output.texture_uv = input.texture_uv;
	output.colour     = input.colour;
	output.sat_scale_localuv = input.sat_scale_localuv;
	return output;
}

#define GetOffsetCoord(influence_tex, influence_sampler, seed, in_tex_coord, out_tex_coord, muddle_frequency, muddle_intensity, aspect_ratio, tex_scale) \
{\
	out_tex_coord = in_tex_coord; \
	float4 muddle_sample = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, out_tex_coord * muddle_frequency * aspect_ratio.xy + float2(seed, seed * 1.37f)); \
	out_tex_coord *= tex_scale.xy; \
	float4 influence_sample = SAMPLE_TEX2D(influence_tex, influence_sampler, out_tex_coord); \
	out_tex_coord += sin(time + muddle_sample.a * 2.0f + seed * 0.3f) * (muddle_sample.xy - 0.5f) / aspect_ratio.xy * muddle_intensity.xy * influence_sample.r; \
	out_tex_coord.x = tex_clamp.x > 0.5f ? clamp(out_tex_coord.x, 0.0f, 1.0f) : out_tex_coord.x; \
	out_tex_coord.y = tex_clamp.y > 0.5f ? clamp(out_tex_coord.y, 0.0f, 1.0f) : out_tex_coord.y; \
}
	
float4 PShad( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ) ;
	float4 final = input.colour * lerp( float4( 1, 1, 1, 1 ), tex_colour, input.sat_scale_localuv.y )  ;
	final.rgb = lerp( dot( final.rgb, float3( 0.30, 0.59, 0.11 ) ), final.rgb, input.sat_scale_localuv.x ) ;
	
	return final;
}

float3 mod( float3 a, float b )
{
	return float3( a.x - b * floor( a.x / b ), a.y - b * floor( a.y / b ), a.z - b * floor( a.z / b ) );
}

float3 color_holo( float2 p, float sum )
{
	p.y -= 9.f;
	float3 _mod = mod( p.y*0.15*6.0 + float3( 0.0, 4.0, 2.0 ), 6.0 );
	float3 _abs = abs( _mod - 3.0 );
	float3 hue = clamp( _abs - 1.0, 0.f, 1.f );
	float3 gray = 0.6;
	float sat = ( cos( p.y )*0.5 + 0.5 ) * ( 0.2 + sum*0.8 );
	return lerp( gray, hue, sat );
}

float4 PShad_Holo( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy );
	float4 final = input.colour * lerp( float4( 1, 1, 1, 1 ), tex_colour, input.sat_scale_localuv.y ) ;
	final.rgb = lerp( dot( final.rgb, float3( 0.30, 0.59, 0.11 ) ), final.rgb, input.sat_scale_localuv.x );

	float variable = -3.f + sin( time ) * 0.4f;
	float3 dir = float3( input.sat_scale_localuv.z * 2.f - 1.f, 1.f - input.sat_scale_localuv.w * 2.f, variable );
	float3 normal = float3( 0, 0, 1.f );
	float sum = ( final.r + final.g + final.b ) / 3.f;
	sum = saturate( sum * 8.f );

	float2 d = dir.xy + ( sum * 2.0 - 1.0 );
	d += dot( dir, normal ) * 5.5f;

	final.rgb = final.rgb * color_holo( d, sum );
	//float bright = saturate( pow( sum, 2.f ) * 2.f );
	//final.rgb = final.rgb * ( 1.f - bright ) + color_holo( d, sum ) * bright;

	return final;
}

float4 ApplyOutline( float4 icolor, float2 icoord )
{
	if (icolor.a <= 0.5)
	{
		const float offset = 1.f / 64.f;
		float a = 
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x + offset, icoord.y)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x, icoord.y - offset)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x - offset, icoord.y)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x, icoord.y + offset)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x - offset, icoord.y - offset)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x - offset, icoord.y + offset)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x + offset, icoord.y - offset)).a +
			SAMPLE_TEX2D(tex, SamplerLinearWrap, float2(icoord.x + offset, icoord.y + offset)).a;
		a *= 0.125;
		icolor.a = a*4.f;
		icolor.rgb = 0.f;
	}
	return icolor;
}

float4 GetShaperBackground( const VS_OUTPUT input )
{
	float2 pan_speed = float2( 0.0105f, 0.006f );
	float2 inv_bg_resolution = effect_params.xy;
	float2 screen_uv = input.position.xy * inv_bg_resolution.xy + time*pan_speed;
	float4 bg = SAMPLE_TEX2D( bg_tex, SamplerLinearWrap, screen_uv );
	
	float4 muddle_info = float4( 1.2f, 0.075f, 0.075f, 0.125f );
	float2 muddle_uv = input.texture_uv * muddle_info.x + time * muddle_info.yz;
	float2 mask_uv = input.texture_uv + (SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, muddle_uv ).rg - float2(0.f, 0.5f))*muddle_info.w;
			
	bg.a = SAMPLE_TEX2D( bg_mask_tex, SamplerLinearBorder, mask_uv ).r;
	bg *= bg.a * 2.f;

	return bg;
}

float4 Overlay(float4 col0, float4 col1)
{
	return lerp(col0, col1, col1.a);
}

float4 GetOutlinedTexture(const VS_OUTPUT input)
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy );
	float4 final = lerp( float4( 1, 1, 1, 1 ), tex_colour, input.sat_scale_localuv.y ) ;
	final.rgb = lerp( dot( final.rgb, float3( 0.30, 0.59, 0.11 ) ), final.rgb, input.sat_scale_localuv.x );
	return ApplyOutline( final, input.texture_uv.xy );
}

float4 PShad_Outline( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	return GetOutlinedTexture( input );
}

float4 PShad_Shaper( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 bg = GetShaperBackground( input );
	return bg * input.colour.a;
}

float4 GetElderBackground( const VS_OUTPUT input )
{
	float2 tex_coord = input.texture_uv.xy;

	float _muddle_frequency = 0.1f;
	float4 _muddle_intensity = 1.0f;
	float4 _aspect_ratio = effect_params.y / effect_params.x;
	float4 _tex_scale = 1.f;
	
	float2 tex_coord1 = tex_coord;
	float2 tex_coord2 = tex_coord;
	GetOffsetCoord(influence_layer_0_tex, SamplerLinearWrap, seed, tex_coord, tex_coord1, _muddle_frequency, _muddle_intensity, _aspect_ratio, _tex_scale);
	GetOffsetCoord(influence_layer_1_tex, SamplerLinearWrap, (seed + 3.14f), tex_coord, tex_coord2, _muddle_frequency, _muddle_intensity, _aspect_ratio, _tex_scale);
	
	float4 background1 = SAMPLE_TEX2D(color_layer_0_tex, SamplerLinearBorder, tex_coord1);
	background1.rgb *= background1.a;
	float4 final = background1;
	
	float4 background2 = SAMPLE_TEX2D(color_layer_1_tex, SamplerLinearBorder, tex_coord2);
	background2.rgb *= background2.a;
	final = final * final.a + background2 * ( 1.f - final.a );

	return final;
}

float4 PShad_Elder( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 bg = GetElderBackground( input );
	return bg * input.colour.a;
}

float4 PShad_Mask( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 tex_colour = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy )   ;
	float4 mask_colour = SAMPLE_TEX2D( mask_tex, SamplerLinearClamp, input.texture_uv.xy ) ;
	float mask_alpha = 1.f - mask_colour.a;
	float4 final = input.colour * lerp( float4( 1, 1, 1, 1 ), tex_colour * mask_alpha, input.sat_scale_localuv.y );
	final.rgb = lerp( dot( final.rgb, float3( 0.30, 0.59, 0.11 ) ), final.rgb, input.sat_scale_localuv.x );
	return final;
}

float4 GetShrunkColor(float2 uv, float width)
{
	int2 offsets[] = {int2(-1, 0), int2(0, 1), int2(1, 0), int2(0, -1)};
	
	float4 shrunk_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
	[unroll]
	for(int i = 0; i < 4; i++)
	{
		float4 test_sample = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv + offsets[i] * width );
		shrunk_color = (shrunk_color.a < test_sample.a) ? shrunk_color : test_sample;
	}
	return shrunk_color;
}

float rand(float2 v){
	return frac(sin(dot(v.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float3 BlackBody(float _t)
{
	// See: http://en.wikipedia.org/wiki/Planckian_locus
	//      under "Approximation"

	float u = (0.860117757 + 1.54118254e-4*_t + 1.28641212e-7*_t*_t)
			/ (1.0 + 8.42420235e-4*_t + 7.08145163e-7*_t*_t);

	float v = (0.317398726 + 4.22806245e-5*_t + 4.20481691e-8*_t*_t)
			/ (1.0 - 2.89741816e-5*_t + 1.61456053e-7*_t*_t);

	// http://en.wikipedia.org/wiki/CIE_1960_color_space
	// -> http://en.wikipedia.org/wiki/XYZ_color_space

	float x = 3.0 * u / (2.0 * u - 8.0 * v + 4.0);
	float y = 2.0 * v / (2.0 * u - 8.0 * v + 4.0);
	float z = 1.0 - x - y;

	float Y = 1.0;
	float X = (Y/y) * x;
	float Z = (Y/y) * z;

	// http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
	float3x3 XYZtosRGB = float3x3(
				3.2404542,-1.5371385,-0.4985314,
			-0.9692660, 1.8760108, 0.0415560,
				0.0556434,-0.2040259, 1.0572252
	);

	float3 RGB = mul(XYZtosRGB, float3(X,Y,Z));
	return pow(saturate(RGB * pow(0.0004*_t, 4.0)), 2.2f) * 2.0f;
}	


float4 GetSynthesizedOutline(float2 uv)
{
	float4 base_color;
	float4 shrunk_color;
	//float2 aspect_ratio = float2(1.0f, item_size.y / item_size.x);//float2(1.0f, item_size.x / item_size.y);
	float2 aspect_ratio = float2(item_size.x, item_size.y) / 128.0f;
	{
		
		float4 muddle_sample = SAMPLE_TEX2D( turbulence_tex, SamplerLinearWrap, (uv * 3.0f + float2(0.0f, time * 0.1f)) * aspect_ratio );
		//return muddle_sample.x;
		base_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv +  (muddle_sample.rg - 0.5f) * 0.08f / aspect_ratio );
	}
	{
		float4 muddle_sample = SAMPLE_TEX2D( turbulence_tex, SamplerLinearWrap, (uv * 3.0f + 0.3f + float2(0.0f, time * 0.05f)) * aspect_ratio );
		shrunk_color = GetShrunkColor(uv + (muddle_sample.rg - 0.5f) * 0.08f / aspect_ratio, 0.02f );
	}
	base_color.rgb /= base_color.a;
	base_color.a = saturate(base_color.a - shrunk_color.a);
	base_color.rgb *= base_color.a;
	return base_color;
}




float3 GetSynthesizedOutlineGlow(float2 uv, float3 color)
{
		float4 outline_color = GetSynthesizedOutline(uv);
		float grayscale = Luminance(outline_color.rgb / outline_color.a);
		grayscale = (grayscale * 0.5f + 0.5f) * outline_color.a;
		return Vibrance(grayscale, color);
}

float3 GetSynthesizedFillGlow(float2 uv, float3 color)
{
		float4 fill_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
		
		float grayscale = Luminance(fill_color.rgb / fill_color.a);
		//grayscale = (grayscale * 0.5f + 0.5f) * fill_color.a;
		//grayscale = pow(grayscale * fill_color.a, 0.5f);
		//grayscale = SmoothStep(grayscale, 0.8f, -0.1f) * fill_color.a;
		
		float2 aspect_ratio = float2(item_size.x, item_size.y) / 128.0f;

		float2 muddle_uv = uv + float2(0.2f, -1.0f) * grayscale * 0.3f;
		float glow_intensity = pow(SAMPLE_TEX2D(fractal_tex, SamplerLinearWrap, muddle_uv * aspect_ratio + float2(0.0f, time * 0.1f)).b, 2.0f) * 1.0f;
		
		return Vibrance(glow_intensity, color) * fill_color.a;
}

float4 PShad_Synthesized( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	int2 offsets[] = {int2(-1, 0), int2(0, 1), int2(1, 0), int2(0, -1)};
	
	
	float2 ray_dir = (input.texture_uv.xy - 0.5f);

	{	
		float4 muddle_sample = SAMPLE_TEX2D( turbulence_tex, SamplerLinearWrap, input.texture_uv.xy * 0.7f + float2(time * 0.3f, 0.0f));
		float2 displacement = (saturate(muddle_sample.rg) - 0.5f) * 2.0f;
		ray_dir += displacement * 0.4f;
	}
	
	float total_temp = 0.0f;
	
	float total_weight = 0.0f;
	float seed = 0.0f;//rand(input.texture_uv.xy);
	#define step_size 0.03f
	
	float3 color = pow(float3(132, 181, 255) / 255.0f, 2.2f);
	float3 outline_glow_color = GetSynthesizedOutlineGlow(input.texture_uv.xy, color);
	float3 fill_glow_color = GetSynthesizedFillGlow(input.texture_uv.xy, color);
	return float4(outline_glow_color + fill_glow_color, 0.0f);
	//return float4(fill_glow_color, 1.0f);
}

float4 GetInfluenceNoise(float2 uv, float phase, uniform TEXTURE2D_DECL(noise_tex))
{
	float PI = 3.14159265f;
	InterpNodes2 nodes = GetLinearInterpNodes(phase);
	
	float4 res = 0.0f;
	float moment = 0;
	for(int i = 0; i < 2; i++)
	{
		float3 hash = hash33(float3(nodes.seeds[i], 0.0f, 0.0f));

		float random_angle = hash.x * PI * 2.0f;

		float2x2 rotation_matrix = float2x2(cos(random_angle), -sin(random_angle),
											sin(random_angle),  cos(random_angle));

		float2 random_uv = mul(uv, rotation_matrix) + hash.yz;
		float4 noise = SAMPLE_TEX2D(noise_tex, SamplerLinearWrap, random_uv);
		moment += nodes.weights[i] * nodes.weights[i];
		res += noise * nodes.weights[i];
	}

	res = PreserveVariance(res, 0.5f, moment);
	return res;
}

float4 GetInfluenceColor(float4 src_color, float4 dst_color)
{
	float luminance = pow(dot(src_color, 1.0f), 4.01f) * 0.1f;
	return float4(Vibrance(luminance * 0.5f, dst_color.rgb) * src_color.a, src_color.a);
}

float4 GetParticlesColor(float2 uv, float2 scroll_speed, float2 uv_offset, float threshold)
{
	float4 color = 0.0f;
	float grid_step = 0.02f;
	float time_with_seed = time + seed;
	float2 scrolled_uv = uv + scroll_speed * time_with_seed;
	for(int i = 0; i < 3; i++)
	{
		float3 interp_node = GetTriangleInterpNode(scrolled_uv, 1.0f / grid_step, i);
		float4 noise_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, interp_node.xy * 5.1 );

		float2 velocity = (noise_sample.xy - 0.5f) * 1.6f;// + float2(0.0f, -0.25f);

		color += SAMPLE_TEX2DLOD( muddle_tex, SamplerLinearWrap, float4(scrolled_uv * 15.0f + noise_sample.zw * 100.0f + velocity * time_with_seed, 0.0f, 0.0f) ) * interp_node.z; 
	}
	//return SAMPLE_TEX2DLOD( muddle_tex, SamplerLinearWrap, float4(uv * 10.0f, 0.0f, 0.0f) );
	float intensity_mip = 4.0f;
	//float snow_intensity = pow(saturate((SAMPLE_TEX2DLOD(tex, SamplerLinearClamp, float4(uv + float2(0.0f, -0.1f) + 0.5f * pow(2.0f, intensity_mip) / item_size.xy, 0.0f, intensity_mip)).a - 0.5f) * 2.0f), 2.0f);
	float snow_intensity = saturate((SAMPLE_TEX2DLOD(tex, SamplerLinearClamp, float4(uv + uv_offset, 0.0f, intensity_mip)).a) * 2.0f);
	float snow_color = saturate((color.r - lerp(1.0f, threshold, snow_intensity)) * 3.0f);
	return snow_color;
}

float4 GetInfluencedFlameSlow( const VS_OUTPUT input, float4 influence_color )
{
	float time_with_seed = time + seed;
	influence_color = float4(1.85, 1.1, 0.2, 1.0);
	float2 sample_uv = input.texture_uv.xy;
	float4 noise = GetInfluenceNoise(sample_uv * 4.0f + float2(0, time_with_seed * 0.32f), time_with_seed, muddle_tex);
	float displacement_mult = saturate((0.5f - SAMPLE_TEX2DLOD( tex, SamplerLinearWrap, float4(sample_uv, 0.0f, 3.0f) ).a) * 2.0f);
	float2 displacement = (saturate(noise.xy) - 0.5f) * 0.4f * displacement_mult * 0.4;
	float4 texture_muddled = SAMPLE_TEX2DLOD(tex, SamplerLinearClamp, float4(saturate(sample_uv + displacement + float2(0.0f, 0.05f)), 0.0f, 2 + 4.0f * noise.z));

	//float luminance = pow(dot(texture_muddled, 1.0f), 6.0f) * 0.1f * noise.z;
	float luminance = pow(SmoothStep(dot(texture_muddled, 1.0f), 0.5, 0.1) * (noise.z + noise.x + 0.5), 3.0f) * 0.15f;
	float4 influence_flame = float4(Vibrance(luminance, influence_color.rgb) * texture_muddled.a, texture_muddled.a);

	return influence_flame + GetParticlesColor(input.texture_uv.xy, float2(0.0f, 0.1f), float2(0.0f, 0.07f), 0.6f) * float4(1.0f, 1.0f, 0.6f, 1.0f);
}

float4 GetInfluencedLightning( const VS_OUTPUT input, float4 influence_color )
{
	float time_with_seed = time + seed;
	influence_color = float4(1.0, 1.5, 5.0, 1.0);
	float2 sample_uv = input.texture_uv.xy;
	float4 noise = GetInfluenceNoise(sample_uv * 1.0f + float2(0, time_with_seed * 1.0f), time_with_seed * 2.5, muddle_tex);
	//float displacement_mult = saturate((0.5f - SAMPLE_TEX2DLOD( tex, SamplerLinearWrap, float4(sample_uv, 0.0f, 3.0f) ).a) * 2.0f);
	float displacement_mult = 1;
	float2 displacement = (saturate(noise.xy) - 0.5f) * 0.4f * displacement_mult * 1.2;
	float4 texture_muddled = SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(saturate(sample_uv + displacement), 0.0f, 0.0f)) * 1.4f;
	float luminance = pow(dot(texture_muddled, 1.0f), 5.0f) * 0.02f;
	float4 influence_flame = float4(Vibrance(luminance, influence_color.rgb) * texture_muddled.a, texture_muddled.a) * 10;
	
	sample_uv += displacement;
	float4 texture_blurred = SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(sample_uv, 0.0f, 2));
	float4 texture_normal = SAMPLE_TEX2D(tex, SamplerLinearWrap, sample_uv);

	float glow_alpha = pow(saturate((texture_normal.a - texture_blurred.a)), 0.3f);
	influence_flame *= glow_alpha;

	float4 noise_value = GetInfluenceNoise(sample_uv * 1.5f + float2(0, -time_with_seed * 1.0f), time_with_seed * 1.5, muddle_tex);
	noise_value = saturate(pow(dot(noise_value, 1), 4) / 10.0 - 1.2);
	influence_flame.rgba *= noise_value;
	
	return influence_flame;
}

float4 GetInfluencedFlameBasilisk( const VS_OUTPUT input, float4 influence_color, float2 offset, float scroll_multiplier, float phase )
{
	float2 sample_uv = input.texture_uv.xy;
	float4 noise = GetInfluenceNoise(sample_uv * 2.0f + float2(0, phase * scroll_multiplier), phase * 3.5, influence_noise_tex);
	
	float displacement_mult = 0.5;
	float2 displacement = (saturate(noise.xy) - 0.5f) * 0.2f * displacement_mult + offset;
	float4 texture_muddled = SAMPLE_TEX2DLOD(tex, SamplerLinearClamp, float4(saturate(sample_uv + displacement), 0.0f, 0.5 + 5.0f * noise.x));
	float4 influence_flame = GetInfluenceColor(texture_muddled, influence_color);
	
	float4 image = SAMPLE_TEX2D(tex, SamplerLinearWrap, sample_uv);
	influence_flame = Overlay(influence_flame, image);

	return influence_flame;
}



float4 GetInfluencedFlameBlue( const VS_OUTPUT input, float2 offset, float scroll_multiplier, float phase )
{
	float4 influence_color = float4(1.0, 2.5, 10.65, 1.0);
	float2 sample_uv = input.texture_uv.xy;
	float4 noise = GetInfluenceNoise(sample_uv * 2.0f + float2(0, phase * scroll_multiplier * -0.5), phase * 2, muddle_tex);
	// float displacement_mult = saturate((0.5f - SAMPLE_TEX2DLOD( tex, SamplerLinearWrap, float4(sample_uv, 0.0f, 3.0f) ).a) * 2.0f);
	float displacement_mult = 1;
	float2 displacement = (saturate(noise.xy) - 0.5f) * 0.2f * displacement_mult * 0.1f + offset * 0.0f;
	float4 texture_muddled = SAMPLE_TEX2DLOD(tex, SamplerLinearClamp, float4(saturate(sample_uv + displacement), 0.0f, 2.0f + 4.0f * noise.z));
	// float luminance = pow(SmoothStep(dot(texture_muddled, 1.0f), 0.5, 0.5) * (noise.y + noise.x + 0.2), 4.0f) * 0.3f;
	float luminance = pow(dot(texture_muddled, 1.0f), 2.0f) * 0.3f;
	float4 influence_flame = float4(Vibrance(luminance, influence_color.rgb) * texture_muddled.a, texture_muddled.a);

	return influence_flame + GetParticlesColor(input.texture_uv.xy, float2(0.0f, -0.02f), float2(0.0f, -0.05f), 0.65f);
}

float4 GetRegionSmogBasilisk( const VS_OUTPUT input, float2 scroll_multiplier, float phase, float4 influence_colour )
{
	float mask_alpha = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ).a;
	float2 sample_uv = input.texture_uv.xy;
	float4 noise = GetInfluenceNoise( sample_uv * 1.8f + phase * scroll_multiplier * 3.5, phase, influence_noise_tex );

	float displacement_mult = 2.5f;
	float2 displacement = ( saturate( noise.xy ) - 0.5f ) * 0.2f * displacement_mult;
	float4 texture_muddled = SAMPLE_TEX2DLOD( tex, SamplerLinearWrap, float4( saturate( sample_uv + displacement ), 0.0f, 0.5 + 5.0f * noise.x ) );

	float4 noise_sample = SAMPLE_TEX2D( influence_noise_tex, SamplerLinearWrap, input.texture_uv.xy + float2( -0.001, -0.005 ) * time );
	float disp_magnitude = 0.6;
	float2 altered_uv = input.texture_uv.xy + ( ( noise_sample.xy * 2 ) - 1 ) * disp_magnitude;
	float disp_alpha = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, altered_uv ).r;
	float final_alpha = ( disp_alpha * texture_muddled.a ) *0.5 + 0.3;
	float4 output = influence_colour * mask_alpha  * final_alpha;
	return output;
}

float4 GetInfluencedGlow( float2 sample_uv, float4 influence_color, float scroll_multiplier, float phase, float glow_power = 5 )
{
	float4 noise = GetInfluenceNoise(sample_uv * 2.0f + float2(0, phase * scroll_multiplier), phase * 3.5, muddle_tex);
	//float2 displacement = (saturate(noise.xy) - 0.5f) * 0.02f * 0;
	float2 displacement = 0;
	float4 texture_normal = SAMPLE_TEX2D(tex, SamplerLinearWrap, sample_uv + displacement);
	float4 blurred = SAMPLE_TEX2DLOD(tex, SamplerLinearWrap, float4(sample_uv + displacement, 0.0f, 2.0f + 1.0f * noise.x));
	float glow_alpha = pow(saturate((texture_normal.a - blurred.a) * 2.0f), glow_power) * 0.5;
	float4 glow_multiplier = noise.x * 1.5 + 1.0;
	float4 glow = float4(Vibrance(glow_alpha * glow_multiplier, influence_color.rgb), glow_alpha);

	return glow;
}

float4 PShad_Conqueror( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = pow(float4(2.0, 0.35, 0.3, 1.0), 1.0f);
	return GetInfluencedFlameSlow(input, influence_color);
}

float4 PShad_ConquerorGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = float4(4.01, 2.5, 1.0, 1.0);
	return GetInfluencedGlow(input.texture_uv.xy, influence_color, 0.4, time + seed, 3.0);
}

float4 PShad_Basilisk( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = float4(3.0, 4.01, 0.6, 1.0);
	return GetInfluencedFlameBasilisk(input, influence_color, float2(0, -0.05), -0.4, (time + seed) * 0.2);
}

float4 PShad_BasiliskGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = pow(float4(2.6, 4.2, 0.2, 1.0), 1.0f);
	return GetInfluencedGlow(input.texture_uv.xy, influence_color, -0.4, (time + seed) * 0.3, 5.0);
}

float4 PShad_Crusader( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = float4(1.5, 3.5, 5.0, 1.0);
	return GetInfluencedLightning(input, influence_color);
}

float4 PShad_CrusaderGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float time_with_seed = time + seed;
	float4 influence_color = pow(float4(1.5, 3.5, 5.0, 1.0), 1.0f);

	float2 sample_uv = input.texture_uv.xy;

	float4 texture_normal = SAMPLE_TEX2D(tex, SamplerLinearWrap, sample_uv);
	float4 glow = GetInfluencedGlow(sample_uv, influence_color, 0.5, time_with_seed * 0.5, 1.8);

	float4 noise = GetInfluenceNoise(sample_uv * 2.5f - float2(0, time_with_seed * 0.03f), time_with_seed * 0.5, muddle_tex);
	float spot_value = saturate(pow(noise.r, 2.0) * 2.0) * texture_normal.a;

	float4 spot_color = float4(1.8, 0.45, 0.4, 1.0);
	float luminance = pow(dot(texture_normal, 1.0f), 1.5f) * 0.1f;
	spot_color = float4(Vibrance(luminance * 0.5f, spot_color.rgb) * spot_value, spot_value);
	spot_color.a = spot_value;

	return Overlay(glow, spot_color * (1 - glow.a));
}

float4 PShad_Eyrie( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	return GetInfluencedFlameBlue(input, 0.0, 0.3, (time + seed + 10.5) * 0.3);
}

float4 PShad_EyrieGlow( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float4 influence_color = float4(2.0, 2.5, 3.65, 1.0);
	return GetInfluencedGlow(input.texture_uv.xy, influence_color, 0.3, (time + seed + 10.5) * 0.5, 3.0);
}

float4 PShad_EyrieRegion( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float mask_alpha = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ).a;
	float4 influence_colour = float4( 0.07, 0.11, 0.23, 1.0f ); // Blue gem
	return influence_colour * mask_alpha * 0.5f;
}

float4 PShad_CrusaderRegion( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float mask_alpha = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ).a;
	float4 influence_colour = float4( 0.23, 0.08, 0.05, 1.0f ); // Red gem
	return influence_colour * mask_alpha * 0.5f;
}

float4 PShad_BasiliskRegion( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float mask_alpha = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ).a;
	float4 influence_colour = float4( 0.01, 0.20, 0.00, 1.0f ); // Green gem
	return influence_colour * mask_alpha * 0.5f;
}

float4 PShad_ConquerorRegion( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float mask_alpha = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy ).a;
	float4 influence_colour = float4( 0.35, 0.26, 0.04, 1.0f ); // Gold gem
	return influence_colour * mask_alpha * 0.5f;
}

float GetFracturedMask(float2 uv, float fracture_scale)
{
	float4 initial_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
	
	/*{
		float4 muddle_sample = SAMPLE_TEX2D( turbulence_tex, SamplerLinearWrap, 0.5f + uv * 3.6f + float2(0.0f, time * 0.02f) );
		return (muddle_sample.r > lerp(1.0f, 0.6f, fracture_scale)  ? 1.0f : 0.0f) * initial_color.a;
	}*/
	float2 aspect_ratio = float2(item_size.x, item_size.y) / 128.0f;
	
	float4 base_color;
	{
		float4 muddle_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, uv * 1.25f * aspect_ratio + float2(time * 0.0f, 0.0f) );
		base_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv + (muddle_sample.rg - 0.5f) * 0.2f * fracture_scale);
	}
	float4 shrunk_color;
	{
		float4 muddle_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, uv * 2.5f * aspect_ratio + 0.3f + float2(time * 0.0f, 0.0f) );
		shrunk_color = GetShrunkColor(uv + (muddle_sample.rg - 0.5f) / aspect_ratio * 0.8f * fracture_scale, 0.01f );
	}
	return saturate(base_color.a - shrunk_color.a);
}


float4 PShad_Fractured( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	int2 offsets[] = {int2(-1, 0), int2(0, 1), int2(1, 0), int2(0, -1)};
	
	float3 glow_color = 0.0f;
	
	float2 ray_dir = (input.texture_uv.xy - 0.5f);
	
	{	
		float4 muddle_sample = SAMPLE_TEX2D( turbulence_tex, SamplerLinearWrap, input.texture_uv.xy * 0.7f + float2(time * 0.2f, 0.0f));
		float2 displacement = (saturate(muddle_sample.rg) - 0.5f) * 2.0f;
		ray_dir += displacement * 0.1f;
	}
	
	float total_temp = 0.0f;
	
	float total_weight = 0.0f;
	float seed = 0.0f;//rand(input.texture_uv.xy);
	#define step_size 0.1f

	
	float4 res_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, input.texture_uv.xy );
	//res_color.rgb = saturate(res_color.rgb - GetFracturedMask(input.texture_uv.xy, 1.0f));
	/*res_color.rgb /= res_color.a;
	res_color.a = saturate(res_color.a - GetFracturedMask(input.texture_uv.xy, 1.0f));
	res_color.rgb *= res_color.a;*/
	res_color.rgb *= (1.0f - GetFracturedMask(input.texture_uv.xy, 1.0f));

	for(float ray_ratio = seed * step_size; ray_ratio < 1.0f; ray_ratio += step_size)
	{
		/*float2 uv = input.texture_uv.xy - ray_dir / item_size.xy * ray_ratio * 75.0f;
		total_temp += GetFracturedMask(uv, 0.8f) * step_size * 2.0f * saturate(1.0f - ray_ratio) / (item_size.x / 200.0); */
		float scale_factor = 0.8f / (0.3f + item_size.x / 300.0f);
		//float scale_factor = 0.3f / (0.3f);
		float2 uv = input.texture_uv.xy - ray_dir * ray_ratio * 0.4f * scale_factor;
		total_temp += GetFracturedMask(uv, 0.7f) * step_size * 1.5f * saturate(1.0f - ray_ratio); 
	}
	
	//res_color.rgb = GetFracturedMask(input.texture_uv.xy, 1.0f);
	//res_color.rgb += BlackBody(1000.0f + total_temp * 1500.0f).bgr;
	//res_color.rgb += pow(total_temp, 2.2f) * 5.0f * (2300.0f).bgr;
	//res_color.rgb += BlackBody(pow(total_temp, 2.2f) * 2000.0f + 800.0f).bgr;
	//res_color.rgb = pow(total_temp, 2.2f);
	//res_color.rgb = saturate(Vibrance(pow(total_temp, 2.2f), pow(float3(189.0f, 221.0f, 255.0f) / 255.0f, 1.0f / 1.0f), 0.5f)) * 1.0f;
	//total_temp = (input.texture_uv.x > 0.1f) ? total_temp : input.texture_uv.y;
	//float3 color = pow(float3(132, 181, 255) / 255.0f, 2.2f);
	float3 color = pow(float3(169, 194, 232) / 255.0f, 2.2f);
	//float3 color = float3(15, 15, 15) / 255.0f;
	//float3 color = float3(13, 125, 239) / 255.0f;
	//float3 color = float3(1, 9, 17) / 255.0f;
	
	res_color.rgb += saturate(Vibrance(total_temp, color)) * 1.0f;
	//res_color.rgb = GetFracturedMask(input.texture_uv.xy, 0.5f);
	//res_color.rgb = GetFracturedMask(input.texture_uv.xy, 0.8f);
	
	
	//res_color.rgb = saturate(Vibrance(total_temp, pow(float3(0.02f, 0.75f, 0.95f), 2.2f / 1.0f), 0.5f)) * 0.5f;
	//res_color.rgb = pow(saturate(Vibrance(pow(total_temp, 1.0f), pow(color, 1.0f), 0.5f)), 2.2f);
	//res_color.rgb = GetFracturedMask(input.texture_uv.xy, 1.0f);
	//res_color.rgb = saturate(Vibrance(pow(total_temp, 2.2f), pow(color, 2.2f), 0.5f));
	//res_color.rgb = saturate(Vibrance(pow(total_temp, 2.2f), pow(color, 2.2f), 0.5f));
	/*res_color.rgb = saturate(Vibrance(pow(total_temp, 1.0f), pow(color, 2.2f), 0.5f));
	res_color.rgb = saturate(Vibrance(pow(total_temp, 1.0f), pow(color, 2.2f), 0.5f));*/
	//res_color.rgb = pow(saturate(Vibrance(total_temp * 1.0f, pow(color, 2.2f), 0.5f)), 1.0f);
	

	//res_color.rgb = pow(res_color.rgb, 2.2f);
	//res_color.a = 1.0f;
	//res_color.rgb = Vibrance(pow(total_temp, 2.2f), pow(float3(1.0f, 0.5f, 0.0f), 2.2f / 1.0f), 0.5f);
	

	//glow_color += BlackBody(total_temp).bgr;
	
	/*[unroll]
	for(float ray_ratio = seed * step_size; ray_ratio < 1.0f; ray_ratio += step_size)
	{
		float2 uv = input.texture_uv.xy - ray_dir * ray_ratio * 0.3f;

		float4 muddle_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, uv * 0.5f + float2(time * 0.1f, 0.0f) );
		float2 displacement = (pow(saturate(muddle_sample.rg), 1.0f / 2.2f) - 0.5f) * 2.0f;

		
		float4 base_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
		float4 shrunk_color = GetShrunkColor(uv + displacement * 0.05f, 0.03f );
		
		float4 mask_color = base_color;
		mask_color.rgb /= mask_color.a;
		mask_color.a = saturate(mask_color.a - shrunk_color.a);
		mask_color.rgb *= mask_color.a;
		//glow_color += saturate(mask_color.rgb) * step_size * pow(saturate(1.0f - ray_ratio), 2.0f) * 5.0f;
		float temperature = (dot(saturate(mask_color.rgb), float3(1.0f, 1.0f, 1.0f)) * 0.0f + 1.5f) * mask_color.a * 1400.0f * pow(saturate(1.0f - ray_ratio), 1.0f);
		total_temp = max(total_temp, temperature);
	}
	glow_color += BlackBody(total_temp).bgr;*/
	//glow_color += BlackBody(total_temp).bgr;


	
/*[unroll]
	for(float ray_ratio = seed * step_size; ray_ratio < 1.0f; ray_ratio += step_size)
	{
		float2 uv = input.texture_uv.xy + ray_dir * ray_ratio * 0.5f;

		float4 muddle_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, uv * 0.7f + float2(time * 0.1f, 0.0f) );
		float2 displacement = (pow(saturate(muddle_sample.rg), 1.0f / 2.2f) - 0.5f) * 2.0f;

		
		float4 base_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
		float4 shrunk_color = GetShrunkColor(uv + displacement * 0.1f * 0.0f, 0.03f );
		
		float4 mask_color = base_color;
		mask_color.rgb /= mask_color.a;
		mask_color.a = saturate(mask_color.a - shrunk_color.a);
		mask_color.rgb *= mask_color.a;
		//glow_color += saturate(mask_color.rgb) * step_size * pow(saturate(1.0f - ray_ratio), 2.0f) * 5.0f;
		float temperature = (dot(saturate(mask_color.rgb), float3(1.0f, 1.0f, 1.0f)) + 0.9f) * mask_color.a * 1800.0f;
		total_temp += temperature * step_size * pow(saturate(1.0f - ray_ratio), 1.0f) * 3.0f;
	}
	glow_color += BlackBody(total_temp).bgr;*/
	/*[unroll]
	for(float ray_ratio = seed * step_size; ray_ratio < 1.0f; ray_ratio += step_size)
	{
		float2 uv = input.texture_uv.xy - ray_dir * ray_ratio * 0.2f;

		float4 muddle_sample = SAMPLE_TEX2D( muddle_tex, SamplerLinearWrap, uv * 0.3f + float2(time * 0.1f, 0.0f) );
		float2 displacement = (pow(saturate(muddle_sample.rg), 1.0f / 2.2f) - 0.5f) * 2.0f;

		
		float4 base_color = SAMPLE_TEX2D( tex, SamplerLinearWrap, uv );
		float4 shrunk_color = GetShrunkColor(uv + displacement * 0.1f * 0.0f, 0.03f );
		
		float4 mask_color = base_color;
		mask_color.rgb /= mask_color.a;
		mask_color.a = saturate(mask_color.a - shrunk_color.a);
		mask_color.rgb *= mask_color.a;
		glow_color += saturate(mask_color.rgb) * step_size * pow(saturate(1.0f - ray_ratio), 2.0f) * 5.0f;
	}*/
	return res_color;
}

/*float4 Uberblend(float4 col0, float4 col1)
{
	return float4(
		lerp(
		lerp((col0.rgb * col0.a + col1.rgb * col1.a) / (col0.a + col1.a + 1e-2f), (col1.rgb), col1.a),
		lerp((col0.rgb * (1.0 - col1.a) + col1.rgb * col1.a), (col1.rgb), col1.a),
		col0.a),
		min(1.0, 1.0f - (1.0f - col0.a) * (1.0f - col1.a)));
}*/

float4 ComputeLighting(float3 basis_normal, float4 normal_sample, float4 color_sample)
{
	float3 basis_tangent = float3(basis_normal.y, -basis_normal.x, 0.0f);
	float3 basis_bitangent = float3(0.0f, 0.0f, -1.0f);

	float3 local_normal = (normal_sample.rgb - 0.5f) * 2.0f;

	float3 world_normal = basis_tangent * local_normal.x + basis_normal * local_normal.y + basis_bitangent * local_normal.z;

	/*res_color = float4(pow(float3(237.0f, 206.0f, 96.0f) / 255.0f, 2.2f), 1.0f);//color_sample;
	res_color.a = color_sample.a;
	res_color.rgb *= res_color.a;*/

	float4 res_color = color_sample;
	//res_color.rgb *= res_color.a;

	float3 light_dir = normalize(float3(cos(time), sin(time), 0.5f));
	float3 reflected_light = light_dir - world_normal * 2.0f * dot(world_normal, light_dir);

	float3 eye_dir = float3(0.0f, 0.0f, 1.0f);
	float3 reflected_eye = eye_dir - world_normal * 2.0f * dot(world_normal, eye_dir);

	float3 env_color = float3(0.3f, 0.2f, 0.15f) * 0.5f;

	float specular = pow(saturate(dot(-eye_dir, reflected_light)), 2.0f) * 2.0f;
	float diffuse = max(0.0f, dot(-light_dir, world_normal));

	float3 diffuse_color = res_color.rgb;
	float3 specular_color = res_color.rgb * 1.0f;

	float3 light_color = float3(1.0f, 1.0f, 1.0f);
	res_color.rgb = diffuse_color * light_color * (diffuse * 0.1f + 0.1f) + specular_color * (light_color * specular + env_color);
	return res_color;
}

float SigmaFunc(float val, float power)
{
	//return ((1.0f - pow(saturate(1.0f - abs(val - 0.5f) * 2.0f), power)) / 2.0f + 0.5f) * sign(val - 0.5f);
	return atan((val * 2.0f - 1.0f) * power) / /*(3.1415f * 0.5f)*/(atan(power) + 1e-5f) * 0.5f + 0.5f;
}
float4 PShad_Tentacles( const VS_OUTPUT input ) : PIXEL_RETURN_SEMANTIC
{
	float2 tex_coord = input.texture_uv.xy;
	float4 fog_of_war_sample = SAMPLE_TEX2D(mask_tex, SamplerLinearWrap, tex_coord);

	float4 res_color = 0.0f;
	//[branch]
	if(shader_type < 0.5f)
	{

		/*float4 muddle_sample = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, input.texture_uv.xy * muddle_frequency * aspect_ratio + float2(seed, seed * 1.37f));
		muddle_sample.rgb = pow(muddle_sample.rgb, 1.0f / 2.2f);

		tex_coord *= tex_scale.xy;
		float4 influence_sample = SAMPLE_TEX2D(influence_tex, SamplerLinearWrap, tex_coord);
		tex_coord += sin(time + muddle_sample.z * 5.0f) * (muddle_sample.xy - 0.5f) / aspect_ratio * influence_sample.r * muddle_intensity;
		float4 tex_sample = SAMPLE_TEX2D(tex, SamplerLinearWrap, tex_coord);
		if(has_mask > 0.5f)
		{
			tex_sample *= pow(fog_of_war_sample.a, 4.0f);
		}
		return float4(tex_sample.rgb, tex_sample.a);*/

		//tex_coord *= tex_scale.xy;

		float2 offset_coord0;
		GetOffsetCoord(influence_layer_0_tex, SamplerLinearWrap, -1.0f, tex_coord, offset_coord0, muddle_frequency, muddle_intensity, aspect_ratio, tex_scale);
		float2 offset_coord1;
		GetOffsetCoord(influence_layer_1_tex, SamplerLinearWrap, 2.71f, tex_coord, offset_coord1, muddle_frequency, muddle_intensity, aspect_ratio, tex_scale);
		float2 offset_coord2;
		GetOffsetCoord(influence_layer_2_tex, SamplerLinearWrap, 3.14f, tex_coord, offset_coord2, muddle_frequency, muddle_intensity, aspect_ratio, tex_scale);
		float2 offset_coord3;
		GetOffsetCoord(influence_layer_3_tex, SamplerLinearWrap, 42.0f, tex_coord, offset_coord3, muddle_frequency, muddle_intensity, aspect_ratio, tex_scale);

		float4 color_sample0 = SAMPLE_TEX2D(color_layer_0_tex, SamplerLinearWrap, offset_coord0);
		//color_sample0.a *= 0.65f;
		//color_sample0.rgb *= color_sample0.a;
		float4 color_sample1 = SAMPLE_TEX2D(color_layer_1_tex, SamplerLinearWrap, offset_coord1);
		//color_sample1.rgb *= color_sample1.a;
		float4 color_sample2 = SAMPLE_TEX2D(color_layer_2_tex, SamplerLinearWrap, offset_coord2);
		//color_sample2.rgb *= color_sample2.a;
		float4 color_sample3 = SAMPLE_TEX2D(color_layer_3_tex, SamplerLinearWrap, offset_coord3);
		//color_sample3.rgb *= color_sample3.a;

		float4 mask_sample0 = SAMPLE_TEX2D(mask_layer_0_tex, SamplerLinearWrap, offset_coord0);
		float4 mask_sample1 = SAMPLE_TEX2D(mask_layer_1_tex, SamplerLinearWrap, offset_coord1);
		float4 mask_sample2 = SAMPLE_TEX2D(mask_layer_2_tex, SamplerLinearWrap, offset_coord2);
		float4 mask_sample3 = SAMPLE_TEX2D(mask_layer_3_tex, SamplerLinearWrap, offset_coord3);

		float res_opacity = 0.0f;
		res_opacity = lerp(res_opacity, mask_sample0.a, mask_sample0.a);
		res_opacity = lerp(res_opacity, mask_sample1.a, mask_sample1.a);
		res_opacity = lerp(res_opacity, mask_sample2.a, mask_sample2.a);
		res_opacity = lerp(res_opacity, mask_sample3.a, mask_sample3.a);


		res_color = lerp(res_color, color_sample0, mask_sample0.a);
		res_color = lerp(res_color, color_sample1, mask_sample1.a);
		res_color = lerp(res_color, color_sample2, mask_sample2.a);
		res_color = lerp(res_color, color_sample3, mask_sample3.a);

		float4 background_color = SAMPLE_TEX2D(background_tex, SamplerLinearWrap, input.sat_scale_localuv.zw).rgba;
		background_color *= res_opacity;

		//res_color = lerp(background_color, res_color, res_color.a);
		res_color = saturate(background_color * saturate(1.0f - res_color.a) + res_color);

		if(has_mask > 0.5f)
		{
			res_color *= fog_of_war_sample.a;
		}
	}else
	if(shader_type < 1.5f)
	{
		tex_coord *= tex_scale.xy;
		float3 basis_normal = float3(normalize(input.sat_scale_localuv.zw), 0.0f);

		float4 normal_sample = SAMPLE_TEX2D(influence_layer_0_tex, SamplerLinearWrap, tex_coord + layer_0_speed.xy * time);
		float4 color_sample = SAMPLE_TEX2D(color_layer_0_tex, SamplerLinearWrap, tex_coord + layer_0_speed.xy * time);
		float4 layer_0_color = ComputeLighting(basis_normal, normal_sample, color_sample);

		normal_sample = SAMPLE_TEX2D(influence_layer_1_tex, SamplerLinearWrap, tex_coord + layer_1_speed.xy * time);
		color_sample = SAMPLE_TEX2D(color_layer_1_tex, SamplerLinearWrap, tex_coord + layer_1_speed.xy * time);
		float4 layer_1_color = ComputeLighting(basis_normal, normal_sample, color_sample);

		normal_sample = SAMPLE_TEX2D(influence_layer_2_tex, SamplerLinearWrap, tex_coord + layer_2_speed.xy * time);
		color_sample = SAMPLE_TEX2D(color_layer_2_tex, SamplerLinearWrap, tex_coord + layer_2_speed.xy * time);
		float4 layer_2_color = ComputeLighting(basis_normal, normal_sample, color_sample);

		/*normal_sample = SAMPLE_TEX2D(influence_layer_0_tex, SamplerLinearWrap, tex_coord);
		float4 layer_3_color = SAMPLE_TEX2D(color_layer_0_tex, SamplerLinearWrap, tex_coord);*/

		res_color = 0.0f;
		res_color.a = has_mask > 0.5f ? 0.5f : 0.0f;
		
		res_color = lerp(res_color, layer_0_color, layer_0_color.a);
		res_color = lerp(res_color, layer_1_color, layer_1_color.a);
		res_color = lerp(res_color, layer_2_color, layer_2_color.a);

		//res_color = lerp(float4(1.0f, 0.0f, 0.0f, 1.0f), float4(0.0f, 1.0f, 0.0f, 1.0f), frac(tex_coord.x * 10.0f));
		if(has_mask > 0.5f)
		{
			res_color *= pow(fog_of_war_sample.a, 2.0f);
		}		
	}else
	{
		float4 global_distortion_sample = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, tex_coord * aspect_ratio.xy * muddle_frequency);
		float global_phase = frac(time * 0.2f + (global_distortion_sample.a * 1.4f + 0.1f));
		float phase0 = frac(global_phase);
		float phase1 = frac(phase0 + 0.5f);
		float weight0 = 1.0f - abs(phase0 - 0.5f) * 2.0f;
		float weight1 = 1.0f - weight0;

		/*weight0 = 1.0f - pow(saturate(1.0f - weight0), 10.0f);
		weight1 = 1.0f - pow(saturate(1.0f - weight1), 10.0f);*/

		float4 muddle_sample_0 = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, tex_coord * aspect_ratio.xy * muddle_frequency + float2(-0.42f, 0.271f));
		float2 muddle_0 = (muddle_sample_0.xy * 2.0f - 1.0f) / aspect_ratio.xy * muddle_intensity.xy * (phase0 * 3.0f + 1.0f);
		float4 mask_sample_0 = SAMPLE_TEX2D(mask_tex, SamplerLinearWrap, tex_coord + muddle_0 * muddle_intensity.xy);

		float4 muddle_sample_1 = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, tex_coord * aspect_ratio.xy * muddle_frequency + float2(0.3f, 0.2f));
		float2 muddle_1 = (muddle_sample_1.xy * 2.0f - 1.0f) / aspect_ratio.xy * muddle_intensity.xy * (phase1 * 3.0f + 1.0f);
		float4 mask_sample_1 = SAMPLE_TEX2D(mask_tex, SamplerLinearWrap, tex_coord + muddle_1 * muddle_intensity.xy);

		float4 color_sample_0 = SAMPLE_TEX2D(color_layer_0_tex, SamplerLinearWrap, tex_coord * tex_scale.xy + layer_0_speed.xy * time);
		float4 color_sample_1 = SAMPLE_TEX2D(color_layer_1_tex, SamplerLinearWrap, tex_coord * tex_scale.xy + layer_1_speed.xy * time);
		float4 color_sample_2 = SAMPLE_TEX2D(color_layer_2_tex, SamplerLinearWrap, tex_coord * tex_scale.xy + layer_2_speed.xy * time);
		float4 color_sample_3 = SAMPLE_TEX2D(color_layer_3_tex, SamplerLinearWrap, tex_coord * tex_scale.xy + layer_3_speed.xy * time);

		res_color = color_sample_0;
		//res_color = lerp(res_color, color_sample_0, color_sample_0.a);
		res_color = lerp(res_color, color_sample_1, color_sample_1.a);
		res_color = lerp(res_color, color_sample_2, color_sample_2.a);

		/*res_color = 0.0f;
		res_color.a = 1.0f;*/
		float4 mask_sample = weight0 * mask_sample_0 + weight1 * mask_sample_1;
		float val = saturate((mask_sample.a - 0.5f) * 4.0f * 2.0f);
		mask_sample.a = SigmaFunc(mask_sample.a, 300.0f * pow(global_distortion_sample.b, 3.0f)); //2.5f-3.0f

		res_color.a += val * val * (1.0f - val) * (1.0f - val) * 1.0f;
		res_color.a = saturate(res_color.a);
		//res_color.a = 1.0f;

		res_color *= mask_sample.a;
	}
	return float4(res_color.rgb, res_color.a);


	/*float4 muddle_sample = SAMPLE_TEX2D(muddle_tex, SamplerLinearWrap, input.texture_uv.xy * 0.2f + float2(seed, seed * 1.37f));
	float4 influence_sample = SAMPLE_TEX2D(influence_tex, SamplerLinearWrap, tex_coord);

	muddle_sample.rgb = pow(muddle_sample.rgb, 1.0f / 2.2f);
	float4 tex_sample = SAMPLE_TEX2D(tex, SamplerLinearWrap, tex_coord);*/
	//return float4(tex_sample.rgb, tex_sample.a);
}