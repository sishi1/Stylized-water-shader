Shader "Custom/Water"
{
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalMap ("Normal map", 2D) = "bump" {}
        _NormalMap2 ("Normal map 2", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _TideHeight ("Tide height", float) = 0
        _TideSpeed ("Tide speed", float) = 0

        _OffsetSpeedX ("Speed x offset", Range(0, 10)) = 1
        _OffsetSpeedY ("Speed y offset", Range(0, 10)) = 1

        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", float) = 1
    }
    SubShader {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Zwrite Off
        Cull Off
        LOD 100

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow alpha
        #pragma target 3.0
        #pragma enable_d3d11_debug_symbols

        sampler2D _NormalMap;
        sampler2D _NormalMap2;
        sampler2D _CameraDepthTexture;

        struct Input {
            float2 uv_NormalMap;
            float2 uv_NormalMap2;

            float4 vertex : SV_POSITION;
            float4 screenPosition : TEXCOORD2;
        };

        half _Glossiness, _Metallic;
        fixed4 _Color, _DepthGradientShallow, _DepthGradientDeep;
        float _TideHeight, _TideSpeed, _OffsetSpeedX, _OffsetSpeedY, _DepthMaxDistance;

        Input vert(inout appdata_full vertexData) {
            Input IN;

            float3 gridPoint = vertexData.vertex.xyz;

            float tideOffset = _TideHeight * sin(_Time.y * _TideSpeed);
            gridPoint.y += tideOffset;

            vertexData.vertex.xyz = gridPoint;

            //IN.vertex = UnityObjectToClipPos(vertexData.vertex);
            IN.screenPosition = ComputeScreenPos(vertexData.vertex);
            return IN;
        }

        float3 AnimateNormalMaps(Input IN) {
            float2 uvNormal = IN.uv_NormalMap;
            float2 uvNormal2 = IN.uv_NormalMap2;

            // Calculate the x and y offsets separately
            float2 offsetX = float2(_Time.x * _OffsetSpeedX, 0);
            float2 offsetY = float2(0, _Time.y * _OffsetSpeedY);

            // Apply the offsets to the texture coordinates
            float2 uvX = frac(uvNormal + offsetX);
            float2 uvY = frac(uvNormal2 + offsetY);

            // Sample the normal maps
            float4 sampleX = tex2D(_NormalMap, uvX);
            float4 sampleY = tex2D(_NormalMap2, uvY);

            // Unpack and normalize the normal vectors
            float3 normalX = UnpackNormal(sampleX); 
            float3 normalY = UnpackNormal(sampleY); 

            // Blend the normal vectors
            return normalize(normalX + normalY) * 0.5 + 0.5;
        }

        float getDepthDifference(Input IN)
        {
            // Calculate depth and depth difference
            float existingDepth01 = tex2Dproj(_CameraDepthTexture, IN.screenPosition).r;
            float existingDepthLinear = LinearEyeDepth(existingDepth01);
                 
            return existingDepthLinear - IN.screenPosition.y;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            float3 blendedNormal = AnimateNormalMaps(IN);

            //float depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, IN.screenPosition);
            //float depth = LinearEyeDepth(depthSample).r;

            float depthDifference = getDepthDifference(IN);

            // Map depth difference to a [0, 1] range
            float depthDifference01 = saturate(depthDifference / _DepthMaxDistance);

            // Calculate blended water color based on depth difference
            float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, depthDifference01);

            o.Albedo = waterColor.rgb;
            o.Alpha = waterColor.a;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Normal = blendedNormal * 2 - 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
