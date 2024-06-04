void ActiveNormalmap_float(in float4 MainColor, in tex2D texture2d)
{
    // �v���p�e�B
    Properties {
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalStrength("Normal Strength", Range(0, 8)) = 1
    }

    SubShader {

        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

LOD100

        Pass {
            HLSLPROGRAM

            // �֐����w��
            #pragma vertex vert
            #pragma fragment frag
            // �t�H�O�p�̃V�F�[�_�o���A���g�𐶐�����
            #pragma multi_compile_fog

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float fogFactor : TEXCOORD1;
    float3 normalOS : NORMAL;
    float3 normalWS : NORMAL_WS;
    float4 tangentWS : TANGENT_WS;
};

            // �ϐ���`
float4 _MainColor;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
float4 _MainTex_ST;
	    
	    TEXTURE2D(_NormalMap);
	    SAMPLER(sampler_NormalMap);
float4 _NormalMap_ST;
float _NormalStrength;

            // ���_�V�F�[�_�[
Varyings vert(Attributes IN)
{
    Varyings OUT;
                
                // TransformObjectToHClip()�Œ��_�ʒu���I�u�W�F�N�g��Ԃ���N���b�v�X�y�[�X�֕ϊ�
                // UnityObjectToClipPos()��TransformObjectToHClip()�ɂȂ���
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // TRANSFORM_TEX()�}�N���Ń^�C�����O�Ȃǂ��v�Z����
    OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                // fog factor �̌v�Z
    OUT.fogFactor = ComputeFogFactor(IN.positionOS.z);

                // �I�u�W�F�N�g��Ԃ̃m�[�}���͂��̂܂�Varyings��normalOS�Ɋi�[
    OUT.normalOS = IN.normalOS;
                // TransformObjectToWorldNormal()�Ńm�[�}�����I�u�W�F�N�g��Ԃ��烏�[���h��Ԃ֕ϊ����Ċi�[
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                // �T�C���i�����j�ƃ��[���h��Ԃ̃^���W�F���g�̌v�Z
    float sign = IN.tangentOS.w * GetOddNegativeScale();
    VertexNormalInputs vni = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    OUT.tangentWS = float4(vni.tangentWS, sign);

    return OUT;
}

            // �t���O�����g�V�F�[�_�[
float4 frag(Varyings IN) : SV_Target
{
                // �e�N�X�`�����T���v�����O���āA�J���[����Z����
    float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _MainColor;
    
                // Fog��K�p����
    color.rgb = MixFog(color.rgb, IN.fogFactor);

                // MainLight�̎擾
    Light mainLight = GetMainLight();

                // �m�[�}���}�b�v���T���v�����O�i�^���W�F���g��ԁj
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv), _NormalStrength);
                // vert()�ŎZ�o�����T�C���i�����j
    float sgn = IN.tangentWS.w;
                // �]�@���ibitangent / binormal�j���v�Z
    float3 bitangent = sgn * cross(IN.normalWS.xyz, IN.tangentWS.xyz);
                // �^���W�F���g��Ԃ��烏�[���h��Ԃ֕ϊ�
                // normalize()�i���K���j�������ɂ��Ă���
    float3 normalWS = normalize(mul(normalTS, float3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normalWS.xyz)));

                // �m�[�}���i�@���j�ƃ��C�g�����̓���
                // saturate()�� 0 ~ 1 �ɌŒ�
    float NdotL = saturate(dot(normalWS, mainLight.direction));
    float lightIntensity = saturate(smoothstep(0.005, 0.01, NdotL));
    
    return float4(color.rgb * mainLight.color.rgb * lightIntensity, 1);
}

            ENDHLSL
        }
    }
}