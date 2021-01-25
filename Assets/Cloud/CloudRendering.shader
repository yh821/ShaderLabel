
Shader "CloudRendering"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.141592653

            struct VertInput
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertToFrag
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
                half3 color : COLOR;
                // viewVector represents the ray from camera to the current point
                float3 viewVector : TEXCOORD1;
            };

            VertToFrag vert (VertInput v)
            {
                VertToFrag o;
                o.vertex = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;
                o.color = v.pos.xyz;
                //将v.uv矢量从投影空间转换到相机空间
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                //将视图向量从相机空间转换到世界空间
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }

            //cloud properties
            float4 _cloudColor;
            float3 _speed;
            float _tileSize;
            float _absorptionCoef;

            //shape properties
            float _detailAmount;
            float _maxDetailModifier;
            float _densityConstant;
            float _cloudMaxHeight;
            float _cloudHeightModifier;
            float _cloudBottomModifier;

            // texture and sampler properties
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            SamplerState samplerShapeTexture;
            SamplerState samplerDetailTexture;
            SamplerState samplerWeatherMap;
            SamplerState samplerMaskTexture;

            Texture3D<float4> ShapeTexture;
            Texture3D<float4> DetailTexture;
            Texture2D<float4> WeatherMap;
            Texture2D<float4> MaskTexture;

            // performance properties
            int _lightMarchSteps;
            float _rayMarchStepSize;
            float _lightMarchDecrease;
            float _rayMarchDecrease;

            // container properties
            float3 containerBound_Min;
            float3 containerBound_Max;

            // sun and light properties
            bool _useLight;
            float3 _lightPosition;
            float4 _lightColor;
            float _lightIntensity;
            float _cloudIntensity;

            float _henyeyCoeff;
            float _henyeyRatio;
            float _henyeyIntensity;

            float _powderCoeff;
            float _powderAmount;
            float _powderIntensity;

            // structures used for storage of results from different functions
            struct rayContainerInfo
            {
                bool intersectedBox;
                float dstInsideBox; // 0 if does not intersect box
                float dstToBox; // 0 if inside box
            };

            struct raymarchInfo
            {
                float transmittance;
                float4 density;
            };

            /*
            输入:
                光线原点-光线的起点(相机位置)
                光线方向-入射光线的方向
            输出:rayContainerInfo结构
            */
            rayContainerInfo getRayContainerInfo(float3 rayOrigin, float3 rayDir)
            {
                //这个函数实现了AABB算法 (e.g. https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection)
                
                // tA和tB来自射线线方程:射线原点+ tA*rayDir
                float3 tA = (containerBound_Min - rayOrigin) / rayDir; // for the point on boundsMin - A
                float3 tB = (containerBound_Max - rayOrigin) / rayDir; // for the point on boundsMax - B

                //对组件进行比较并保存结果
                float3 tmin = min(tA, tB);
                float3 tmax = max(tA, tB);
                
                //获取相交距离- dstFirst为与box的第一个相交，dstSecond为第二个相交
                float dstFirst = max(max(tmin.x, tmin.y), tmin.z);
                float dstSecond = min(tmax.x, min(tmax.y, tmax.z));

                rayContainerInfo containerInfo;
                //如果第一个距离小于第二个距离，则光线与盒子相交
                containerInfo.intersectedBox = (dstFirst > dstSecond) ? false : true;
                //如果0 <= dstFirst <= dstSecond，则射线从外部与盒子相交
                containerInfo.dstToBox = max(0, dstFirst);
                //如果dstFirst < 0 < dstSecond (dstA < 0 < dstB)
                containerInfo.dstInsideBox = max(0, dstSecond - containerInfo.dstToBox);

                return containerInfo;
            }

            //如果给定的点在容器内部，则返回true
            bool isInsideBox(float3 position, float3 rayDir)
            {
                rayContainerInfo containerInfo = getRayContainerInfo(position, rayDir);
                return (containerInfo.dstInsideBox > 0);
            }

            //返回3D中两个位置之间的距离
            float getDistance(float3 A, float3 B)
            {
                return sqrt(pow(A.x-B.x, 2) + pow(A.y-B.y, 2) + pow(A.z-B.z, 2));
            }

            //将一个值从一个range (original)映射到一个新的range (new)
            float remap(float value, float originalMin, float originalMax, float newMin, float newMax)
            {
                return newMin + (((value - originalMin) / (originalMax - originalMin)) * (newMax - newMin));
            }

            //改变云的形状，使云稍微向底部四舍五入，很多到顶部(取决于从天气图的高度值)
            float heightAlter(float percentHeight, float heightValue)
            {
                //有点圆到底，几乎看不出来
                float bottomRound = saturate(remap(percentHeight, 0.0, _cloudBottomModifier, 0.0, 1.0));
                //圆在顶部
                float stopHeight = saturate(heightValue + _cloudMaxHeight);
                float topRound = saturate(remap(percentHeight, stopHeight * _cloudHeightModifier, stopHeight, 1.0, 0.0));
                return topRound * bottomRound;
            }

            //根据云的类型，使云的底部更蓬松，顶部更圆润浮动密度(浮动百分比高度，浮动云类型)
            float densityAlter (float percentHeight, float cloudType)
            {
                //减少底部的密度，以使更多的绒毛云，底部为0.2
                float bottomDensity = saturate(remap(percentHeight, 0.0, 0.2, 0.0, 1.0));
                //在顶部创建更多定义的形状，顶部从0.9开始
                float topDensity = saturate(remap(percentHeight, 0.9, 1.0, 1.0, 0.0));

                //密度计算公式，应用mapDensity，底部和顶部密度和用户定义的常数
                return percentHeight * bottomDensity * topDensity * cloudType * _densityConstant;
            }

            //返回给定点的云密度
            float getDensity(float3 position)
            {
            	float3 scale = (position - containerBound_Min) / (containerBound_Max - containerBound_Min);
            	float4 mask = MaskTexture.SampleLevel(samplerMaskTexture, float2(scale.x,scale.z), 0);
            	if (mask.r<=0)
            		return 0;
            	
                //获取样本的位置
                float3 samplePos = (position + _Time.y * _speed)/_tileSize;

                //即使在盒子外也不要取样
                if (!isInsideBox(position, _lightPosition))
                    return 0;

                //对天气纹理进行采样，红色通道表示覆盖，绿色通道表示高度，蓝色通道表示云层密度
                float2 weatherSamplePos = float2(samplePos.x, samplePos.z);
                float4 weatherValue = WeatherMap.SampleLevel(samplerWeatherMap, weatherSamplePos, 0);
                //从天气纹理中获取单独的值
                float heightValue = weatherValue.g;
                float globalDensity = weatherValue.b;
                float cloudCoverage = weatherValue.r;
                
                //从形状纹理中获得云的基本形状，使用柏林噪声(红色通道)作为基础
                float4 shapeDensity = ShapeTexture.SampleLevel(samplerShapeTexture, samplePos, 0);
                float shapeNoise = shapeDensity.g * 0.625 + shapeDensity.b * 0.25 + shapeDensity.a * 0.125;
                shapeNoise = -(1 - shapeNoise);
                shapeNoise = remap(shapeDensity.r, shapeNoise, 1.0, 0.0, 1.0); // this is now the base cloud

                //获取当前点的高度百分比
                float heightPercentage = (position.y - containerBound_Min.y) / (containerBound_Max.y - containerBound_Min.y);

                //采样将用于腐蚀边缘的细节噪声
                float4 detailDensity = DetailTexture.SampleLevel(samplerDetailTexture, samplePos, 0);
                float detailNoise = detailDensity.r * 0.625 + detailDensity.g * 0.25 + detailDensity.a * 0.125; //类似的采样形状纹理
                //根据高度百分比调整细节噪声-点越低，形状越纤细
                float detailModifier = lerp (detailNoise, 1-detailNoise, saturate(heightPercentage));
                //减少细节噪声的数量，使最大值为detailAmount(用户输入)
                detailModifier *= _detailAmount * exp(-_maxDetailModifier);

                //从当前的heightPercetange采样高度和密度改变函数
                float heightModifier = heightAlter(heightPercentage, heightValue); //根据云的高度，可以将云绕向底部和顶部
                float densityFactor = densityAlter(heightPercentage, globalDensity); //编辑密度，使云底部更蓬松，顶部更圆润

                //等式来自Haggstrom的论文
                float shapeND = saturate(remap(heightModifier * shapeNoise, 1 - cloudCoverage, 1.0, 0.0, 1.0));

                //从形状杂色中减去细节杂色以侵蚀边缘
                float finalDensity = saturate(remap(shapeND, detailModifier, 1.0, 0.0, 1.0));

                //再次改变结尾的密度，哈吉斯特罗姆Haggstrom
                return finalDensity * densityFactor;
            }

            //实现相位函数，cosAngle是两个向量夹角的余弦，g是[-1,1]中的参数
            float getHenyeyGreenstein(float cosAngle, float g)
            {
                return (1-g*g)/ (PI) * sqrt(pow(1 + g*g - 2*g*cosAngle, 3)); //由于结果太暗，我把4因子去掉了
            }

            //使用用户选择的henyey系数和相位函数的权/比实现相位函数
            float phaseFunction(float cosAngle)
            {
                //得到henyey-greenstein相位函数
                float hg = getHenyeyGreenstein(cosAngle, _henyeyCoeff);
                return (1 - _henyeyRatio) + hg * _henyeyRatio *  _henyeyIntensity;
            }

            //返回地平线零点的啤酒粉效应值
            float powderEffect(float depth)
            {
                return (1 - exp(-_powderCoeff * 2 * depth)) * _powderAmount * _powderIntensity + (1 - _powderAmount);
            }

            float lightmarch(float3 pos, float heightPercentage)
            {
                //从我的位置到光的位置归一化矢量
                float3 dirVector = float3(_lightPosition.x, _lightPosition.y, _lightPosition.z) - pos;
                dirVector = dirVector / length(dirVector);

                //获取与云容器的交集
                rayContainerInfo containerInfo = getRayContainerInfo(_lightPosition, -dirVector);
                float3 entryPoint = _lightPosition - dirVector * containerInfo.dstToBox;

                //轻行军，从我的位置行军到入口点
                float3 currPoint = pos;
                //每个轻步的步数应该是相同的
                float distanceToMarch = getDistance(entryPoint, pos) * heightPercentage; //不要超过最大高度
                float noOfSteps = _lightMarchSteps; //轻步步由用户设置
                float stepDecrease = _lightMarchDecrease;
                float stepSize = distanceToMarch/noOfSteps;

                //使用此属性在行进时减少步长，步长最多为4
                if (noOfSteps == 2)
                    stepSize = distanceToMarch/(1 + stepDecrease);
                else if (stepSize == 3)
                    stepSize = distanceToMarch/(1 + stepDecrease + pow(stepDecrease,2));
                else if (stepSize == 4)
                    stepSize = distanceToMarch/(1 + stepDecrease + pow(stepDecrease,2) + pow(stepDecrease,3));

                float accumDensity = 0; //从我的点到入口点的所有光线的累积密度
                float transmittance = 1;

                while (noOfSteps > 0)
                {
                    float density = getDensity(currPoint); //获取射线当前部分的密度
                    if (density > 0)
                        accumDensity += density * stepSize;
                    else
                        break; //性能度量，当密度为零时，通常意味着我们已经走出了云雾
                    //向光的方向再走一步
                    currPoint += dirVector * stepSize;
                    stepSize *= stepDecrease;
                    noOfSteps--;
                }

                //使用beer定律来计算光的衰减(来自Fredrik Haggstrom的论文)
                float lightAttenuation = exp(-accumDensity * _absorptionCoef);
                return lightAttenuation * _lightIntensity * _lightColor; //通过用户设置亮度和颜色
            }

            float getIncidentLighting(float3 pos, float3 incVector, float currDensity)
            {
                //将在照明计算中多次使用
                float heightPercentage = (pos.y - containerBound_Min.y) / (containerBound_Max.y - containerBound_Min.y);

                //获取来自太阳的光，使用光行进算法
                float lightFromSun = lightmarch(pos, heightPercentage);
                lightFromSun *= powderEffect(currDensity);

                ///只有在需要时才计算相位函数的值
                float phaseVal = 1;
                if (_henyeyRatio > 0)
                {
                    float3 lightVector = pos - float3(_lightPosition.x, _lightPosition.y, _lightPosition.z);
                    lightVector = lightVector / length(lightVector);
                    float cosAngle = dot(normalize(incVector), lightVector);
                    phaseVal = phaseFunction(cosAngle);
                }
                return phaseVal * lightFromSun;
            }

            //射线行军，主要从Palenik实现
            raymarchInfo raymarch(float3 entryPoint, float3 rayDir)
            {
                float stepSize = _rayMarchStepSize; //用户定义的步长
                //一个不被0除的支票
                if (stepSize <= 0 || _rayMarchDecrease <= 0)
                {
                    raymarchInfo result;
                    result.transmittance = 0;
                    result.density = 0;
                    return result;
                }

                float transmittance = 1; //接收到的光和发射到的光的当前比率(透明度的累加变量)
                float4 totalDensity = float4(0,0,0,0); //结果颜色的累加变量
                float3 currPoint = entryPoint; //射线行进时射线上的当前点

                //光线行进算法
                while (isInsideBox(currPoint, rayDir))
                {
                    float density = getDensity(currPoint); //密度=从噪声纹理中采样的颜色
                    if (density > 0)
                    {
                        float incLight = 0;
                        if (_useLight)
                            incLight = getIncidentLighting(currPoint, rayDir, density);

                        //用比尔-朗伯定律近似光的衰减
                        float deltaT = exp(-_absorptionCoef * stepSize * density);

                        //当你远离观众时，降低透过率
                        transmittance *= deltaT;
                        if (transmittance < 0.01) // break if transmittance is too low to avoid performance problems
                            break;

                        //光线行进渲染方程，常量项并没有添加到这里来提高性能
                        totalDensity += density * transmittance * incLight;
                    }

                    //沿着射线向前走一步
                    currPoint += rayDir * stepSize;
                    stepSize *= _rayMarchDecrease; //用户定义的减少
                    
                }
                raymarchInfo result;
                result.transmittance = transmittance;
                
                // raymarch渲染方程的另一部分-添加常量项，这样它们就不必在每个raymarch步骤中添加
                result.density = totalDensity * _absorptionCoef * stepSize;
                return result;
            }

            fixed4 frag (VertToFrag i) : COLOR
            {
                //得到归一化的射线方向
                float viewLength = length(i.viewVector);
                float3 rayDir = i.viewVector / viewLength;

                // ray从相机位置开始
                float3 rayOrigin = _WorldSpaceCameraPos;

                //获取ray与容器相交的信息
                rayContainerInfo containerInfo = getRayContainerInfo(rayOrigin, rayDir);
                
                //如果有其他物体，不要渲染云
                float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonLinearDepth) * viewLength;

                //如果方框没有相交，返回基数
                float4 base = tex2D(_MainTex, i.uv);

                if (!containerInfo.intersectedBox || containerInfo.dstToBox > depth)
                    return base;

                float3 entryPoint = rayOrigin + rayDir * containerInfo.dstToBox; //与云容器相交
                raymarchInfo raymarchInfo = raymarch(entryPoint, rayDir); //通过云层，得到密度和透过率

                //添加用户定义的强度和云颜色到已经采样的密度，也添加来自环境太阳的光色
                return base * raymarchInfo.transmittance + raymarchInfo.density * _cloudIntensity * _cloudColor;
            }
            ENDCG
        }
    }
}
