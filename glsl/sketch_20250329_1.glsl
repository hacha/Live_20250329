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
    // 極座標のパラメータ
    float radius = 5.0; // 回転半径
    float theta = time * 0.7; // 水平面での角度
    float phi = time * 0.5; // 垂直方向の角度
    float height = 5.0; // 基準となる高さ
    
    // 極座標から直交座標への変換
    vec3 basePos = vec3(
        radius * cos(theta), // x座標
        height + 2.0 * sin(phi + PI * 0.5), // y座標
        radius * sin(theta)// z座標
    );
    
    return basePos;
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
    
    // 飛び回るキューブの処理
    vec3 cubePos = getFlyingCubePosition(iTime);
    
    vec3 cubeSize = vec3(2.0); // キューブのサイズを2倍に
    
    // キューブの回転
    vec3 rotatedP = p - cubePos;
    rotatedP = rotateMatrix(normalize(vec3(1.0, 1.0, 1.0)), iTime) * rotatedP;
    
    // キューブの距離計算
    float cubeDist = sdBox(rotatedP, cubeSize);
    
    // キューブの距離と材質IDを更新
    if (cubeDist < res.x) {
        res = vec2(cubeDist, 4.0); // 材質ID 4.0 を飛び回るキューブに割り当て
    }
    
    // レペテーションの設定
    float spacing = 6.0; // 球体間の距離
    vec3 repetition = vec3(spacing);
    vec3 q = mod(p + 0.5 * repetition, repetition) - 0.5 * repetition;
    
    // オリジナルの位置を保存（マテリアルIDの変更に使用）
    vec3 cellIndex = floor((p + 0.5 * repetition) / repetition);
    
    // 球体の位置
    vec3 spherePos = vec3(0.0, 1.0, 0.0);
    // グリッドごとに異なる上下運動を追加
    float wobbleSpeed = dot(cellIndex, vec3(0.7, 0.9, 1.1)); // グリッドごとに異なる速度
    float wobbleRange = 0.75; // 上下の振幅
    spherePos.y += wobbleRange * sin(iTime * 0.25 + wobbleSpeed); // ゆっくりとした上下運動
    
    vec3 localP = q - spherePos;
    
    // 球体の距離計算
    float sphereRadius = 0.6;
    
    // キューブとの距離を計算
    float distToCube = length(p - cubePos) - 2.0; // キューブのサイズを考慮
    
    // キューブに近い場合、球体を縮小
    float shrinkRange = 4.0; // 縮小が始まる距離
    float shrinkFactor = smoothstep(0.0, shrinkRange, distToCube);
    float dynamicRadius = sphereRadius * mix(0.2, 1.0, shrinkFactor); // 最小で元のサイズの20%まで縮小
    
    float objDist = length(localP) - dynamicRadius;
    
    // キューブに近い場合、球体を変形
    float cubeInfluenceRange = 5.0; // 変形が始まる距離
    float cubeInfluenceFactor = smoothstep(cubeInfluenceRange, 0.0, distToCube);
    objDist = mix(objDist, distToCube * 0.5, cubeInfluenceFactor); // キューブに向かって徐々に変形
    
    // 地面からの距離に応じたスムージング
    float groundDistance = spherePos.y;
    float smoothRange = 1.2;
    float smoothFactor = smoothstep(0.0, smoothRange, groundDistance);
    objDist = mix(length(localP) - sphereRadius * 1.5, objDist, smoothFactor);
    
    // オブジェクトの距離と材質IDを更新
    if (objDist < res.x) {
        res = vec2(objDist, 2.0);
    }
    
    // 地面（平面）
    float planeDist = p.y;
    if (planeDist < res.x) {
        res = vec2(planeDist, 0.0);
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

// ソフトシャドウの計算
float calcSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    
    for(int i = 0; i < 64; i ++ ) {
        if (t > maxt)break;
        
        float h = map(ro + rd * t);
        
        // h < 0.001 の条件は削除し、常にソフトシャドウの計算を行う
        float s = clamp(k * h / t, 0.0, 1.0);
        res = min(res, s);
        
        // 完全に影の場合は早期終了
        if (res < 0.005)break;
        
        // 距離に応じてステップサイズを調整
        t += max(0.01, h);
    }
    
    // 影をさらに滑らかにする
    return smoothstep(0.0, 1.0, res);
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
    
    void mainImage(out vec4 fragColor, in vec2 fragCoord)
    {
        // Normalized pixel coordinates (from 0 to 1)
        vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
        
        // カメラの設定
        float camRadius = 17.0; // カメラの回転半径
        float camHeight = 4.2; // カメラの基本の高さを3.2から4.2に変更
        float camSpeed = -0.2; // カメラの回転速度
        float camVerticalSpeed = 0.15; // カメラの上下運動の速度
        float camVerticalRange = 4.0; // カメラの上下運動の範囲
        
        // 注視点をキューブの位置に設定
        vec3 target = getFlyingCubePosition(iTime);
        
        // カメラの位置を計算（球体の周りを円を描いて回転）
        vec3 ro = vec3(
            camRadius * cos(iTime * camSpeed),
            max(1.0, camHeight + camVerticalRange * sin(iTime * camVerticalSpeed)), // 最低高度を1.0に制限
            camRadius * sin(iTime * camSpeed)
        );
        
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
        
        for(int i = 0; i < 100; i ++ ) {
            vec3 p = ro + rd * t;
            float d = map(p);
            
            // 球体からの影響を計算
            vec3 cellIndex = floor((p + 0.5 * vec3(6.0)) / vec3(6.0));
            vec3 q = mod(p + 0.5 * vec3(6.0), vec3(6.0)) - 0.5 * vec3(6.0);
            vec3 spherePos = vec3(0.0, 1.0, 0.0);
            vec3 localP = q - spherePos;
            float sphereDist = length(localP) - 1.0;
            
            // 球体の色を取得
            vec3 baseColor = vec3(
                0.5 + 0.5 * sin(cellIndex.x * 1.5),
                0.5 + 0.5 * sin(cellIndex.y * 1.7 + 2.0),
                0.5 + 0.5 * sin(cellIndex.z * 1.9 + 4.0)
            );
            vec3 sphereColor = baseColor * vec3(0.6, 0.8, 1.0);
            
            // 点滅効果を適用
            float blinkFactor = blink(cellIndex, iTime);
            sphereColor *= blinkFactor;
            
            // 距離に基づいて影響を計算
            float influence = smoothstep(2.0, 0.0, abs(sphereDist));
            influence *= 0.1; // 影響の強さを調整
            
            // 影響を蓄積
            sphereInfluence += sphereColor * influence;
            totalDensity += influence;
            
            // 十分に近づいたか、遠すぎる場合は終了
            if (d < epsilon || t > tmax)break;
            
            // 距離を進める
            t += d;
        }
        
        // 色を設定
        vec3 col = vec3(0.0); // 背景色（真っ黒）
        float alpha = 1.0;
        
        // 物体に当たった場合
        if (t < tmax) {
            vec3 p = ro + rd * t;
            vec3 n = calcNormal(p);
            float material = getMaterial(p);
            
            // オブジェクトの色を設定
            vec3 objColor;
            if (material < 0.5) { // 地面
                if (SHOW_GRID) {
                    // グリッド描画関数を呼び出し
                    vec4 gridResult = drawGrid(p, t);
                    objColor = gridResult.rgb;
                } else {
                    // グリッドを表示しない場合は単色
                    objColor = vec3(0.0);
                }
            } else if (material < 1.5) { // 球体
                objColor = vec3(1.0, 1.0, 1.0); // 白色
            } else if (material < 2.05) { // 球体本体
                // グリッドの位置に基づいて色を変化
                vec3 cellIndex = floor((p + 0.5 * vec3(6.0)) / vec3(6.0));
                vec3 baseColor = vec3(
                    0.5 + 0.5 * sin(cellIndex.x * 1.5),
                    0.5 + 0.5 * sin(cellIndex.y * 1.7 + 2.0),
                    0.5 + 0.5 * sin(cellIndex.z * 1.9 + 4.0)
                );
                objColor = baseColor * vec3(0.6, 0.8, 1.0);
                float blinkFactor = blink(cellIndex, iTime);
                objColor *= blinkFactor;
            } else if (material < 4.5) { // 飛び回るキューブ
                // 時間に基づいて色が変化する虹色のような効果
                objColor = vec3(
                    0.5 + 0.5 * sin(iTime * 1.1),
                    0.5 + 0.5 * sin(iTime * 1.3 + PI * 0.5),
                    0.5 + 0.5 * sin(iTime * 1.5 + PI)
                ) * 0.75; // ベース色を暗くする
                
                // 反射レイの計算
                vec3 reflectDir = reflect(rd, n);
                
                // 反射レイのレイマーチング
                vec3 reflectPos = p + n * 0.002; // 表面から少し離す
                float reflectT = 0.0;
                float maxReflectDist = 20.0;
                vec3 reflectCol = vec3(0.0);
                bool hitSomething = false;
                
                // 反射レイのレイマーチング
                for(int i = 0; i < 50; i ++ ) {
                    vec3 rp = reflectPos + reflectDir * reflectT;
                    float rd = map(rp);
                    
                    if (rd < epsilon) {
                        // 物体にヒット
                        hitSomething = true;
                        float rMaterial = getMaterial(rp);
                        
                        // 反射した先の物体の色を取得
                        if (rMaterial < 0.5) { // 地面
                            reflectCol = vec3(0.1); // 暗い地面
                        } else if (rMaterial < 2.5) { // 球体
                            vec3 cellIndex = floor((rp + 0.5 * vec3(6.0)) / vec3(6.0));
                            reflectCol = vec3(
                                0.5 + 0.5 * sin(cellIndex.x * 1.5),
                                0.5 + 0.5 * sin(cellIndex.y * 1.7 + 2.0),
                                0.5 + 0.5 * sin(cellIndex.z * 1.9 + 4.0)
                            ) * vec3(0.6, 0.8, 1.0) * blink(cellIndex, iTime);
                        }
                        break;
                    }
                    
                    reflectT += rd;
                    if (reflectT > maxReflectDist)break;
                }
                
                // 反射しなかった場合は空の色（暗めのグラデーション）
                if (!hitSomething) {
                    float skyGrad = 0.5 + 0.5 * reflectDir.y;
                    reflectCol = vec3(0.4, 0.5, 0.6) * skyGrad;
                }
                
                // フレネル効果の計算
                float fresnel = pow(1.0 - max(0.0, dot(n, - rd)), 5.0);
                
                // 最終的な色の合成
                objColor = mix(objColor, reflectCol, 0.8 + fresnel * 0.2);
                
                // 鏡面ハイライトの追加
                vec3 light = normalize(vec3(1.0, 0.50, - 1.0));
                float specular = pow(max(dot(reflectDir, light), 0.0), 32.0);
                objColor += vec3(1.0) * specular * 0.5;
            } else { // 未使用
                objColor = vec3(1.0);
            }
            
            // 単純な拡散照明
            vec3 light = normalize(vec3(1.0, 0.50, - 1.0));
            float diff = max(dot(n, light), 0.0);
            
            // 環境光+拡散光
            if (material < 0.5) { // 地面の場合はグリッドラインを強調するため拡散を抑える
                col = objColor * (0.9 + 0.1 * diff);
            } else {
                col = objColor * (0.3 + 0.7 * diff);
            }
            
            // ソフトシャドウを計算
            float shadow = calcSoftShadow(p + n * 0.002, light, 0.02, 5.0, 16.0);
            
            // 光源の強度と色
            vec3 lightColor = vec3(1.0, 0.9, 0.8);
            
            // 影を適用（ソフトシャドウ）
            col = col * mix(vec3(0.2), lightColor, shadow);
        }
        
        // 球体の影響を加算
        col += sphereInfluence;
        
        // 透明なグリッドを描画
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
            }
        }
        
        // ガンマ補正
        col = pow(col, vec3(0.4545));
        
        // Output to screen
        fragColor = vec4(col, alpha);
    }