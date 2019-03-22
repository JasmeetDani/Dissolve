Shader "CustomShaders/DissolveSurfaceShader"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_Scale ("Scale", Float) = 100.0
		_Speed ("Speed", Float) = 3.0
		_EdgeWidth ("EdgeWidth", Float) = 0.05
		_EdgeColor ("EdgeColor", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		uniform float _Scale;
		uniform float _Speed;
		uniform float _EdgeWidth;
		fixed4 _EdgeColor;
				
		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)


		// Ref : https://github.com/Unity-Technologies/ShaderGraph/wiki/Simple-Noise-Node

		inline float unity_noise_randomValue (float2 uv)
		{
			return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
		}

		inline float unity_noise_interpolate (float a, float b, float t)
		{
			return (1.0-t)*a + (t*b);
		}

		inline float unity_valueNoise (float2 uv)
		{
			float2 i = floor(uv);
			float2 f = frac(uv);
			f = f * f * (3.0 - 2.0 * f);

			uv = abs(frac(uv) - 0.5);
			float2 c0 = i + float2(0.0, 0.0);
			float2 c1 = i + float2(1.0, 0.0);
			float2 c2 = i + float2(0.0, 1.0);
			float2 c3 = i + float2(1.0, 1.0);
			float r0 = unity_noise_randomValue(c0);
			float r1 = unity_noise_randomValue(c1);
			float r2 = unity_noise_randomValue(c2);
			float r3 = unity_noise_randomValue(c3);

			float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
			float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
			float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
			return t;
		}


		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;


			// Ref : https://github.com/Unity-Technologies/ShaderGraph/wiki/Simple-Noise-Node

			float t = 0.0;
			for(int i = 0; i < 3; i++)
			{
				float freq = pow(2.0, float(i));
				float amp = pow(0.5, float(3-i));
				t += unity_valueNoise(IN.uv_MainTex * _Scale/freq)*amp;
			}
			
			float level = abs(sin(_Time.y * _Speed));

			o.Emission = step(t, _EdgeWidth + level) * _EdgeColor;

			clip(t - level);
				
			o.Alpha = c.a;
		}

		ENDCG
	}

	FallBack "Diffuse"
}