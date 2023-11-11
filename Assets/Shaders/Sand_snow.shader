// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "KumaBeer/Sand_snow"
{
	Properties
	{
		_Diffuse("Diffuse", 2D) = "white" {}
		_MainNormalmap("Main Normalmap", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1,1)
		[HDR]_Shadowcolor("Shadow color", Color) = (0.3921569,0.454902,0.5568628,1)
		_Main_Tile("Main_Tile", Float) = 0.15
		_Normalmapscale("Normalmap scale", Float) = 1
		[HDR]_RimColor("Rim Color", Color) = (1,1,1,0)
		_RimStr("Rim Str", Range( 0.01 , 1)) = 0.4
		_Rimoffset("Rim offset", Range( 0 , 1)) = 0.6
		_IndirectDiffuseContribution("Indirect Diffuse Contribution", Range( 0 , 1)) = 1
		_BaseCellSharpness("Base Cell Sharpness", Range( 0.01 , 1)) = 0.01
		_BaseCellOffset("Base Cell Offset", Range( -1 , 1)) = 0
		_Sandnoise("Sand noise", 2D) = "gray" {}
		_SandnoiseTile("Sand noise Tile", Float) = 2.65
		_NoiseRimBlend("Noise Rim Blend", Float) = 0.8
		_NoiseRimStr("Noise Rim Str", Float) = 20
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		ColorMask RGB
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
		#define ASE_USING_SAMPLING_MACROS 1
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
		#else//ASE Sampling Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
		#endif//ASE Sampling Macros

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float4 screenPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		UNITY_DECLARE_TEX2D_NOSAMPLER(_MainNormalmap);
		SamplerState sampler_MainNormalmap;
		uniform float _Main_Tile;
		uniform float _Normalmapscale;
		uniform float _Rimoffset;
		uniform float _RimStr;
		uniform float _NoiseRimStr;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Sandnoise);
		SamplerState sampler_Sandnoise;
		uniform float _SandnoiseTile;
		uniform float _NoiseRimBlend;
		uniform float4 _RimColor;
		uniform float _IndirectDiffuseContribution;
		uniform float _BaseCellOffset;
		uniform float _BaseCellSharpness;
		uniform float4 _Shadowcolor;
		uniform float4 _MainColor;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Diffuse);
		SamplerState sampler_Diffuse;


		inline float3 TriplanarSampling186( UNITY_DECLARE_TEX2D_NOSAMPLER(topTexMap), SamplerState samplertopTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			xNorm.xyz  = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2(  nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz  = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2(  nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz  = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
		}


		inline float4 TriplanarSampling177( UNITY_DECLARE_TEX2D_NOSAMPLER(topTexMap), SamplerState samplertopTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		inline float4 TriplanarSampling185( UNITY_DECLARE_TEX2D_NOSAMPLER(topTexMap), SamplerState samplertopTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = SAMPLE_TEXTURE2D( topTexMap, samplertopTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float LightType125 = _WorldSpaceLightPos0.w;
			float3 temp_cast_3 = (1.0).xxx;
			float2 temp_cast_4 = (_Main_Tile).xx;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 triplanar186 = TriplanarSampling186( _MainNormalmap, sampler_MainNormalmap, ase_worldPos, ase_worldNormal, 1.0, temp_cast_4, _Normalmapscale, 0 );
			float3 tanTriplanarNormal186 = mul( ase_worldToTangent, triplanar186 );
			float3 WSNormal31 = normalize( (WorldNormalVector( i , tanTriplanarNormal186 )) );
			UnityGI gi72 = gi;
			float3 diffNorm72 = WSNormal31;
			gi72 = UnityGI_Base( data, 1, diffNorm72 );
			float3 indirectDiffuse72 = gi72.indirect.diffuse + diffNorm72 * 0.0001;
			float3 lerpResult90 = lerp( temp_cast_3 , indirectDiffuse72 , _IndirectDiffuseContribution);
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult34 = dot( WSNormal31 , ase_worldlightDir );
			float NdotL36 = dotResult34;
			float4 triplanar177 = TriplanarSampling177( _Sandnoise, sampler_Sandnoise, ase_worldPos, ase_worldNormal, 8.0, _SandnoiseTile, 1.0, 0 );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float dotResult200 = dot( float4( ase_worldlightDir , 0.0 ) , ase_screenPosNorm );
			float lerpResult203 = lerp( triplanar177.x , 0.0 , dotResult200);
			float temp_output_194_0 = saturate( lerpResult203 );
			float3 temp_output_134_0 = ( lerpResult90 + saturate( ( ( NdotL36 + _BaseCellOffset + temp_output_194_0 ) / _BaseCellSharpness ) ) );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 Lightcolor93 = ase_lightColor;
			float4 lerpResult140 = lerp( _Shadowcolor , float4( 1,1,1,0 ) , ( ase_lightAtten * float4( temp_output_134_0 , 0.0 ) * Lightcolor93 ));
			float4 ifLocalVar142 = 0;
			if( LightType125 == 1.0 )
				ifLocalVar142 = ( ase_lightAtten * float4( temp_output_134_0 , 0.0 ) * Lightcolor93 );
			else if( LightType125 < 1.0 )
				ifLocalVar142 = lerpResult140;
			float2 temp_cast_8 = (_Main_Tile).xx;
			float4 triplanar185 = TriplanarSampling185( _Diffuse, sampler_Diffuse, ase_worldPos, ase_worldNormal, 1.0, temp_cast_8, 1.0, 0 );
			c.rgb = ( ifLocalVar142 * ( _MainColor * triplanar185 ) ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
			float2 temp_cast_0 = (_Main_Tile).xx;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 triplanar186 = TriplanarSampling186( _MainNormalmap, sampler_MainNormalmap, ase_worldPos, ase_worldNormal, 1.0, temp_cast_0, _Normalmapscale, 0 );
			float3 tanTriplanarNormal186 = mul( ase_worldToTangent, triplanar186 );
			float3 WSNormal31 = normalize( (WorldNormalVector( i , tanTriplanarNormal186 )) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult34 = dot( WSNormal31 , ase_worldlightDir );
			float NdotL36 = dotResult34;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult49 = dot( WSNormal31 , ase_worldViewDir );
			float saferPower88 = max( ( 1.0 - ( dotResult49 + _Rimoffset ) ) , 0.0001 );
			float temp_output_105_0 = ( NdotL36 * pow( saferPower88 , _RimStr ) );
			float4 triplanar177 = TriplanarSampling177( _Sandnoise, sampler_Sandnoise, ase_worldPos, ase_worldNormal, 8.0, _SandnoiseTile, 1.0, 0 );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float dotResult200 = dot( float4( ase_worldlightDir , 0.0 ) , ase_screenPosNorm );
			float lerpResult203 = lerp( triplanar177.x , 0.0 , dotResult200);
			float temp_output_194_0 = saturate( lerpResult203 );
			float lerpResult199 = lerp( 0.0 , _NoiseRimStr , temp_output_194_0);
			float lerpResult214 = lerp( ( temp_output_105_0 * lerpResult199 ) , temp_output_105_0 , _NoiseRimBlend);
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 Lightcolor93 = ase_lightColor;
			o.Emission = ( saturate( lerpResult214 ) * _RimColor * Lightcolor93 ).rgb;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 screenPos : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
454;546;1297;592;11492.44;-2318.69;1.667074;True;True
Node;AmplifyShaderEditor.CommentaryNode;5;-9873.999,2074.875;Inherit;False;1163.388;554.3827;Diffuse&Normal;8;115;108;31;28;186;17;23;185;Main;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-9817.337,2519.364;Inherit;False;Property;_Normalmapscale;Normalmap scale;5;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-9819.957,2386.199;Inherit;False;Property;_Main_Tile;Main_Tile;4;0;Create;True;0;0;0;False;0;False;0.15;0.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;186;-9504.119,2420.953;Inherit;True;Spherical;World;True;Main Normalmap;_MainNormalmap;white;1;None;Mid Texture 1;_MidTexture1;white;-1;None;Bot Texture 1;_BotTexture1;white;-1;None;Main Normalmap;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;28;-9097.102,2421.165;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;30;-12003.67,2210.233;Inherit;False;852.9001;307.4;NdotL;4;36;34;32;149;NdotL;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;31;-8920.21,2416.061;Inherit;False;WSNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;32;-11969.12,2258.423;Inherit;False;31;WSNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;149;-11972.17,2341.046;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ScreenPosInputsNode;201;-12362.51,3083.969;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;178;-12386.76,2961.268;Float;False;Property;_SandnoiseTile;Sand noise Tile;13;0;Create;True;0;0;0;False;0;False;2.65;2.65;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;177;-12141.52,2919.935;Inherit;True;Spherical;World;False;Sand noise;_Sandnoise;gray;12;None;Mid Texture 3;_MidTexture3;white;-1;None;Bot Texture 3;_BotTexture3;white;-1;None;Sand noise;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;8;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;200;-11732.88,3065.365;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;34;-11662.88,2278.222;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;35;-11027.86,3421.185;Inherit;False;1945.774;673.4066;Rimlight;17;105;88;76;81;144;106;85;59;49;47;42;41;195;175;215;214;208;Rimlight;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;37;-11000.16,2791.446;Inherit;False;2315.376;481.6804;Shadows;15;62;142;141;140;139;138;137;134;55;46;52;39;44;176;135;Shadows;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;-11372.27,2277.605;Float;True;NdotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;203;-11344.24,2626.099;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;42;-10946,3744.711;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;41;-10993.04,3633.503;Inherit;False;31;WSNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-10982.48,3042.583;Float;False;Property;_BaseCellOffset;Base Cell Offset;11;0;Create;True;0;0;0;False;0;False;0;-0.35;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;194;-10915.64,2628.441;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-10965.7,2849.535;Inherit;True;36;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;49;-10640.9,3679.82;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;60;-10891.29,2195.432;Inherit;False;828.4254;361.0605;Comment;5;90;74;72;70;66;Indirect Diffuse;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-10677,3914.153;Float;False;Property;_Rimoffset;Rim offset;8;0;Create;True;0;0;0;False;0;False;0.6;0.689;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;59;-10417.29,3684.036;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;52;-10688.46,2848.806;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;46;-10678.08,2990.253;Float;False;Property;_BaseCellSharpness;Base Cell Sharpness;10;0;Create;True;0;0;0;False;0;False;0.01;0.35;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-10841.29,2339.813;Inherit;False;31;WSNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;81;-10317.09,3812.036;Float;False;Property;_RimStr;Rim Str;7;0;Create;True;0;0;0;False;0;False;0.4;0.268;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;55;-10365.4,2850.584;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;61;-11939.2,2664.913;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;70;-10582.3,2446.494;Float;False;Property;_IndirectDiffuseContribution;Indirect Diffuse Contribution;9;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;76;-10231.46,3683.851;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;74;-10462.68,2245.432;Float;False;Constant;_Float0;Float 0;20;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;72;-10551.23,2341.408;Inherit;False;World;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;62;-10174.13,2988.907;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;-9944.421,3509.366;Inherit;False;36;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;93;-11708.78,2661.159;Inherit;False;Lightcolor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;90;-10309.81,2289.792;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;88;-10013.09,3684.036;Inherit;True;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;212;-10508.7,2712.456;Inherit;False;Property;_NoiseRimStr;Noise Rim Str;15;0;Create;True;0;0;0;False;0;False;20;50;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightPos;124;-12052.01,2549.601;Inherit;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.LightAttenuation;137;-9629.611,2830.345;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;135;-9600.191,3020.906;Inherit;False;93;Lightcolor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;199;-10294.99,2575.89;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;134;-9933.926,2966.414;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-9724.165,3508.208;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;195;-9752.65,3737.876;Inherit;False;Property;_NoiseRimBlend;Noise Rim Blend;14;0;Create;True;0;0;0;False;0;False;0.8;0.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;215;-9502.513,3460.071;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;138;-9623.81,3102.406;Inherit;False;Property;_Shadowcolor;Shadow color;3;1;[HDR];Create;True;0;0;0;False;0;False;0.3921569,0.454902,0.5568628,1;0.245283,0.245283,0.245283,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;125;-11640.01,2551.81;Inherit;False;LightType;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;139;-9398.438,2946.031;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;176;-9127.812,2963.172;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;141;-9158.054,2855.834;Inherit;False;125;LightType;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;108;-9742.476,2116.79;Float;False;Property;_MainColor;Main Color;2;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;140;-9137.584,3150.453;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;214;-9339.754,3508.168;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;185;-9450.323,2214.99;Inherit;True;Spherical;World;False;Diffuse;_Diffuse;white;0;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;Diffuse;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ConditionalIfNode;142;-8933.028,2861.853;Inherit;True;False;5;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;106;-9599.976,3997.588;Inherit;False;93;Lightcolor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;208;-9469.826,3718.84;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;85;-9622.718,3812.16;Float;False;Property;_RimColor;Rim Color;6;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0.5849056,0.3553169,0.2069242,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-9011.558,2122.602;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;-9295.869,3846.538;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;120;-8302.323,2396.677;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-7705.01,2168.141;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;KumaBeer/Sand_snow;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;False;0;False;17;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;5;True;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;1;False;-1;0;False;-1;True;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;186;8;23;0
WireConnection;186;3;17;0
WireConnection;28;0;186;0
WireConnection;31;0;28;0
WireConnection;177;3;178;0
WireConnection;200;0;149;0
WireConnection;200;1;201;0
WireConnection;34;0;32;0
WireConnection;34;1;149;0
WireConnection;36;0;34;0
WireConnection;203;0;177;1
WireConnection;203;2;200;0
WireConnection;194;0;203;0
WireConnection;49;0;41;0
WireConnection;49;1;42;0
WireConnection;59;0;49;0
WireConnection;59;1;47;0
WireConnection;52;0;44;0
WireConnection;52;1;39;0
WireConnection;52;2;194;0
WireConnection;55;0;52;0
WireConnection;55;1;46;0
WireConnection;76;0;59;0
WireConnection;72;0;66;0
WireConnection;62;0;55;0
WireConnection;93;0;61;0
WireConnection;90;0;74;0
WireConnection;90;1;72;0
WireConnection;90;2;70;0
WireConnection;88;0;76;0
WireConnection;88;1;81;0
WireConnection;199;1;212;0
WireConnection;199;2;194;0
WireConnection;134;0;90;0
WireConnection;134;1;62;0
WireConnection;105;0;175;0
WireConnection;105;1;88;0
WireConnection;215;0;105;0
WireConnection;215;1;199;0
WireConnection;125;0;124;2
WireConnection;139;0;137;0
WireConnection;139;1;134;0
WireConnection;139;2;135;0
WireConnection;176;0;137;0
WireConnection;176;1;134;0
WireConnection;176;2;135;0
WireConnection;140;0;138;0
WireConnection;140;2;139;0
WireConnection;214;0;215;0
WireConnection;214;1;105;0
WireConnection;214;2;195;0
WireConnection;185;3;17;0
WireConnection;142;0;141;0
WireConnection;142;3;176;0
WireConnection;142;4;140;0
WireConnection;208;0;214;0
WireConnection;115;0;108;0
WireConnection;115;1;185;0
WireConnection;144;0;208;0
WireConnection;144;1;85;0
WireConnection;144;2;106;0
WireConnection;120;0;142;0
WireConnection;120;1;115;0
WireConnection;0;2;144;0
WireConnection;0;13;120;0
ASEEND*/
//CHKSM=C16EE97B5D627A19C38DA0E5225D6651A929B2DD