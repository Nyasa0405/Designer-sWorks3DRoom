void ActiveNormalmap_float(in float4 MainColor, in tex2D texture2d)
{
    // プロパティ
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

            // 関数を指定
            #pragma vertex vert
            #pragma fragment frag
            // フォグ用のシェーダバリアントを生成する
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

            // 変数定義
float4 _MainColor;

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
float4 _MainTex_ST;
	    
	    TEXTURE2D(_NormalMap);
	    SAMPLER(sampler_NormalMap);
float4 _NormalMap_ST;
float _NormalStrength;

            // 頂点シェーダー
Varyings vert(Attributes IN)
{
    Varyings OUT;
                
                // TransformObjectToHClip()で頂点位置をオブジェクト空間からクリップスペースへ変換
                // UnityObjectToClipPos()がTransformObjectToHClip()になった
    OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // TRANSFORM_TEX()マクロでタイリングなどを計算する
    OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                // fog factor の計算
    OUT.fogFactor = ComputeFogFactor(IN.positionOS.z);

                // オブジェクト空間のノーマルはそのままVaryingsのnormalOSに格納
    OUT.normalOS = IN.normalOS;
                // TransformObjectToWorldNormal()でノーマルをオブジェクト空間からワールド空間へ変換して格納
    OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                // サイン（正弦）とワールド空間のタンジェントの計算
    float sign = IN.tangentOS.w * GetOddNegativeScale();
    VertexNormalInputs vni = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    OUT.tangentWS = float4(vni.tangentWS, sign);

    return OUT;
}

            // フラグメントシェーダー
float4 frag(Varyings IN) : SV_Target
{
                // テクスチャをサンプリングして、カラーを乗算する
    float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _MainColor;
    
                // Fogを適用する
    color.rgb = MixFog(color.rgb, IN.fogFactor);

                // MainLightの取得
    Light mainLight = GetMainLight();

                // ノーマルマップをサンプリング（タンジェント空間）
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv), _NormalStrength);
                // vert()で算出したサイン（正弦）
    float sgn = IN.tangentWS.w;
                // 従法線（bitangent / binormal）を計算
    float3 bitangent = sgn * cross(IN.normalWS.xyz, IN.tangentWS.xyz);
                // タンジェント空間からワールド空間へ変換
                // normalize()（正規化）も同時にしておく
    float3 normalWS = normalize(mul(normalTS, float3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normalWS.xyz)));

                // ノーマル（法線）とライト方向の内積
                // saturate()で 0 ~ 1 に固定
    float NdotL = saturate(dot(normalWS, mainLight.direction));
    float lightIntensity = saturate(smoothstep(0.005, 0.01, NdotL));
    
    return float4(color.rgb * mainLight.color.rgb * lightIntensity, 1);
}

            ENDHLSL
        }
    }
}