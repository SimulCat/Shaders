Shader "SimulCat/Wave Surface/From Phase CRT"
{
    Properties
    {
        _MainTex ("Surface Phase", 2D) = "white" {}
        _Color("Wave Colour", Color) = (.45,.8,1,.4)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _ScaleAmplitude("Scale Amplitude", Range(0, 0.1)) = 0.01
        _ScaleEnergy("Scale Energy", Range(0, 0.1)) = 0.003
        _ClipHeight("Clip Height", Range(0.01,1)) = .25
        _Frequency("Wave Frequency", float) = 0
        _ShowHeight("Show Real", float) = 1
        _ShowVelocity("Show Imaginary", float) = 0
        _ShowSquare("Show Energy", float) = 0
    }
    SubShader
    {
        Tags { "Rendertype"="Opaque"}
        //Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"}
        Cull Off
        LOD 100
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard addshadow fullforwardshadows vertex:verts
        //#pragma surface surf Standard alpha addshadow fullforwardshadows vertex:verts

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;

        half _Glossiness;
        half _Metallic;

        fixed4 _Color;

        float _ScaleAmplitude;
        float _ScaleEnergy;
        float _ClipHeight;
        float _Frequency;
        
        float _ShowHeight;
        float _ShowVelocity;
        float _ShowSquare;

        static const float Tau = 6.28318531f;

        struct Input
        {
            float2 uv_MainTex;
        };

        float rotatePhase(float2 phSample)
        {
            float tphi = (1 - frac(_Frequency * _Time.y)) * Tau;
            float sinPhi = sin(tphi);
            float cosPhi = cos(tphi);
            return float2(  phSample.x * cosPhi - phSample.y * sinPhi, 
                            phSample.x * sinPhi + phSample.y * cosPhi);
        }

        float samplePhase(float4 phaseSample)
        {
            float result = 0;
            if ((_ShowHeight > 0.1) && (_ShowVelocity > 0.1))
            {
                result = _ShowSquare > 0.1 ? phaseSample.w : phaseSample.z;
                if (_ShowSquare > 0.1) 
                    result *= _ScaleEnergy;
                else
                    result *= _ScaleAmplitude;
            }
            else
            {
                float2 phasor = (_Frequency > 0) ? rotatePhase(phaseSample.xy) : phaseSample.xy;
                result = (_ShowHeight > 0) ? phasor.x : phasor.y;

                result = (_ShowSquare > 0.1) ? result * result * _ScaleEnergy : result * _ScaleAmplitude;
            }
            return clamp(result, -_ClipHeight,_ClipHeight);
        }

        void verts (inout appdata_full vertices) 
        {
            float3 p = vertices.vertex.xyz;
            p.y = samplePhase(tex2Dlod(_MainTex, float4(vertices.texcoord.xy, 0, 0)));
            vertices.vertex.xyz = p;
        }

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            // Albedo comes from a texture tinted by color
            float hgt = samplePhase(tex2D(_MainTex, i.uv_MainTex));
            float lvl = (_ShowSquare > 0.1) ? hgt/_ClipHeight : ((hgt*.5) +0.5)/_ClipHeight;
            fixed4 c = _Color * lvl;
            o.Alpha = lerp(1,0.35,lvl);
            
            float3 duv = float3(_MainTex_TexelSize.xy, 0);
            float delta = _MainTex_TexelSize.x*2;

            o.Albedo =  fixed4(c.rgb,1);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            float v1 = samplePhase(tex2D(_MainTex, i.uv_MainTex - duv.xz));
            float v2 = samplePhase(tex2D(_MainTex, i.uv_MainTex + duv.xz));
            float v3 = samplePhase(tex2D(_MainTex, i.uv_MainTex - duv.zy));
            float v4 = samplePhase(tex2D(_MainTex, i.uv_MainTex + duv.zy));
            float d1 = v1 - v2;
            float d2 = v3 - v4;
            o.Normal = normalize(float3(d1,delta, d2));
        }
        ENDCG
    }
    FallBack "Diffuse"
}
