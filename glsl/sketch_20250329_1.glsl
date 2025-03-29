// for shadertoy

// グリッド表示の設定
#define SHOW_GRID true
#define GRID_MAX_DISTANCE 15.0 // グリッドが見える最大距離
#define PI 3.1415926535897932384626433832795

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
    
    // 時間に基づく球体の軌道の計算
    float orbitRadius = 3.0;
    float orbitHeight = 1.0;
    float orbitSpeed = 0.5;
    vec3 spherePos = vec3(
        orbitRadius * cos(iTime * orbitSpeed),
        orbitHeight * sin(iTime * orbitSpeed * 0.7) + 1.0,
        orbitRadius * sin(iTime * orbitSpeed)
    );
    
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
        vec3 ro = vec3(0.0, 2.0, - 7.0); // Ray origin (カメラ位置)
        vec3 rd = normalize(vec3(uv, 1.0)); // Ray direction
        
        // カメラ回転
        float theta = PI / 4.0;
        mat3 rot = mat3(
            cos(theta), 0.0, sin(theta),
            0.0, 1.0, 0.0,
            - sin(theta), 0.0, cos(theta)
        );
        rd = rot * rd;
        ro = rot * ro;
        
        // レイマーチング
        float t = 0.0;
        float tmax = 20.0;
        float epsilon = 0.001;
        
        for(int i = 0; i < 100; i ++ ) {
            vec3 p = ro + rd * t;
            float d = map(p);
            
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
            } else { // 箱
                objColor = vec3(1.0, 1.0, 1.0); // 白色
            }
            
            // 単純な拡散照明
            vec3 light = normalize(vec3(1.0, 2.0, - 1.0));
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