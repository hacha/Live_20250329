// for shadertoy

// グリッド表示の設定
#define SHOW_GRID false
#define GRID_MAX_DISTANCE 15.0 // グリッドが見える最大距離
#define PI 3.1415926535897932384626433832795

// ハッシュ関数（グリッドごとのランダム値生成用）
float hash(vec3 p) {
    p = fract(p * vec3(123.34, 456.21, 789.92));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y * p.z);
}

// ノイズ関数（グリッド間でスムーズな値を生成）
float smoothNoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    // スムーズステップ
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    // 8つの頂点でのハッシュ値
    float a = hash(i);
    float b = hash(i + vec3(1.0, 0.0, 0.0));
    float c = hash(i + vec3(0.0, 1.0, 0.0));
    float d = hash(i + vec3(1.0, 1.0, 0.0));
    float e = hash(i + vec3(0.0, 0.0, 1.0));
    float f1 = hash(i + vec3(1.0, 0.0, 1.0));
    float g = hash(i + vec3(0.0, 1.0, 1.0));
    float h = hash(i + vec3(1.0, 1.0, 1.0));
    
    // トリリニア補間
    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f1;
    float k7 = -a + b + c - d + e - f1 - g + h;
    
    return k0 + k1 * u.x + k2 * u.y + k3 * u.z +
    k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x +
    k7 * u.x * u.y * u.z;
}

// 点滅制御関数
float blink(vec3 cellIndex, float time) {
    float h = hash(cellIndex);
    // 8%の確率で点滅する
    if (h > 0.72) {
        // 点滅の速さと位相をランダムに
        float blinkSpeed = 4.0 + h * 12.0;
        float phase = h * 10.0;
        return step(0.5, sin(time * blinkSpeed + phase));
    }
    return 1.0;
}

// 飛び回るキューブの位置を計算する関数
vec3 getFlyingCubePosition(float time) {
    // 1つ目の大きな周回運動のパラメータ
    float orbitRadius1 = 25.0; // 大きな周回の半径
    float orbitSpeed1 = 0.15; // ゆっくりとした周回速度
    float orbitHeight1 = 12.0; // 周回の高さ
    
    // 1つ目の大きな周回運動の計算
    float orbitTheta1 = time * orbitSpeed1;
    vec3 orbitCenter1 = vec3(
        orbitRadius1 * cos(orbitTheta1),
        orbitHeight1 + sin(time * 0.2) * 3.0, // 高さも緩やかに変化
        orbitRadius1 * sin(orbitTheta1)
    );
    
    // 2つ目の大きな周回運動のパラメータ（異なる値を設定）
    float orbitRadius2 = 35.0; // より大きな半径
    float orbitSpeed2 = 0.11; // より遅い速度
    float orbitHeight2 = 18.0; // より高い位置
    
    // 2つ目の大きな周回運動の計算（逆方向に回転）
    float orbitTheta2 = -time * orbitSpeed2; // マイナスで逆回転
    vec3 orbitCenter2 = vec3(
        orbitRadius2 * cos(orbitTheta2),
        orbitHeight2 + sin(time * 0.15) * 4.0, // より大きくゆっくりとした上下動
        orbitRadius2 * sin(orbitTheta2)
    );
    
    // 2つの周回運動の中心点を補間
    float blendFactor = sin(time * 0.3) * 0.5 + 0.5; // 0.0-1.0でゆっくり変化
    vec3 orbitCenter = mix(orbitCenter1, orbitCenter2, blendFactor);
    
    // 基本となる円運動のパラメータ（既存の動き）
    float baseRadius = 12.0;
    float baseHeight = 5.5;
    
    // 複数の周期を組み合わせた水平面での動き
    float theta1 = time * 0.97;
    float theta2 = time * 0.53;
    float theta3 = time * 1.31;
    
    // 複数の周期を組み合わせた垂直方向の動き
    float phi1 = time * 0.85;
    float phi2 = time * 0.67;
    float phi3 = time * 1.23;
    
    // 半径の変動
    float radiusVar = sin(time * 0.43) * 2.0;
    float radius = baseRadius + radiusVar;
    
    // 高さの変動
    float heightVar1 = sin(phi1 + PI * 0.5) * 2.0;
    float heightVar2 = cos(phi2) * 1.5;
    float heightVar3 = sin(phi3) * 1.0;
    float height = baseHeight + heightVar1 + heightVar2 + heightVar3;
    
    // 水平面での位置の計算（複数の円運動の合成）
    float x = radius * (cos(theta1) * 0.6 + cos(theta2) * 0.3 + cos(theta3) * 0.1);
    float z = radius * (sin(theta1) * 0.6 + sin(theta2) * 0.3 + sin(theta3) * 0.1);
    
    // 局所的な動きを補間された周回運動に加算
    float averageHeight = mix(orbitHeight1, orbitHeight2, blendFactor);
    return orbitCenter + vec3(x, height - averageHeight, z);
}

// 回転行列を生成する関数
mat3 rotateMatrix(vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat3(
        oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
    );
}

// キューブの距離関数
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// インデックスが奇数かどうかをチェックする関数
bool isOddIndex(vec3 cellIndex) {
    // 各成分が奇数かどうかをチェック
    bool isXOdd = mod(abs(cellIndex.x), 2.0) >= 1.0;
    bool isYOdd = mod(abs(cellIndex.y), 2.0) >= 1.0;
    bool isZOdd = mod(abs(cellIndex.z), 2.0) >= 1.0;
    
    // いずれかの成分が奇数ならtrue
    return isXOdd || isYOdd || isZOdd;
}

// 3x3x3のキューブ群の距離関数
float sdCubeGrid(vec3 p, vec3 totalSize) {
    vec3 smallCubeSize = totalSize / 3.5;
    vec3 cellIndex = floor((p + totalSize * 0.5) / smallCubeSize);
    vec3 localP = mod(p + totalSize * 0.5, smallCubeSize) - smallCubeSize * 0.5;
    
    // 3x3x3の範囲内のセルのみ処理
    if (any(lessThan(cellIndex, vec3(0.0)))|| any(greaterThanEqual(cellIndex, vec3(3.0)))) {
        return 1e10;
    }
    
    // 小さなキューブの距離計算（サイズを半分に）
    float smallCubeDist = sdBox(localP, smallCubeSize * 0.2);
    
    // 中心からの距離に基づいて重みを計算
    vec3 centerDist = abs(cellIndex - vec3(1.0));
    float weight = max(centerDist.x, max(centerDist.y, centerDist.z));
    
    // 中心に近いキューブほど大きく
    float sizeScale = 1.0 - weight * 0.2;
    smallCubeDist *= 1.0 / sizeScale;
    
    return smallCubeDist;
}

// モーフィング用の距離関数
float morphDistance(vec3 p, vec3 size, float morphFactor) {
    float singleCubeDist = sdBox(p, size);
    float cubeGridDist = sdCubeGrid(p, size * 2.0); // グリッドは少し大きめに
    
    // スムーズステップでモーフィングを補間
    float smoothMorphFactor = smoothstep(0.0, 1.0, morphFactor);
    
    // 距離関数の補間時に形状を保持
    float morphedDist = mix(singleCubeDist, cubeGridDist, smoothMorphFactor);
    
    // モーフィング中の形状の安定化
    float stabilityFactor = sin(smoothMorphFactor * PI) * 0.5 + 0.5;
    morphedDist *= mix(1.0, 1.2, stabilityFactor);
    
    return morphedDist;
}

// 回転アニメーションの制御関数
vec4 getRotationParams(vec3 cellIndex, float time) {
    float h = hash(cellIndex);
    float h2 = hash(cellIndex + vec3(42.0));
    
    // 50%の確率で回転する
    if (h > 0.5) {
        // 回転の周期（8秒）
        float rotationCycle = 8.0;
        float cycleStart = floor(time / rotationCycle) * rotationCycle;
        float localTime = time - cycleStart;
        
        // 回転軸の選択（x, y, z のいずれか）
        vec3 axis;
        if (h2 < 0.33) {
            axis = vec3(1.0, 0.0, 0.0); // X軸
        } else if (h2 < 0.66) {
            axis = vec3(0.0, 1.0, 0.0); // Y軸
        } else {
            axis = vec3(0.0, 0.0, 1.0); // Z軸
        }
        
        // 回転角度の計算（0から90度まで）
        float angle = 0.0;
        if (localTime < 1.0) {
            // イーズイン・イーズアウトの補間
            float t = localTime;
            t = t * t * (3.0 - 2.0 * t); // スムーズステップ
            angle = t * PI * 0.5; // 90度（π/2）
        } else {
            angle = PI * 0.5; // 90度で固定
        }
        
        return vec4(axis, angle);
    }
    
    return vec4(vec3(1.0, 0.0, 0.0), 0.0); // 回転なし
}

// HSVからRGBへの変換関数
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// RGBからHSVへの変換関数
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, - 1.0 / 3.0, 2.0 / 3.0, - 1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 0.0000000001; // 1.0e-10 をリテラルで表現
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// 回転する平面との距離を計算する関数
float getRotatingPlaneDistance(vec3 p, float time, int planeId) {
    // 各平面の回転速度と動きを設定
    vec3 normal;
    float d0;
    
    if (planeId == 0) {
        // 1つ目の平面（既存）
        normal = normalize(vec3(
                sin(time * 0.5),
                cos(time * 0.7),
                sin(time * 0.3)
            ));
            d0 = 2.0 * sin(time * 0.2);
        } else if (planeId == 1) {
            // 2つ目の平面（新規）
            normal = normalize(vec3(
                    cos(time * 0.4),
                    sin(time * 0.6),
                    cos(time * 0.8)
                ));
                d0 = 3.0 * cos(time * 0.3);
            } else {
                // 3つ目の平面（新規）
                normal = normalize(vec3(
                        sin(time * 0.9),
                        cos(time * 0.5),
                        sin(time * 0.7)
                    ));
                    d0 = 2.5 * sin(time * 0.4);
                }
                
                // 点と平面の距離
                return abs(dot(p, normal) - d0);
            }
            
            // キューブの色を計算する関数
            vec3 getCubeColor(vec3 cellIndex, float time) {
                // インデックスが奇数の場合は黒（非表示）を返す
                if (isOddIndex(cellIndex)) {
                    return vec3(0.0);
                }
                
                float noiseScale = 0.3; // ノイズのスケール（小さいほど滑らか）
                
                // 各色成分に異なるオフセットを使用してノイズを生成
                float r = smoothNoise(cellIndex * noiseScale);
                float g = smoothNoise(cellIndex * noiseScale + vec3(42.0));
                float b = smoothNoise(cellIndex * noiseScale + vec3(123.0));
                
                // 時間による変化を加える
                float timeScale = 0.1;
                r = mix(r, smoothNoise(cellIndex * noiseScale + vec3(time * timeScale)), 0.3);
                g = mix(g, smoothNoise(cellIndex * noiseScale + vec3(42.0 + time * timeScale)), 0.3);
                b = mix(b, smoothNoise(cellIndex * noiseScale + vec3(123.0 + time * timeScale)), 0.3);
                
                // 色の範囲を調整
                vec3 baseColor = vec3(r, g, b) * vec3(0.6, 0.8, 1.0);
                
                // 3つの平面それぞれとの距離を計算
                vec3 worldPos = cellIndex * 6.0; // グリッドの実際の位置
                float planeDist1 = getRotatingPlaneDistance(worldPos, time, 0);
                float planeDist2 = getRotatingPlaneDistance(worldPos, time, 1);
                float planeDist3 = getRotatingPlaneDistance(worldPos, time, 2);
                
                // 各平面からの影響を計算
                float planeInfluence1 = smoothstep(2.0, 0.0, planeDist1);
                float planeInfluence2 = smoothstep(2.0, 0.0, planeDist2);
                float planeInfluence3 = smoothstep(2.0, 0.0, planeDist3);
                
                // RGBをHSVに変換
                vec3 hsv = rgb2hsv(baseColor);
                
                // 各平面からの色相変調を適用（異なる周期と強度で）
                hsv.x = mod(hsv.x +
                    planeInfluence1 * 0.5 * sin(time) +
                    planeInfluence2 * 0.3 * cos(time * 1.2) +
                    planeInfluence3 * 0.4 * sin(time * 0.8), 1.0);
                    
                    // 彩度も平面からの影響で変化
                    hsv.y = mix(hsv.y, 1.0, max(max(
                                planeInfluence1 * 0.5,
                            planeInfluence2 * 0.4),
                        planeInfluence3 * 0.3));
                        
                        // HSVをRGBに戻す
                        return hsv2rgb(hsv);
                    }
                    
                    // 子キューブの位置を計算する関数
                    vec3 getChildCubePosition(vec3 parentPos, float time, float delay) {
                        // 親の位置から少し遅れて追従
                        float delayedTime = time - delay;
                        vec3 basePos = getFlyingCubePosition(delayedTime);
                        
                        // 親の位置と子の位置の差分を計算
                        vec3 diff = basePos - parentPos;
                        
                        // フレーム内での相対位置（0.0から1.0）
                        float framePosition = delay / (0.15 * 20.0); // 20は子キューブの総数
                        
                        // 距離の伸縮を計算
                        float baseStretch = 3.0; // 基本の伸縮範囲
                        float stretchPhase = time * 2.0; // 伸縮の周期
                        
                        // サインウェーブで伸縮（0.3から3.0の範囲）
                        float stretchFactor = mix(0.3, 3.0, (sin(stretchPhase + framePosition * PI * 2.0) * 0.5 + 0.5));
                        
                        return parentPos + diff * stretchFactor;
                    }
                    
                    /**
                    * 各オブジェクトの距離を計算し、最も近いオブジェクトの情報を返す関数
                    *
                    * @param p 空間内の位置（ワールド座標）
                    * @return vec2(距離, マテリアルID)
                    *   - x成分: 最も近いオブジェクトまでの符号付き距離
                    *   - y成分: オブジェクトのマテリアルID
                    *     - 負の値: 無効（オブジェクトなし）
                    */
                    vec2 mapObjects(vec3 p) {
                        // 距離と材質ID（最初は無効な値で初期化）
                        vec2 res = vec2(1e10, - 1.0);
                        
                        // 回転する平面の距離を計算
                        float planeDist = getRotatingPlaneDistance(p, iTime, 0);
                        if (planeDist < res.x) {
                            res = vec2(planeDist, 3.0); // マテリアルID 3.0を平面用に使用
                        }
                        
                        // 親キューブの位置と処理
                        vec3 cubePos = getFlyingCubePosition(iTime);
                        vec3 cubeSize = vec3(2.0);
                        
                        // 親キューブの回転
                        vec3 rotatedP = p - cubePos;
                        rotatedP = rotateMatrix(normalize(vec3(1.0, 1.0, 1.0)), iTime) * rotatedP;
                        
                        // 親キューブの距離計算（モーフィングなし）
                        float cubeDist = sdBox(rotatedP, cubeSize);
                        if (cubeDist < res.x) {
                            res = vec2(cubeDist, 4.0);
                        }
                        
                        // 20個の子キューブを追加
                        const int NUM_CHILDREN = 20;
                        float baseDelay = 0.15; // 基本の遅延時間
                        float maxSize = 0.95; // 最大サイズ（親の85%）
                        float minSize = 0.20; // 最小サイズ（親の30%）
                        
                        for(int i = 0; i < NUM_CHILDREN; i ++ ) {
                            // 遅延時間を計算（等間隔）
                            float delay = baseDelay * float(i + 1);
                            
                            // サイズを計算（徐々に小さく）
                            float t = float(i) / float(NUM_CHILDREN - 1);
                            float size = mix(maxSize, minSize, t);
                            
                            // 子キューブの位置を計算
                            vec3 childPos = getChildCubePosition(cubePos, iTime, delay);
                            vec3 childRotatedP = p - childPos;
                            childRotatedP = rotateMatrix(normalize(vec3(1.0, 1.0, 1.0)), iTime - delay) * childRotatedP;
                            
                            // 子キューブのサイズを設定
                            vec3 childSize = cubeSize * size;
                            
                            // 子キューブの距離計算（モーフィングなし）
                            float childDist = sdBox(childRotatedP, childSize);
                            
                            // 子キューブの距離と材質IDを更新（材質IDは4.1から4.99）
                            if (childDist < res.x) {
                                res = vec2(childDist, 4.1 + float(i) * 0.045);
                            }
                        }
                        
                        return res;
                    }
                    
                    // シーンの距離関数
                    float map(vec3 p)
                    {
                        return mapObjects(p).x;
                    }
                    
                    // マテリアルID
                    float getMaterial(vec3 p) {
                        return mapObjects(p).y;
                    }
                    
                    // スムーズステップ関数（アンチエイリアス用）
                    float smoothGrid(float coord, float width, float feather) {
                        float half_width = width * 0.5;
                        float lower = 0.5 - half_width - feather;
                        float upper = 0.5 - half_width;
                        return smoothstep(lower, upper, coord) - smoothstep(1.0 - upper, 1.0 - lower, coord);
                    }
                    
                    // グリッドを描画する関数
                    vec4 drawGrid(vec3 p, float distanceFromCamera) {
                        // 基本の真っ黒な床の色（透明）
                        vec4 gridColor = vec4(0.0);
                        
                        // 距離に応じたフェードアウト係数（遠くになるほど透明に）
                        float fadeFactor = 1.0 - clamp(distanceFromCamera / GRID_MAX_DISTANCE, 0.0, 1.0);
                        fadeFactor = smoothstep(0.0, 0.4, fadeFactor); // よりスムーズなフェードアウト
                        
                        // Blenderスタイルのグリッド
                        float smallGrid = 1.0; // 小さいグリッドのサイズ
                        float largeGrid = 5.0; // 大きいグリッドのサイズ
                        
                        // グリッドラインの太さ（距離に応じて調整）
                        float smallLineBaseWidth = 0.01;
                        float largeLineBaseWidth = 0.005;
                        
                        // 距離に応じてラインを太くして見やすくする
                        float distanceFactor = min(distanceFromCamera / 20.0, 1.0);
                        float smallLineWidth = smallLineBaseWidth * (1.0 + distanceFactor * 2.0);
                        float largeLineWidth = largeLineBaseWidth * (1.0 + distanceFactor);
                        
                        // アンチエイリアス用のフェザー値
                        float feather = 0.001 * (1.0 + distanceFactor * 5.0);
                        
                        // 座標をグリッドサイズで割って、0～1の範囲にマッピング
                        vec2 smallGridCoord = fract(p.xz / smallGrid);
                        vec2 largeGridCoord = fract(p.xz / largeGrid);
                        
                        // スムーズステップでアンチエイリアスを適用
                        float smallGridX = smoothGrid(smallGridCoord.x, smallLineWidth, feather);
                        float smallGridZ = smoothGrid(smallGridCoord.y, smallLineWidth, feather);
                        float largeGridX = smoothGrid(largeGridCoord.x, largeLineWidth, feather);
                        float largeGridZ = smoothGrid(largeGridCoord.y, largeLineWidth, feather);
                        
                        // 小さいグリッドの線
                        float smallGridLines = max(smallGridX, smallGridZ);
                        if (smallGridLines > 0.0) {
                            gridColor = vec4(vec3(0.2), smallGridLines * fadeFactor * 0.5);
                        }
                        
                        // 大きいグリッドの線
                        float largeGridLines = max(largeGridX, largeGridZ);
                        if (largeGridLines > 0.0) {
                            gridColor = vec4(vec3(0.4), largeGridLines * fadeFactor * 0.7);
                        }
                        
                        // 座標軸の中心線（X軸とZ軸）をハイライト
                        float xAxisDist = abs(p.x);
                        float zAxisDist = abs(p.z);
                        float centerLineWidth = 0.04 * (1.0 + distanceFactor);
                        
                        // X軸（赤）
                        if (xAxisDist < centerLineWidth) {
                            float axisIntensity = (1.0 - xAxisDist / centerLineWidth) * fadeFactor;
                            gridColor = vec4(vec3(0.7, 0.0, 0.0) * axisIntensity, axisIntensity * 0.8);
                        }
                        
                        // Z軸（青）
                        if (zAxisDist < centerLineWidth) {
                            float axisIntensity = (1.0 - zAxisDist / centerLineWidth) * fadeFactor;
                            gridColor = vec4(vec3(0.0, 0.0, 0.7) * axisIntensity, axisIntensity * 0.8);
                        }
                        
                        // Y軸（緑）
                        if (xAxisDist < centerLineWidth && zAxisDist < centerLineWidth) {
                            float axisIntensity = (1.0 - max(xAxisDist, zAxisDist) / centerLineWidth) * fadeFactor;
                            gridColor = vec4(vec3(0.0, 0.7, 0.0) * axisIntensity, axisIntensity * 0.8);
                        }
                        
                        return gridColor;
                    }
                    
                    // グリッドとの交差を計算する関数
                    float intersectGrid(vec3 ro, vec3 rd) {
                        // y=0の平面との交差を計算
                        float t = -ro.y / rd.y;
                        
                        // 交差点が前方にあり、有効な値であることを確認
                        if (t > 0.0) {
                            return t;
                        }
                        
                        return - 1.0; // 交差なし
                    }
                    
                    // Y軸との交差を計算する関数
                    float intersectYAxis(vec3 ro, vec3 rd) {
                        // X=0, Z=0の線（Y軸）との最小距離を計算
                        // Y軸は直線 (0,t,0) として定義できる
                        // ここでは、レイと直線の最短距離を計算する
                        
                        // レイの起点からY軸への方向ベクトル（X-Z平面上のみ）
                        vec2 a = vec2(ro.x, ro.z);
                        
                        // レイの方向ベクトル（X-Z平面上のみ）
                        vec2 b = vec2(rd.x, rd.z);
                        
                        // X-Z平面上での距離
                        float t = -dot(a, b) / dot(b, b);
                        
                        // t < 0ならレイの後ろにY軸がある
                        if (t < 0.0)return - 1.0;
                        
                        // Y軸までの最短距離
                        float xzDist = length(a + b * t);
                        
                        // ある程度の太さを持ったY軸として判定
                        float yAxisWidth = 0.04;
                        if (xzDist < yAxisWidth) {
                            // Y軸と交差している場合、交差点までの距離を返す
                            return t;
                        }
                        
                        return - 1.0; // 交差なし
                    }
                    
                    // ソフトシャドウの計算（最適化版）
                    float calcSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
                        float res = 1.0;
                        float t = mint;
                        float ph = 1e10; // 前回のh
                        
                        for(int i = 0; i < 32; i ++ ) { // 64から32に削減
                            if (t > maxt)break;
                            
                            float h = map(ro + rd * t);
                            
                            // 改善されたペナンブラ計算
                            float y = h*h / (2.0 * ph);
                            float d = sqrt(h * h-y * y);
                            res = min(res, k * d / max(0.0, t - y));
                            ph = h;
                            
                            t += h * 0.5; // ステップサイズを調整
                            
                            // 完全に影の場合は早期終了
                            if (res < 0.001)break;
                        }
                        
                        return res;
                    }
                    
                    // 法線を計算
                    vec3 calcNormal(vec3 p)
                    {
                        const float eps = 0.0001;
                        const vec2 h = vec2(eps, 0);
                        return normalize(vec3(
                                map(p + h.xyy) - map(p - h.xyy),
                                map(p + h.yxy) - map(p - h.yxy),
                                map(p + h.yyx) - map(p - h.yyx)
                            ));
                        }
                        
                        // 2D回転行列を適用する関数
                        mat2 rot2D(float angle) {
                            float s = sin(angle);
                            float c = cos(angle);
                            return mat2(c, - s, s, c);
                        }
                        
                        // 不穏なskyboxパターンを生成する関数
                        vec3 getSkyboxPattern(vec3 rd, float time) {
                            // 万華鏡効果のための方向ベクトルの変換
                            vec3 dir = rd;
                            float kaleidNum = 24.0; // 分割数を増加
                            
                            // 方向ベクトルを極座標に変換
                            float theta = atan(dir.z, dir.x);
                            float phi = atan(length(dir.xz), dir.y);
                            
                            // 万華鏡効果（角度の折り返し）を複数回適用
                            theta = mod(theta, 2.0 * PI / kaleidNum);
                            if (theta > PI / kaleidNum) {
                                theta = 2.0 * PI / kaleidNum - theta;
                            }
                            
                            // 垂直方向の反復パターン
                            phi = mod(phi * 4.0, PI); // 垂直方向の反復を4倍に
                            if (phi > PI / 2.0) {
                                phi = PI - phi;
                            }
                            
                            // 極座標を直交座標に戻す
                            float r = length(dir);
                            dir.x = r * cos(theta) * sin(phi);
                            dir.z = r * sin(theta) * sin(phi);
                            dir.y = r * cos(phi);
                            
                            // 基本となる方向ベクトルを時間とともに歪ませる（より複雑な回転）
                            dir.xy *= rot2D(sin(time * 0.5 + dir.z) * 0.8);
                            dir.yz *= rot2D(cos(time * 0.4 + dir.x) * 0.9);
                            dir.xz *= rot2D(sin(time * 0.6 + dir.y) * 0.7);
                            
                            // より細かいノイズパターンを生成
                            float n1 = smoothNoise(dir * 4.0 + vec3(time * 0.3));
                            float n2 = smoothNoise(dir * 8.0 - vec3(time * 0.35));
                            float n3 = smoothNoise(dir * 16.0 + vec3(time * 0.4));
                            float n4 = smoothNoise(dir * 32.0 - vec3(time * 0.25));
                            
                            // より鋭いエッジを作成
                            float edge1 = step(0.48, n1);
                            float edge2 = step(0.48, n2);
                            float edge3 = step(0.48, n3);
                            float edge4 = step(0.48, n4);
                            
                            // エッジパターンの合成（より均等な重み）
                            float pattern = edge1 * 0.25 + edge2 * 0.25 + edge3 * 0.25 + edge4 * 0.25;
                            
                            // 色の設定（より鮮やかな色の組み合わせ）
                            vec3 color1 = vec3(1.0, 0.0, 0.5); // マゼンタ系
                            vec3 color2 = vec3(0.0, 0.8, 1.0); // シアン系
                            vec3 color3 = vec3(1.0, 0.8, 0.0); // イエロー系
                            vec3 color4 = vec3(0.5, 1.0, 0.0); // ライムグリーン系
                            
                            // 時間に基づく色の変化（より規則的に）
                            float t1 = step(0.5, sin(time * 2.0 + dir.x * 5.0));
                            float t2 = step(0.5, cos(time * 2.0 + dir.y * 5.0));
                            float t3 = step(0.5, sin(time * 2.0 + dir.z * 5.0));
                            
                            // 色の混合（より規則的なパターン）
                            vec3 finalColor = mix(color1, color2, pattern);
                            finalColor = mix(finalColor, color3, step(0.5, smoothNoise(dir * 8.0 + vec3(time * 0.35))));
                            finalColor = mix(finalColor, color4, step(0.5, smoothNoise(dir * 12.0 - vec3(time * 0.27))));
                            
                            // 反復パターンの追加
                            vec2 repPattern = vec2(
                                step(0.5, sin(atan(dir.z, dir.x) * 32.0 + time * 2.0)), // 32分割
                                step(0.5, cos(atan(dir.y, length(dir.xz)) * 24.0 - time * 1.5))// 24分割
                            );
                            float repEffect = step(0.5, smoothNoise(vec3(repPattern * 8.0, time * 0.4)));
                            
                            // 同心円パターンの追加
                            float circles = step(0.5, sin(length(dir) * 40.0 - time * 2.0)); // 40個の同心円
                            
                            // パターンの合成
                            finalColor = mix(finalColor, color1, repEffect);
                            finalColor = mix(finalColor, color2, circles);
                            
                            // コントラストと彩度の調整
                            finalColor = pow(finalColor, vec3(0.4));
                            finalColor = clamp(finalColor * 2.0, 0.0, 1.0);
                            
                            // 彩度を4倍に
                            vec3 gray = vec3(dot(finalColor, vec3(0.299, 0.587, 0.114)));
                            finalColor = mix(gray, finalColor, 4.0);
                            finalColor = clamp(finalColor, 0.0, 1.0);
                            
                            // エッジ検出による境界強調
                            float edge = length(vec2(
                                    smoothNoise(dir + vec3(0.01, 0.0, 0.0)) - smoothNoise(dir - vec3(0.01, 0.0, 0.0)),
                                    smoothNoise(dir + vec3(0.0, 0.01, 0.0)) - smoothNoise(dir - vec3(0.0, 0.01, 0.0))
                                ));
                                
                                // エッジを強調
                                finalColor += vec3(1.0) * step(0.1, edge) * 0.5;
                                
                                return finalColor * 0.3;
                            }
                            
                            // 1つ目のPointLightの位置を計算する関数
                            vec3 getPointLightPosition(float time) {
                                // 基本となる円運動のパラメータ
                                float baseRadius = 8.0;
                                float baseHeight = 8.0;
                                
                                // 複数の周期を組み合わせた水平面での動き
                                float theta1 = time * 1.7; // 速い回転
                                float theta2 = time * 0.9; // 遅い回転
                                
                                // 高さの変動（より急激な動き）
                                float heightVar = sin(time * 2.5) * 3.0;
                                float height = baseHeight + heightVar;
                                
                                // 水平面での位置の計算（ハードな動き）
                                float x = baseRadius * sign(sin(theta1)) * abs(cos(theta2));
                                float z = baseRadius * sign(cos(theta1)) * abs(sin(theta2));
                                
                                return vec3(x, height, z);
                            }
                            
                            // 2つ目のPointLightの位置を計算する関数（高速バージョン）
                            vec3 getSpeedyLightPosition(float time) {
                                // 基本となる円運動のパラメータ（より小さな半径）
                                float baseRadius = 6.0;
                                float baseHeight = 6.0;
                                
                                // より速い回転と複雑な動き
                                float theta1 = time * 3.4; // 2倍速い回転
                                float theta2 = time * 2.1; // より速い第二の回転
                                
                                // 高さの変動（より急激で頻繁な動き）
                                float heightVar = sin(time * 4.0) * 2.0 + cos(time * 3.0) * 1.5;
                                float height = baseHeight + heightVar;
                                
                                // 水平面での位置の計算（より急激な動き）
                                float x = baseRadius * sign(sin(theta1 * 1.2)) * abs(cos(theta2 * 0.8));
                                float z = baseRadius * sign(cos(theta1 * 0.8)) * abs(sin(theta2 * 1.2));
                                
                                return vec3(x, height, z);
                            }
                            
                            // カメラの設定を計算する関数
                            vec3 calculateCameraPosition(float time, int cameraId) {
                                float baseRadius = 17.0; // 基本の回転半径
                                
                                if (cameraId == 0) {
                                    // カメラ0: ダイナミックな円運動（より大きな半径と高さ変化）
                                    float radius = baseRadius * 1.2;
                                    float height = 6.0 + sin(time * 0.4) * 4.0;
                                    return vec3(
                                        radius * cos(time * -0.3),
                                        height,
                                        radius * sin(time * -0.3)
                                    );
                                }
                                else if (cameraId == 1) {
                                    // カメラ1: 高速スパイラル運動（より複雑な軌道）
                                    float t = time * 0.8;
                                    float spiralRadius = baseRadius * (0.7 + 0.3 * sin(t * 0.5));
                                    float heightOffset = 20.0 + sin(t * 0.7) * 8.0;
                                    return vec3(
                                        spiralRadius * cos(t),
                                        heightOffset,
                                        spiralRadius * sin(t * 1.3)// 非対称な動き
                                    );
                                }
                                else if (cameraId == 2) {
                                    // カメラ2: 低い位置からの8の字運動（より極端な視点）
                                    float t = time * 0.4;
                                    return vec3(
                                        baseRadius * 0.8 * sin(t),
                                        max(3.0, 4.0 + sin(time * 0.6) * 2.0),
                                        baseRadius * 0.6 * sin(t * 2.0)
                                    );
                                }
                                else {
                                    // カメラ3: カオティックな軌道（より予測不可能な動き）
                                    float t = time * 0.5;
                                    float chaosRadius = baseRadius * (1.0 + 0.4 * sin(t * 1.7));
                                    return vec3(
                                        chaosRadius * sin(t) * cos(t * 0.7),
                                        max(5.0, 12.0 + cos(t * 0.9) * 6.0),
                                        chaosRadius * cos(t) * sin(t * 0.6)
                                    );
                                }
                            }
                            
                            void mainImage(out vec4 fragColor, in vec2 fragCoord)
                            {
                                vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
                                
                                // カメラの切り替え時間を設定
                                float switchDuration = 5.0; // 各カメラの持続時間
                                float blendDuration = 1.0; // ブレンド時間
                                
                                // 現在のカメラIDを計算
                                float totalTime = mod(iTime, switchDuration * 4.0); // 4つのカメラでループ
                                int currentCam = int(totalTime / switchDuration);
                                int nextCam = (currentCam + 1)% 4;
                                
                                // ブレンド係数を計算
                                float camTime = mod(totalTime, switchDuration);
                                float blend = smoothstep(switchDuration - blendDuration, switchDuration, camTime);
                                
                                // 2つのカメラ位置を計算
                                vec3 ro1 = calculateCameraPosition(iTime, currentCam);
                                vec3 ro2 = calculateCameraPosition(iTime, nextCam);
                                
                                // カメラ位置をブレンド
                                vec3 ro = mix(ro1, ro2, blend);
                                
                                // 注視点をキューブの位置に設定
                                vec3 target = getFlyingCubePosition(iTime);
                                
                                // カメラの向きを計算
                                vec3 forward = normalize(target - ro);
                                vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
                                vec3 up = cross(forward, right);
                                
                                // レイの方向を計算
                                vec3 rd = normalize(forward + right * uv.x + up * uv.y);
                                
                                // レイマーチング
                                float t = 0.0;
                                float tmax = 80.0;
                                float epsilon = 0.0002;
                                float nearClip = 0.15; // ニアクリップ距離
                                
                                // 初期位置をニアクリップ位置に設定
                                t = nearClip;
                                
                                // 球体からの影響を蓄積
                                vec3 sphereInfluence = vec3(0.0);
                                float totalDensity = 0.0;
                                
                                // レイマーチングループの最適化
                                for(int i = 0; i < 64; i ++ ) { // 100から64に削減
                                    vec3 p = ro + rd * t;
                                    float d = map(p);
                                    
                                    // 球体からの影響を計算（簡略化）
                                    if (d < epsilon || t > tmax)break;
                                    
                                    // より大きなステップサイズを使用
                                    t += d * 0.8; // より積極的なステップ
                                }
                                
                                // 色を設定
                                vec3 col = vec3(0.0);
                                float alpha = 1.0;
                                
                                // 物体に当たった場合
                                if (t < tmax) {
                                    vec3 p = ro + rd * t;
                                    vec3 n = calcNormal(p);
                                    float material = getMaterial(p);
                                    
                                    // 1つ目のPointLightの位置と効果
                                    vec3 lightPos1 = getPointLightPosition(iTime);
                                    vec3 lightColor1 = vec3(1.0, 0.9, 0.8) * 2.0;
                                    float lightIntensity1 = 5.0;
                                    
                                    vec3 lightDir1 = normalize(lightPos1 - p);
                                    float lightDistance1 = length(lightPos1 - p);
                                    float attenuation1 = 1.0 / (1.0 + 0.1 * lightDistance1 + 0.01 * lightDistance1 * lightDistance1);
                                    
                                    // 2つ目のPointLight（高速バージョン）の位置と効果
                                    vec3 lightPos2 = getSpeedyLightPosition(iTime);
                                    vec3 lightColor2 = vec3(0.8, 1.0, 0.9) * 1.5; // より弱い青みがかった光
                                    float baseIntensity2 = 2.0; // 基本強度を弱めに
                                    
                                    // 高速な明滅効果（複数の周期を組み合わせる）
                                    float strobe1 = sin(iTime * 8.0) * 0.5 + 0.5; // 8Hzの明滅
                                    float strobe2 = sin(iTime * 12.0) * 0.5 + 0.5; // 12Hzの明滅
                                    float strobe3 = sin(iTime * 15.0) * 0.5 + 0.5; // 15Hzの明滅
                                    float strobeEffect = (strobe1 * 0.4 + strobe2 * 0.3 + strobe3 * 0.3) * 0.8 + 0.2; // 0.2-1.0の範囲
                                    
                                    float lightIntensity2 = baseIntensity2 * strobeEffect;
                                    
                                    vec3 lightDir2 = normalize(lightPos2 - p);
                                    float lightDistance2 = length(lightPos2 - p);
                                    float attenuation2 = 1.0 / (1.0 + 0.1 * lightDistance2 + 0.01 * lightDistance2 * lightDistance2);
                                    
                                    // 基本の光源方向
                                    vec3 baseLight = normalize(vec3(1.0, 0.50, - 1.0));
                                    float baseDiff = max(dot(n, baseLight), 0.0);
                                    
                                    // オブジェクトの色を設定
                                    vec3 objColor;
                                    if (material < 0.5) { // 地面
                                        if (SHOW_GRID) {
                                            // グリッド描画関数を呼び出し
                                            vec4 gridResult = drawGrid(p, t);
                                            objColor = gridResult.rgb * 0.3; // グリッドを暗く
                                        } else {
                                            objColor = vec3(0.0);
                                        }
                                    } else if (material < 1.5) { // 球体
                                        objColor = vec3(0.5); // 暗めの白色
                                    } else if (material < 2.05) { // グリッドキューブ本体
                                        // グリッドの位置に基づいて色を変化
                                        vec3 cellIndex = floor((p + 0.5 * vec3(6.0)) / vec3(6.0));
                                        objColor = getCubeColor(cellIndex, iTime) * 0.5; // 色を半分の明るさに
                                        float blinkFactor = blink(cellIndex, iTime);
                                        objColor *= blinkFactor;
                                    } else if (material < 4.5) { // 親キューブと子キューブ
                                        // 基本の虹色効果（暗めに）
                                        objColor = vec3(
                                            0.3 + 0.3 * sin(iTime * 1.1),
                                            0.3 + 0.3 * sin(iTime * 1.3 + PI * 0.5),
                                            0.3 + 0.3 * sin(iTime * 1.5 + PI)
                                        ) * 0.5;
                                        
                                        // 子キューブの場合は色をさらに暗く
                                        if (material > 4.05) {
                                            float childIndex = (material - 4.1) / 0.045; // 0から19
                                            objColor *= mix(0.7, 0.2, childIndex / 19.0); // より暗く
                                        }
                                        
                                        // 反射計算の最適化（反射の回数を減らす）
                                        vec3 reflectDir = reflect(rd, n);
                                        
                                        // 反射レイマーチングの簡略化
                                        vec3 reflectPos = p + n * 0.002;
                                        float reflectT = 0.0;
                                        float maxReflectDist = 10.0; // 20.0から10.0に短縮
                                        vec3 reflectCol = vec3(0.0);
                                        bool hitSomething = false;
                                        
                                        // 反射レイマーチングの回数を削減
                                        for(int i = 0; i < 32; i ++ ) { // 50から32に削減
                                            vec3 rp = reflectPos + reflectDir * reflectT;
                                            float rd = map(rp);
                                            
                                            if (rd < epsilon) {
                                                hitSomething = true;
                                                float rMaterial = getMaterial(rp);
                                                
                                                // 反射色の計算を簡略化
                                                if (rMaterial < 0.5) {
                                                    reflectCol = vec3(0.05);
                                                } else {
                                                    reflectCol = vec3(0.3);
                                                }
                                                break;
                                            }
                                            
                                            reflectT += rd * 0.8; // より積極的なステップ
                                            if (reflectT > maxReflectDist)break;
                                        }
                                        
                                        // 反射しなかった場合は簡略化された空の色
                                        if (!hitSomething) {
                                            reflectCol = vec3(0.2);
                                        }
                                        
                                        // フレネル効果と色の合成（簡略化）
                                        float fresnel = pow(1.0 - max(0.0, dot(n, - rd)), 3.0); // 5.0から3.0に変更
                                        objColor = mix(objColor, reflectCol, 0.4 + fresnel * 0.2);
                                        
                                        // 鏡面ハイライトの追加（弱めに）
                                        float specular = pow(max(dot(reflectDir, baseLight), 0.0), 16.0);
                                        objColor += vec3(0.5) * specular * 0.2;
                                    } else if (material < 3.5) { // 回転する平面
                                        // 平面の色を時間とともに変化させる
                                        objColor = vec3(
                                            0.5 + 0.5 * sin(iTime * 0.7),
                                            0.5 + 0.5 * sin(iTime * 0.9 + PI * 0.5),
                                            0.5 + 0.5 * sin(iTime * 1.1 + PI)
                                        ) * 0.3; // 暗めに設定
                                        
                                        // 反射効果を追加
                                        vec3 reflectDir = reflect(rd, n);
                                        vec3 reflectCol = getSkyboxPattern(reflectDir, iTime);
                                        float fresnel = pow(1.0 - max(0.0, dot(n, - rd)), 3.0);
                                        objColor = mix(objColor, reflectCol, 0.5 + fresnel * 0.3);
                                        
                                        // 鏡面ハイライトを追加
                                        float specular = pow(max(dot(reflectDir, baseLight), 0.0), 16.0);
                                        objColor += vec3(0.3) * specular * 0.2;
                                    } else { // 未使用
                                        objColor = vec3(1.0);
                                    }
                                    
                                    // 両方のPointLightからの寄与を計算
                                    float pointDiff1 = max(dot(n, lightDir1), 0.0);
                                    float pointDiff2 = max(dot(n, lightDir2), 0.0);
                                    vec3 pointLightContribution =
                                    lightColor1 * pointDiff1 * attenuation1 * lightIntensity1 +
                                    lightColor2 * pointDiff2 * attenuation2 * lightIntensity2;
                                    
                                    // 環境光+拡散光（暗めに）
                                    if (material < 0.5) { // 地面
                                        col = objColor * (0.5 + 0.3 * baseDiff + pointLightContribution);
                                    } else {
                                        col = objColor * (0.2 + 0.4 * baseDiff + pointLightContribution);
                                    }
                                    
                                    // ソフトシャドウを計算
                                    float shadow = calcSoftShadow(p + n * 0.002, baseLight, 0.02, 2.0, 16.0); // パラメータを調整
                                    
                                    // ライティング計算（簡略化）
                                    col = objColor * (0.2 + 0.4 * baseDiff);
                                    col = col * mix(vec3(0.2), vec3(1.0), shadow);
                                    
                                    // ポイントライトの影響（簡略化）
                                    col += lightColor1 * pointDiff1 * attenuation1 * lightIntensity1 * 0.5
                                    + lightColor2 * pointDiff2 * attenuation2 * lightIntensity2 * 0.5;
                                } else {
                                    // 背景色（簡略化）
                                    col = getSkyboxPattern(rd, iTime) * 0.3;
                                }
                                
                                // 球体の影響を加算（弱めに）
                                if (t < tmax) {
                                    col += sphereInfluence * 0.5;
                                }
                                
                                // 透明なグリッドを描画（物体がない場合でもグリッドは表示）
                                if (SHOW_GRID) {
                                    float tGrid = intersectGrid(ro, rd);
                                    if (tGrid > 0.0 &&(t > tmax || tGrid < t)) {
                                        // グリッドとの交差点
                                        vec3 gridPos = ro + rd * tGrid;
                                        
                                        // グリッドの色を取得（カメラからの距離も渡す）
                                        vec4 gridResult = drawGrid(gridPos, tGrid);
                                        
                                        // アルファブレンディング
                                        if (gridResult.a > 0.001) {
                                            col = mix(col, gridResult.rgb, gridResult.a);
                                            alpha = max(alpha, gridResult.a); // グリッドのアルファ値を反映
                                        }
                                    }
                                    
                                    // Y軸との交差を計算
                                    float tYAxis = intersectYAxis(ro, rd);
                                    if (tYAxis > 0.0 &&(t > tmax || tYAxis < t)) {
                                        // Y軸との交差点
                                        vec3 yAxisPos = ro + rd * tYAxis;
                                        
                                        // Y軸の高さに応じたフェードアウト
                                        float yHeight = abs(yAxisPos.y);
                                        float yFade = 1.0 - clamp(yHeight / 10.0, 0.0, 1.0);
                                        
                                        // Y軸の色（緑）
                                        vec3 yAxisColor = vec3(0.0, 0.7, 0.0) * yFade;
                                        float yAxisAlpha = 0.8 * yFade;
                                        
                                        // アルファブレンディング
                                        col = mix(col, yAxisColor, yAxisAlpha);
                                        alpha = max(alpha, yAxisAlpha); // Y軸のアルファ値を反映
                                    }
                                }
                                
                                // ガンマ補正（より暗く）
                                col = pow(col, vec3(0.6));
                                
                                // Output to screen
                                fragColor = vec4(col, alpha);
                            }