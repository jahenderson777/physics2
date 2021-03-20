/*Shader "Unlit/particles"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
*/



// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Subway/Particles"
{

    Properties
    {
        _ColorLow("Color Slow Speed", Color) = (0, 0, 0.5, 1)
        _ColorHigh("Color High Speed", Color) = (0, 1, 0, 1)
        _HighSpeedValue("High speed Value", Range(0, 50)) = 25
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }


        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0

// Lighting and shadow keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Particle's data
            struct Particle
            {
                float2 position;
                float2 velocity;
            };

            struct DrawTriangle {
                //float3 normalWS; // normal in world space. All points share this normal
                //DrawVertex vertices[3];
                float3 vertices[3];
            };

            // Pixel shader input
            struct PS_INPUT
            {
                float4 position : SV_POSITION;
                float4 color : COLOR;
            };

            // Particle's data, shared with the compute shader
            StructuredBuffer<Particle> Particles;
            StructuredBuffer<DrawTriangle> _DrawTriangles;

            // Properties variables
            uniform float4 _ColorLow;
            uniform float4 _ColorHigh;
            uniform float _HighSpeedValue;

            PS_INPUT vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID, out float pointSize : PSIZE)
            {
                pointSize = 4;

                PS_INPUT o = (PS_INPUT)0;

                //float speed = length(Particles[instance_id].velocity);
                //float lerpValue = clamp(speed / _HighSpeedValue, 0.0f, 1.0f);

                DrawTriangle tri = _DrawTriangles[vertex_id / 3];
                float3 vert = tri.vertices[vertex_id % 3];

                o.color = _ColorHigh; //lerp(_ColorLow, _ColorHigh, lerpValue);

                o.position = UnityObjectToClipPos(float4(vert.x, vert.y, vert.z, 1.0));

                return o;
            }

            float4 frag(PS_INPUT i) : COLOR
            {
                return i.color;
            }

            ENDCG
        }
    }

    Fallback Off
}