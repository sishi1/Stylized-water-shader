Shader "Custom/GerstnerWave"
{
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalMap ("Normal map", 2D) = "bump" {}
        _NormalMap2 ("Normal map 2", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AlphaLerp ("Alpha lerp", Range(0,1)) = 0.5

        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
        _WaveB ("Wave B", Vector) = (0, 1, 0.25, 20)
        _WaveC ("Wave C", Vector) = (1, 1, 0.15, 10)

        _TideHeight ("Tide height", float) = 0
        _TideSpeed ("Tide speed", float) = 0

        _OffsetSpeedX ("Speed x offset", Range(0, 10)) = 1
        _OffsetSpeedY ("Speed y offset", Range(0, 10)) = 1
        _Lerp ("Lerp", Range(0,1)) = 0.5

        _WaveSizeMultiplier ("Wave Size Multiplier", Range(0.5, 2)) = 1
        _SpeedAmplifier ("Speed amplifier", float) = 1
    }
    SubShader {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        // Makes transparent things look right by blending them with the background.
        Blend SrcAlpha OneMinusSrcAlpha
        // Allows transparent objects or special effects to be rendered without 
        // affecting the visibility or 'blocking' of other objects based on their depth
        Zwrite Off
        Cull Off
        LOD 100

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow alpha:premul
        //#pragma surface surf Standard // Allows us to use the standard lighting model for shading objects in the shader
        //#pragma fullforwardshadows // Enables the use of shadows when lighting is applied to objects
        //#pragma vertex:vert // Allows for custom control of how the vertices of objects are handled in the shader
        //#pragma addshadow // Incorporates shadow calculations into the shader, so objects can cast and receive shadows
        //#pragma alpha:premul // Adds transparency to the shader by specifying that alpha (transparency) should be treated as premultiplied
        #pragma target 3.0

        sampler2D _NormalMap;
        sampler2D _NormalMap2;

        struct Input {
            float2 uv_NormalMap;
            float2 uv_NormalMap2;

            float2 texCoord : TEXCOORD0;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float4 _WaveA, _WaveB, _WaveC;
        float _TideHeight, _TideSpeed, _OffsetSpeedX, _OffsetSpeedY, _Lerp, 
        _WaveSizeMultiplier, _SpeedAmplifier, _AlphaLerp;

        float3 GerstnerWave(float4 wave, float3 gridPoint, inout float3 tangent, inout float3 binormal) 
        {
            float steepness = wave.z;
            float wavelength = wave.w;
            float angularWaveNumber  = 2 * UNITY_PI / wavelength;
            float speed = sqrt(9.8 / angularWaveNumber );
            float2 waveNormalized = normalize(wave.xy);
            float wavePosition = angularWaveNumber  * (dot(waveNormalized, gridPoint.xz) - speed * _Time.y * _SpeedAmplifier);
            float amplitude = steepness / angularWaveNumber ;

            tangent += float3(
                -waveNormalized.x * waveNormalized.x * (steepness * sin(wavePosition)), 
                waveNormalized.x * (steepness * cos(wavePosition)),
                -waveNormalized.x * waveNormalized.y * (steepness * sin(wavePosition))
            );

            binormal += float3(
                -waveNormalized.x * waveNormalized.y * (steepness * sin(wavePosition)),
                waveNormalized.y * (steepness * cos(wavePosition)),
                -waveNormalized.y * waveNormalized.y * (steepness * sin(wavePosition))
            );
            
            return float3(
                waveNormalized.x * (amplitude * cos(wavePosition)),
                amplitude * sin(wavePosition),
                waveNormalized.y * (amplitude * cos(wavePosition))
            );
        }

        void vert(inout appdata_full vertexData) {
            float3 gridPoint = vertexData.vertex.xyz;
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);
            float3 gPoint = gridPoint;

            float steepnessA = _WaveA.z * _WaveSizeMultiplier;
            float steepnessB = _WaveB.z * _WaveSizeMultiplier;
            float steepnessC = _WaveC.z * _WaveSizeMultiplier;

            float4 waveA = float4(_WaveA.x, _WaveA.y, steepnessA, _WaveA.w);
            float4 waveB = float4(_WaveB.x, _WaveB.y, steepnessB, _WaveB.w);
            float4 waveC = float4(_WaveC.x, _WaveC.y, steepnessC, _WaveC.w);

            gPoint += GerstnerWave(waveA, gridPoint, tangent, binormal);
            gPoint += GerstnerWave(waveB, gridPoint, tangent, binormal);
            gPoint += GerstnerWave(waveC, gridPoint, tangent, binormal);

            float3 normal = normalize(cross(binormal, tangent));

            vertexData.vertex.xyz = gPoint;
            vertexData.normal = normal;
        }

        // Calulcating a new blended normal map and alpha
        half4 blendNormalsHeight(half4 sample1, half4 sample2) {
            sample1.rgb = sample1.rgb * 2 - 1;
            sample2.rgb = sample2.rgb * 2 - 1;
            half blendFactor = (sample1.a + sample2.a) * 0.5;
            half3 blendedNormal = normalize(lerp(sample1.rgb, sample2.rgb, blendFactor));
            half blendedAlpha = lerp(sample1.a, sample2.a, _AlphaLerp);
            return half4(blendedNormal * 0.5 + 0.5, blendedAlpha);
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            float2 uvNormal = IN.uv_NormalMap;
            float2 uvNormal2 = IN.uv_NormalMap2;

            // Calculate the x and y offsets separately
            float2 offsetX = float2(_Time.x * _OffsetSpeedX, 0);
            float2 offsetY = float2(0, _Time.y * _OffsetSpeedY);

            // Apply the offsets to the texture coordinates
            float2 uvX = frac(uvNormal + offsetX);
            float2 uvY = frac(uvNormal2 - offsetY);

            // Sample the normal map twice using the modified offsets
            float4 sampleX = tex2D(_NormalMap, uvX);
            float4 sampleY = tex2D(_NormalMap2, uvY);

            // Blend the two normal map samples using the lerp function
            half4 blendedNormal = blendNormalsHeight(sampleX, sampleY);
            o.Albedo = _Color;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = blendedNormal.a;
            //o.Normal = blendedNormal * 2 - 1;
            o.Normal = UnpackNormal(blendedNormal);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
