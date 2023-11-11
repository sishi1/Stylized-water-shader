Shader "Custom/UnlitWater"
{
    Properties
    {	
        [NoScaleOffset] _NormalMap ("Normal map", 2D) = "bump" {}
        [NoScaleOffset] _NormalMap2 ("Normal map 2", 2D) = "bump" {}
        _Smoothness ("Smoothness", Range(0,1)) = 1
        _MapsIntensity ("Normal maps intensity", Range(0, 1)) = 0.5
        _AlphaLerp ("Alpha lerp", Range(0, 1)) = 0.5

        _TideHeight ("Tide height", float) = 0
        _TideSpeed ("Tide speed", float) = 0

        _ScrollSpeed1 ("Speed1", Range(0, 1)) = 1
        _ScrollSpeed2 ("Speed2", Range(0, 1)) = 1

		_DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _ShallowColorIntensity ("Shallow color intensity", Range(0, 1)) = 0.5
		_DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _WaterColorIntensity ("Water color intensity", Range(0, 0.2)) = 0.05
		_DepthMaxDistance("Depth Maximum Distance", Float) = 1

        [NoScaleOffset] _CubeMap ("Cube map", Cube) = "white" {}

        [HideInInspector]_ReflectionTexture ("Reflection texture", 2D) = "white" {}
        _FresnelStrength ("Fresnel strength", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        // The base pass is automatically a directional light
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;

                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;

                float3 normal : TEXCOORD6;
                float3 tangent : TEXCOORD7;
                float3 bitangent : TEXCOORD8;
                float3 worldPosition : TEXCOORD9;

                float2 uvNormal : TEXCOORD2; 
                float2 uvNormal2 : TEXCOORD3; 
                float2 uv : TEXCOORD4;
                float2 uv2 : TEXCOORD5;

                float3 worldNormal : TEXCOORD10;
            };

            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            sampler2D _NormalMap2;
            float4 _NormalMap2_ST;
            sampler2D _NormalHeight;

            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;
            samplerCUBE _CubeMap;
            sampler2D _ReflectionTexture;

            float _TideHeight, _TideSpeed, _ScrollSpeed1, _ScrollSpeed2, _MapsIntensity, _AlphaLerp, _DepthMaxDistance,
            _Smoothness, _BumpScale, _WaterColorIntensity, _ShallowColorIntensity, _FresnelStrength;

            float4 _DepthGradientShallow, _DepthGradientDeep, _FoamColor; 

            v2f vert (appdata v)
            {
                v2f o;
                o.uvNormal = v.uv;
                o.uvNormal2 = v.uv;

                o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
                o.uv2 = v.uv;

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.tangent = UnityObjectToWorldDir(v.tangent.xyz); 
                o.bitangent = cross (o.normal, o.tangent); 
                o.bitangent *= v.tangent.w * unity_WorldTransformParams.w; // Correctly handle flipping/mirroring

                v.vertex.y += _TideHeight * sin(_Time.y * _TideSpeed);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 BlendScrollingMaps(v2f i) {
                float2 scrollingUV1 = i.uvNormal - _Time.x * _ScrollSpeed1;
                float2 scrollingUV2 = i.uvNormal2 - _Time.y * _ScrollSpeed2;

                float3 normal1 = UnpackNormal(tex2D(_NormalMap, scrollingUV1));
                float3 normal2 = UnpackNormal(tex2D(_NormalMap2, scrollingUV2));

                float3 blendedNormal = (normal1 + normal2);
                return fixed4(blendedNormal * 0.5 + 0.5, 1);
            }

            float3 CalculateWorldSpaceNormal(v2f i) {
                 float3 tangentSpaceNormal = BlendScrollingMaps(i);
                tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _MapsIntensity));

                float3x3 mtxTangToWorld = 
                {
                     i.tangent.x, i.bitangent.x, i.normal.x,
                     i.tangent.y, i.bitangent.y, i.normal.y,
                     i.tangent.z, i.bitangent.z, i.normal.z,
                 };

                return mul(mtxTangToWorld, tangentSpaceNormal);
            }

            float4 CalculateWaterAppearance(v2f i) {
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);

                float depthDifference = existingDepthLinear - i.screenPosition.w;

                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow + _ShallowColorIntensity, _DepthGradientDeep, waterDepthDifference01);
                
                return waterColor + float4(CalculateWorldSpaceNormal(i), 1) * _WaterColorIntensity;
            }

            float4 CustomLighting(v2f i) {
                float3 worldSpaceNormal = CalculateWorldSpaceNormal(i);

                float3 lightVector = _WorldSpaceLightPos0.xyz; // Actually a direction
                float3 viewVector = normalize(_WorldSpaceCameraPos - i.worldPosition);
                float3 reflectedVector = reflect(-lightVector, worldSpaceNormal);
                float3 halfVector = normalize(lightVector + viewVector);
                float3 lambertian = saturate(dot(worldSpaceNormal, lightVector));

                float3 diffuseLight = lambertian * _LightColor0.xyz;
                float3 specularLightPhong = saturate(dot(viewVector, reflectedVector)); // Phong lighting
                float3 specularLightBlinnPhong = saturate(dot(halfVector, worldSpaceNormal)) * (lambertian > 0); // Blinn-Phong lighting

                float3 reflectionVector = reflect(-viewVector, worldSpaceNormal);
                float4 cubeMap = texCUBE(_CubeMap, reflectionVector);
                float3 reflection = tex2D(_ReflectionTexture, reflectionVector);

                float fresnel = dot(viewVector, worldSpaceNormal);
                fresnel = pow(1 - fresnel, 3) * _FresnelStrength;
                
                float specularExponent = exp2(_Smoothness * 11) + 2; 
                // Generally don't want to use math functions in shader script. Later on maybe in a normal script and pass results here
                specularLightBlinnPhong = pow(specularLightBlinnPhong, specularExponent);
                specularLightBlinnPhong *= _LightColor0.xyz;

                return float4 (cubeMap + diffuseLight + specularLightBlinnPhong + (_LightColor0.xyz * fresnel), _AlphaLerp);
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float4 waterAppearance = CalculateWaterAppearance(i);

                return CustomLighting(i) * waterAppearance;
            }
            ENDCG
        }
    }
}