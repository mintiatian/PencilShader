Shader "Unlit/PenShader"
{
    Properties
    {
		_OutLineWidth("Out Line", Range(0,0.01)) = 0
		_MainTex("Texture", 2D) = "white" {}
		_LineTex("Texture", 2D) = "white" {}
		_Param("sin parame", Range(-400,400)) = 1
		_Shift("shift", Range(-1,1)) = 0
			_PerlinParam("_PerlinParam", Range(0,100000)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


		Pass
		{
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float _OutLineWidth;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				v.vertex += float4(v.normal * _OutLineWidth, 0);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}




			float rand2(float co)
			{
				return frac(sin(dot(co, float3(12.9898, 78.233, 56.787))) * 43758.5453);
			}

			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 56.787))) * 43758.5453);
			}

			float noise(float3 pos)
			{
				float3 ip = floor(pos);
				float3 fp = smoothstep(0, 1, frac(pos));
				float4 a = float4(
					rand(ip + float3(0, 0, 0)),
					rand(ip + float3(1, 0, 0)),
					rand(ip + float3(0, 1, 0)),
					rand(ip + float3(1, 1, 0)));
				float4 b = float4(
					rand(ip + float3(0, 0, 1)),
					rand(ip + float3(1, 0, 1)),
					rand(ip + float3(0, 1, 1)),
					rand(ip + float3(1, 1, 1)));

				a = lerp(a, b, fp.z);
				a.xy = lerp(a.xy, a.zw, fp.y);
				return lerp(a.x, a.y, fp.x);
			}


			float perlin(float3 pos)
			{
				return
					(noise(pos) * 32 +
						noise(pos * 2) * 16 +
						noise(pos * 4) * 8 +
						noise(pos * 8) * 4 +
						noise(pos * 16) * 2 +
						noise(pos * 32)) / 63;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				float2 screenUV = i.uv * _ScreenParams.xy;
				i.uv += (float2(perlin(float3(screenUV, _Time.y) * 5), perlin(float3(screenUV, _Time.y + 100) * 5)) - 0.5) * 0.01;
				float col1 = rand2(i.uv*_Time);
				fixed4 col = fixed4(col1, col1, col1,1);
				return col;
			}




			ENDCG
		}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D _LineTex;
			

			float _Param;
			float _Shift;

            v2f vert (appdata v)
            {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
            }


			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 56.787))) * 43758.5453);
			}

			float noise(float3 pos)
			{
				float3 ip = floor(pos);
				float3 fp = smoothstep(0, 1, frac(pos));
				float4 a = float4(
					rand(ip + float3(0, 0, 0)),
					rand(ip + float3(1, 0, 0)),
					rand(ip + float3(0, 1, 0)),
					rand(ip + float3(1, 1, 0)));
				float4 b = float4(
					rand(ip + float3(0, 0, 1)),
					rand(ip + float3(1, 0, 1)),
					rand(ip + float3(0, 1, 1)),
					rand(ip + float3(1, 1, 1)));

				a = lerp(a, b, fp.z);
				a.xy = lerp(a.xy, a.zw, fp.y);
				return lerp(a.x, a.y, fp.x);
			}

			float _PerlinParam;


			float perlin(float3 pos)
			{
				return
					(noise(pos) * 32 +
						noise(pos * 2) * 16 +
						noise(pos * 4) * 8 +
						noise(pos * 8) * 4 +
						noise(pos * 16) * 2 +
						noise(pos * 32)) / 63;
			}
			float monochrome(float3 col)
			{
				return 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;
			}

            fixed4 frag (v2f i) : SV_Target
            {


				half x = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz)) + _Shift;

				float2 lineUv = i.uv;
				float2 screenUV = i.uv * _ScreenParams.xy;
				i.uv += (float2(perlin(float3(screenUV, _Time.y) * _PerlinParam), perlin(float3(screenUV, _Time.y + 100) * _PerlinParam)) - 0.5) * 0.01;
				//i.uv.x += 0.1 * _Time;
				//i.uv.y += 0.2 * _Time;
				
				float col = monochrome(tex2D(_MainTex, i.uv)) + 0.2f;

				float2 pixelSize = _ScreenParams.zw - 1;
				col -= abs(monochrome(tex2D(_MainTex, i.uv - float2(pixelSize.x, 0)))
						  - monochrome(tex2D(_MainTex, i.uv + float2(pixelSize.x, 0)))
						  + monochrome(tex2D(_MainTex, i.uv - float2(0, pixelSize.y)))
						  - monochrome(tex2D(_MainTex, i.uv + float2(0, pixelSize.y)))) * 0.7;
				
				float4 col2 = tex2D(_MainTex, i.uv);
				//col2 = col;

				float4 col3 = tex2D(_LineTex, i.uv);

				//col *= perlin(float3(screenUV, _Time.y * 10) * 1) * 0.5f + 0.8f;
				return col2 * (col3 + x);
				/*
				i.uv.x += 0.1 * _Time;
				fixed4 texColor = tex2D(_MainTex, i.uv);

				half x = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz)) + _Shift;

				if (x < 0) {
					x = 0;
				}
				//if (nl <= 0.01f) nl = 0.1f;
				//else if (nl <= 0.3f) nl = 0.3f;
				//else nl = 1.0f;


				//float noise = abs(sin(x * 100)) / 2;
				//float noize = (sin(x * 10)) / 2;

				float c = saturate(sin(x * _Param));

				float rand = saturate(random(i.uv * _Time));
				//float rand = saturate(noise(i.uv*800));


				if(c > 0.1)
				{
					c = 1;
				}
				else {
					if (rand<x) {
						c = 1;
					}
				}

				fixed4 col;
				col = fixed4(c, c, c, 1);
				
				return texColor * col;
				*/
            }
            ENDCG
        }
    }
}
