TEXTURECUBE_DECL( specular_cube );
TEXTURECUBE_DECL( diffuse_cube );
TEXTURE2D_DECL( environment_ggx_sampler );

float GetPrefilterMip(float glossiness)
{
	float phy = -10.0 / ( log2( saturate(glossiness) * 0.968 + .03 ) );
	float specPower = phy * phy;
	
	float glossBias = 1.0f;
	float glossScale = 15.0f;
	
	float cmftGlossiness = log2( specPower );
	//float cmftGlossiness = mipRatio * glossCale + glossBias;
	float mipRatio = (cmftGlossiness - glossBias) / glossScale;
	//mipRatio = 1.0f - mipLevel / mipsCount
	float mipsCount = 8.0f;
	float mipLevel = min(7.0f, (1.0f - mipRatio) * mipsCount); //min because 1x1 mip's discretization error is too great
	return mipLevel;
}

float3 GetPrefilterGGX(float NdotV, float glossiness, float3 specular_color)
{
	float2 lookup_coord = float2(NdotV, glossiness);
	float2 lookup_sample = SAMPLE_TEX2DLOD(environment_ggx_sampler, SamplerLinearClamp, float4(lookup_coord, 0.0f, 0.0f)).rg;
	return lookup_sample.r + lookup_sample.g * specular_color;
}

float4 GetGGXPrefilteredLight(float3 view_dir, float3 surface_normal, float glossiness, float3 specular_color, uniform TEXTURECUBE_DECL(spec_cubemap_tex), float3x3 env_transform)
{
	//include env_mapping_verification

	float3 reflected_dir = view_dir - 2.0f * surface_normal * dot(view_dir, surface_normal);
	float3 lookup_dir = mul(reflected_dir, env_transform);

	float NdotV = dot(surface_normal, -view_dir);
	float3 brdf_contribution = GetPrefilterGGX(abs(NdotV), glossiness, specular_color);
	
	float mip_level = GetPrefilterMip(glossiness);
	float3 skybox_contribution = SAMPLE_TEXCUBELOD(spec_cubemap_tex, SamplerLinearClamp, float4(lookup_dir, mip_level)).rgb;
	
	return float4(brdf_contribution * skybox_contribution, saturate(dot(brdf_contribution, 1.0f) / 3.0f));
}

float3 GetEnvDiffuseLight(float3 bent_normal, uniform TEXTURECUBE_DECL(diffuse_cubemap_tex), float3x3 env_transform)
{
	float3 lookup_dir = mul(bent_normal, env_transform);
	return SAMPLE_TEXCUBE( diffuse_cubemap_tex, SamplerLinearClamp, lookup_dir).rgb;
}


float Fresnel(float VdotH)
{
	return exp2( (-5.55473 * VdotH - 6.98316) * VdotH );
}

float GlossinessToRoughness(float glossiness)
{
	return saturate(1.0f - glossiness);
}

float GeometryOcclusionSmithTerm(float alpha, float VdotN, float LdotN) // * VdotN * LdotN
{
	//geometric term
	float k = alpha * 0.5;
	float G_SmithI = (VdotN * (1.0 - k) + k);
	float G_SmithO = (LdotN * (1.0 - k) + k);
	return 1.0f / ( G_SmithI * G_SmithO );
}

float3 FresnelTerm(float VdotH, float3 specular_color)
{
	float3 fresnel_amount = Fresnel(VdotH);
	return lerp(fresnel_amount, float3(1.0f, 1.0f, 1.0f), specular_color);
}

float GGXMicrofacetDistribution(float NdotH, float alpha2) // / pi
{
	return alpha2 / pow(( alpha2 - 1.0f ) * NdotH * NdotH + 1.0f, 2.0f);
}

//GGX specular is from here : https://www.graphics.cornell.edu/~bjw/microfacetbsdf.pdf
// "Microfacet Models for Refraction through Rough Surfaces Bruce Walter et al"
float3 GGXSpecular(float3 light_dir, float3 surface_normal, float3 view_dir, float glossiness, float3 specular_color)
{
	float roughness = GlossinessToRoughness(glossiness);
	float alpha = max( roughness * roughness, 2e-3 ); // \alpha_g
	float alpha2 = alpha * alpha; // {\alpha_g}^2

	float3 I = -view_dir; //in vector //same as V
	float3 O = light_dir; //out vector //same as L
	float3 H = normalize(I + O); //half vector
	float3 N = surface_normal; //macro normal
	float NdotH = saturate(dot(N,H));
	float OdotN = saturate(dot(O,N)); //LdotH
	float IdotN = saturate(dot(I,N)); //VdotN
	float IdotH = saturate(dot(I,H)); //VdotH

	float3 incident_light = OdotN;

	const float pi = 3.141592f;

	float D = GGXMicrofacetDistribution(NdotH, alpha2)/*/ pi*/;
	float G = GeometryOcclusionSmithTerm(alpha, IdotN, OdotN) /* * IdotN * OdotN*/;
	float3 F = FresnelTerm(IdotH, specular_color);
	
	//comments are eliminated terms
	float3 res = D * F * G * OdotN / (4.0f /* * IdotN * OdotN*/)/* * pi*/;

	return res;
}

float3x3 GetCubemapTransform(float hor_ang, float vert_ang)
{
	//float hor_ang = 1.5f;// + 4.0f;
	//float vert_ang = 0.2f;// - 1.0f;
	float3x3 hor_transform = float3x3(
		cos(hor_ang), 0.0f, sin(hor_ang),
		0.0f, 1.0f, 0.0f,
		-sin(hor_ang), 0.0f, cos(hor_ang));
		
	float3x3 vert_transform = float3x3(
		1.0f, 0.0f, 0.0f,
		0.0f, cos(vert_ang), -sin(vert_ang),
		0.0f, sin(vert_ang), cos(vert_ang));
		

	return mul(vert_transform, hor_transform);
}
