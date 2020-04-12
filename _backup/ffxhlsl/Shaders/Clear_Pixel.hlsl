//PRECOMPILE ps_4_0 main
//PRECOMPILE ps_gnm main
//PRECOMPILE ps_vkn main


CBUFFER_BEGIN( pix_clear_constants )
	float4 m_color;
CBUFFER_END


float4 main() : PIXEL_RETURN_SEMANTIC
{
	return m_color;
}
