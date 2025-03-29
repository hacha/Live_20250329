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

// 球体のSDF
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// スムーズミニマム関数
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// FBMのノイズ関数
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float n = i.x + i.y * 157.0 + 113.0 * i.z;
    return mix(
        mix(
            mix(hash(vec3(n + 0.0)), hash(vec3(n + 1.0)), f.x),
            mix(hash(vec3(n + 157.0)), hash(vec3(n + 158.0)), f.x),
        f.y),
        mix(
            mix(hash(vec3(n + 113.0)), hash(vec3(n + 114.0)), f.x),
            mix(hash(vec3(n + 270.0)), hash(vec3(n + 271.0)), f.x),
        f.y),
    f.z);
}

// FBM（Fractional Brownian Motion）関数
float fbm(vec3 p) {
    float f = 0.0;
    float amp = 1.75;
    float freq = 1.0;
    
    // 時間による急激な変化の制御
    float timeScale = 1.0 + step(0.7, sin(iTime * 0.5)) * 3.0; // 時折3倍速に
    float ampScale = 1.0 + step(0.8, sin(iTime * 0.7)) * 2.0; // 時折振幅2倍に
    
    for(int i = 0; i < 5; i ++ ) {
        // 不規則な周波数変調
        float freqMod = 1.0 + sin(iTime * freq * 0.3) * 0.5;
        f += amp * noise(p * freq * freqMod * timeScale);
        
        // より急激な変化のための周波数とアンプの更新
        freq *= 2.0 * (1.0 + sin(iTime * 0.2) * 0.3); // 周波数の変化を不規則に
        amp *= 0.5 * ampScale;
    }
    
    return f;
}

vec2 mapObjects(vec3 p) {
    // 立方体の位置と回転
    vec3 cubePos = vec3(0.0);
    vec3 rotatedP = p - cubePos;
    rotatedP = rotateMatrix(normalize(vec3(1.0, 1.0, 1.0)), iTime) * rotatedP;
    
    // チェッカーパターンの計算
    float checkerScale = 6.5;
    vec3 checkerP = rotatedP * checkerScale;
    float checker = step(0.0, sin(checkerP.x) * sin(checkerP.y)) *
    step(0.0, sin(checkerP.y) * sin(checkerP.z)) *
    step(0.0, sin(checkerP.z) * sin(checkerP.x));
    
    // 立方体のサイズと距離計算
    vec3 cubeSize = vec3(3.0);
    float cubeDist = sdBox(rotatedP, cubeSize);
    
    // 白いチェッカー部分に球体を配置
    float sphereRadius = 0.15;
    float sphereOffset = 0.2;
    float sphereDist = 1e10;
    
    if (checker > 0.5) {
        // 立方体の表面の法線方向を計算
        vec3 normal = normalize(rotatedP);
        // 球体の位置を法線方向に少しオフセット
        vec3 spherePos = rotatedP - normal * sphereOffset;
        sphereDist = sdSphere(spherePos, sphereRadius);
        
        // 球体と立方体の距離をスムーズに結合
        float k = 0.1; // ブレンド係数
        cubeDist = smin(cubeDist, sphereDist, k);
    }
    
    // FBMディスプレイスメントとチェッカーパターンの組み合わせ
    float timeFactor = 0.2 * (1.0 + step(0.75, sin(iTime * 0.3)) * 4.0);
    float displacement = fbm(rotatedP * 1.5 + iTime * timeFactor) * 0.95;
    displacement *= mix(0.8, 1.2, checker);
    
    cubeDist -= displacement;
    
    // マテリアルIDの決定（距離に基づいて）
    float materialId;
    if (checker > 0.5 && sphereDist < cubeDist + sphereOffset) {
        materialId = 7.0; // 球体のマテリアル
    } else {
        materialId = mix(5.0, 6.0, checker); // チェッカーパターンのマテリアル
    }
    
    return vec2(cubeDist, materialId);
}

// シーンの距離関数
float map(vec3 p) {
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
    
    for(int i = 0; i < 32; i ++ ) {
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
vec3 calcNormal(vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(
            map(p + h.xyy) - map(p - h.xyy),
            map(p + h.yxy) - map(p - h.yxy),
            map(p + h.yyx) - map(p - h.yyx)
        ));
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
    
    // カラーグレーディング
    vec3 colorGrading(vec3 color) {
        // コントラストの強化
        float contrast = 1.2;
        color = pow(color, vec3(contrast));
        
        // 彩度の調整
        vec3 hsv = rgb2hsv(color);
        hsv.y *= 1.3; // 彩度を30%増加
        color = hsv2rgb(hsv);
        
        // 暖かみの追加
        vec3 warmth = vec3(0.1, 0.05, 0.0);
        color += warmth * (1.0 - color); // ハイライトへの影響を抑制
        
        return color;
    }
    
    // ナバホ族の幾何学模様を生成する関数
    vec3 navajoPattern(vec2 uv, float time) {
        // スケールの調整
        uv *= 4.0;
        
        // 時間による緩やかな移動
        uv.x += sin(time * 0.1) * 0.5;
        uv.y += cos(time * 0.08) * 0.5;
        
        // 基本グリッドの作成
        vec2 id = floor(uv);
        vec2 gv = fract(uv) - 0.5;
        
        // ダイヤモンドパターンの基本形
        float diamond = abs(gv.x) + abs(gv.y);
        
        // ジグザグパターン
        float zigzag = sin(uv.x * 3.0 + time * 0.2) * cos(uv.y * 3.0 + time * 0.15);
        
        // 階段パターン
        float stairs = step(0.5, fract((uv.x + uv.y) * 2.0));
        
        // パターンの組み合わせ
        float pattern = mix(diamond, zigzag, 0.5) + stairs * 0.3;
        
        // ハッシュ関数を使用してランダムな変化を追加
        float h = hash(vec3(id, time * 0.1));
        
        // 色の設定（ナバホ族の伝統的な色）
        vec3 col1 = vec3(0.8, 0.4, 0.2); // テラコッタ
        vec3 col2 = vec3(0.2, 0.1, 0.05); // ダークブラウン
        vec3 col3 = vec3(0.9, 0.8, 0.6); // サンド
        
        // パターンに基づいて色を混ぜる
        vec3 finalColor = mix(col1, col2, pattern);
        finalColor = mix(finalColor, col3, stairs * h);
        
        // 全体的な暗さの調整（背景として控えめに）
        return finalColor * 0.15;
    }
    
    // カメラポイントを取得する関数
    vec3 getCameraPoint(float index) {
        // 8つのカメラポイントを定義
        if (index < 1.0)return vec3(0.0, 5.0, - 10.0); // 正面やや上から
        if (index < 2.0)return vec3(10.0, 5.0, - 5.0); // 右前上から
        if (index < 3.0)return vec3(10.0, 2.0, 0.0); // 右側から
        if (index < 4.0)return vec3(10.0, 5.0, 5.0); // 右後ろ上から
        if (index < 5.0)return vec3(0.0, 5.0, 10.0); // 背面やや上から
        if (index < 6.0)return vec3(-10.0, 5.0, 5.0); // 左後ろ上から
        if (index < 7.0)return vec3(-10.0, 2.0, 0.0); // 左側から
        return vec3(-10.0, 5.0, - 5.0); // 左前上から
    }
    
    // ピクセルグリッチエフェクト
    vec3 pixelGlitch(vec3 color, vec2 uv, float time) {
        // グリッドサイズの定義（時間とともに変化）
        float gridSize = 20.0 + sin(time * 0.5) * 10.0;
        vec2 grid = floor(uv * gridSize) / gridSize;
        
        // ノイズ生成
        float noise = hash(vec3(grid * 50.0, time));
        float glitchStr = step(0.95, noise); // グリッチの発生確率
        
        // RGB分離効果
        float rOffset = sin(grid.x * 10.0 + time) * 0.02;
        float gOffset = cos(grid.y * 10.0 - time) * 0.02;
        float bOffset = sin((grid.x + grid.y) * 15.0 + time) * 0.02;
        
        // カラーシフト
        vec3 glitchColor;
        glitchColor.r = color.r + rOffset * glitchStr;
        glitchColor.g = color.g + gOffset * glitchStr;
        glitchColor.b = color.b + bOffset * glitchStr;
        
        // ランダムなカラーノイズ
        vec3 randomColor = vec3(
            hash(vec3(grid * 1.1, time)),
            hash(vec3(grid * 2.2, time)),
            hash(vec3(grid * 3.3, time))
        );
        
        // 時間に基づくグリッチラインの生成
        float line = step(0.98, sin(grid.y * 100.0 + time * 5.0));
        
        // 最終的なグリッチ効果の合成
        return mix(
            glitchColor,
            randomColor,
            (glitchStr * 0.5 + line * 0.3) * step(0.8, noise)
        );
    }
    
    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
        vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
        
        // カメラの切り替え周期（8秒）
        float period = 8.0;
        float cameraIndex = floor(mod(iTime, period * 8.0) / period);
        
        // 現在のカメラポイントと次のカメラポイントを取得
        vec3 currentCam = getCameraPoint(cameraIndex);
        vec3 nextCam = getCameraPoint(mod(cameraIndex + 1.0, 8.0));
        
        // スムーズな遷移のための補間
        float transition = smoothstep(0.0, 1.0, fract(iTime / period));
        vec3 ro = mix(currentCam, nextCam, transition);
        
        vec3 target = vec3(0.0); // 注視点は中心に固定
        
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
        
        // レイマーチングループ
        for(int i = 0; i < 64; i ++ ) {
            vec3 p = ro + rd * t;
            float d = map(p);
            
            if (d < epsilon || t > tmax)break;
            t += d * 0.8;
        }
        
        // 色を設定
        vec3 col = vec3(0.0);
        float alpha = 1.0;
        
        // 物体に当たった場合
        if (t < tmax) {
            vec3 p = ro + rd * t;
            vec3 n = calcNormal(p);
            float material = getMaterial(p);
            
            // マテリアルに基づいて色を変更
            vec3 baseColor;
            if (material > 6.5) {
                // 球体の色（金属的な光沢）
                baseColor = vec3(0.8, 0.7, 0.5);
            } else {
                // チェッカーパターンの色
                baseColor = (material > 5.5) ? vec3(0.9, 0.9, 0.9) : vec3(0.2, 0.2, 0.2);
            }
            
            // 基本の光源方向
            vec3 baseLight = normalize(vec3(1.0, 0.50, - 1.0));
            float baseDiff = max(dot(n, baseLight), 0.0);
            
            // 反射方向を計算
            vec3 reflectDir = reflect(rd, n);
            
            // 波動効果のパラメータ
            float waveFreq = 3.0;
            float waveAmp = 0.3;
            float waveSpeed = 2.0;
            
            // 波動関数
            float wave1 = sin(rd.x * waveFreq + iTime * waveSpeed) * waveAmp;
            float wave2 = cos(rd.y * waveFreq * 1.3 + iTime * waveSpeed * 0.7) * waveAmp;
            float wave3 = sin((rd.x + rd.y) * waveFreq * 0.8 - iTime * waveSpeed * 1.2) * waveAmp;
            
            // 波動効果の合成
            vec2 waveOffset = vec2(wave1 + wave2, wave2 + wave3);
            
            // 変調パラメータ
            float modulateFreq = 2.0;
            float modulateAmp = 0.4;
            float modulateSpeed = 1.5;
            
            // 変調効果
            float modulation1 = sin(iTime * modulateSpeed + rd.x * modulateFreq) * modulateAmp;
            float modulation2 = cos(iTime * modulateSpeed * 1.2 + rd.y * modulateFreq * 0.8) * modulateAmp;
            
            // レイ方向を波動と変調で歪ませる
            vec2 distortedRay = rd.xy + waveOffset + vec2(modulation1, modulation2);
            
            // 時間に基づく色相の変化
            float hue1 = iTime * 0.1 + wave1 * 0.2 + modulation1 * 0.3;
            float hue2 = -iTime * 0.15 + wave2 * 0.2 + modulation2 * 0.3;
            
            // HSVからRGBへの変換
            vec3 color1 = hsv2rgb(vec3(fract(hue1), 0.8, 0.3));
            vec3 color2 = hsv2rgb(vec3(fract(hue2), 0.7, 0.25));
            
            // レイの方向に基づいて色を混ぜる
            float mixFactor = smoothstep(-0.5, 0.5, dot(rd.xy, vec2(cos(iTime * 0.3), sin(iTime * 0.4))));
            vec3 objColor = mix(color1, color2, mixFactor) * baseColor;
            
            // フレネル効果の強化（球体用）
            float fresnel = pow(1.0 - max(0.0, dot(n, - rd)), material > 6.5 ? 5.0 : 3.0);
            objColor *= material > 6.5 ? (0.6 + fresnel * 0.8) : (0.8 + fresnel * 0.4);
            
            // ライティング計算
            col = objColor * (0.2 + 0.4 * baseDiff);
            
            // ソフトシャドウ
            float shadow = calcSoftShadow(p + n * 0.002, baseLight, 0.02, 2.0, 16.0);
            col = col * mix(vec3(0.2), vec3(1.0), shadow);
        } else {
            // 背景にナバホ族の模様を適用
            vec2 bgUV = rd.xy / rd.z;
            col = navajoPattern(bgUV, iTime);
        }
        
        // ガンマ補正の前にトーンマッピングとカラーグレーディングを適用
        col = toneMapping(col);
        col = colorGrading(col);
        
        // ピクセルグリッチエフェクトの適用
        vec2 glitchUV = fragCoord / iResolution.xy;
        col = pixelGlitch(col, glitchUV, iTime);
        
        // ガンマ補正
        col = pow(col, vec3(0.6));
        
        // ビネット効果の追加
        vec2 q = fragCoord / iResolution.xy;
        col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);
        
        // 出力
        fragColor = vec4(col, alpha);
    }