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
    
    // HSVに変換
    vec3 hsv = rgb2hsv(baseColor);
    
    // 時間による色相の変化
    hsv.x = mod(hsv.x + sin(time * 0.5) * 0.2, 1.0);
    
    // HSVをRGBに戻す
    return hsv2rgb(hsv);
}

// 子球体の位置を計算する関数
vec3 getChildCubePosition(vec3 parentPos, float time, float delay) {
    // 親の位置から少し遅れて追従
    float delayedTime = time - delay;
    vec3 basePos = getFlyingCubePosition(delayedTime);
    
    // フレーム内での相対位置（0.0から1.0）
    float framePosition = delay / (0.15 * 20.0); // 20は子球体の総数
    
    // インデックスが深いほど、より大きな周回半径と遅い速度（距離を10%縮小）
    float orbitRadius = mix(8.1, 32.4, framePosition); // 9.0->8.1, 36.0->32.4 (10%減)
    float orbitSpeed = mix(1.5, 0.8, framePosition); // 速度は維持
    
    // より複雑な周回運動の計算
    float angle = delayedTime * orbitSpeed;
    float verticalAngle = angle * 0.7; // 垂直方向の角度は水平より遅く
    
    // らせん状の軌道を計算（一定距離を保つ）
    vec3 orbit = vec3(
        cos(angle) * orbitRadius,
        sin(verticalAngle) * orbitRadius * 0.3, // 高さの変化を30%に抑制
        sin(angle) * orbitRadius
    );
    
    // 親の位置を中心とした周回運動
    vec3 orbitPos = parentPos + orbit;
    
    // 親の位置と周回位置をブレンド（追従性を調整）
    float followStrength = mix(0.7, 0.3, framePosition); // 追従の強さを維持
    vec3 finalPos = mix(orbitPos, basePos, followStrength);
    
    // 親との距離を一定に保つ
    vec3 toParent = finalPos - parentPos;
    float currentDist = length(toParent);
    float targetDist = orbitRadius + 5.4; // 6.0->5.4 (10%減)
    
    // 距離の補正（スムーズに）
    float distanceCorrection = smoothstep(targetDist * 0.8, targetDist * 1.2, currentDist);
    finalPos = parentPos + normalize(toParent) * mix(targetDist, currentDist, distanceCorrection);
    
    return finalPos;
}

// キューブの痙攣的な拡縮を計算する関数
vec3 getConvulsiveScale(float time) {
    // 複数の高周波ノイズを合成（周波数を2倍に）
    float n1 = smoothNoise(vec3(time * 16.0, 0.0, 0.0)); // 16Hz
    float n2 = smoothNoise(vec3(time * 24.0, 1.0, 0.0)); // 24Hz
    float n3 = smoothNoise(vec3(time * 30.0, 2.0, 0.0)); // 30Hz
    float n4 = smoothNoise(vec3(time * 40.0, 3.0, 0.0)); // 40Hz
    
    // 急激な変化のためのステップ関数（より大きな変化を許容）
    float s1 = step(0.5, n1) * 0.5; // 0.3から0.5に増加
    float s2 = step(0.6, n2) * 0.4; // 0.2から0.4に増加
    float s3 = step(0.4, n3) * 0.45; // 0.25から0.45に増加
    float s4 = step(0.55, n4) * 0.35; // 0.15から0.35に増加
    
    // 基本スケール（2.0）に不規則な変動を加える（変動幅を増加）
    float baseScale = 2.0;
    float xScale = baseScale * (1.0 + s1 + s2 - s3 + s4) * 1.2; // 20%増幅
    float yScale = baseScale * (1.0 - s2 + s3 + s1 - s4) * 1.2;
    float zScale = baseScale * (1.0 + s3 - s1 + s4 - s2) * 1.2;
    
    return vec3(xScale, yScale, zScale);
}

// カメラの設定を計算する関数
vec3 calculateCameraPosition(float time, int cameraId) {
    float baseRadius = 17.0; // 基本の回転半径
    
    // フォーカス対象の位置を取得
    vec3 targetPos;
    float focusTime = 3.0; // フォーカスの切り替え間隔
    float focusIndex = floor(time / focusTime);
    float focusPhase = fract(time / focusTime);
    
    // ハッシュ関数を使用してランダムな子球体のインデックスを生成（毎フレーム変化）
    float randomChildIndex = floor(
        mix(
            hash(vec3(focusIndex)),
            hash(vec3(focusIndex + 1.0)),
            smoothstep(2.0, 2.8, mod(time, focusTime))// 切り替え前に次の子球体を選択
        ) * 40.0
    );
    float childDelay = 0.15 * (randomChildIndex + 1.0);
    
    // フォーカス対象を決定（偶数回は親、奇数回はランダムな子）
    vec3 parentPos = getFlyingCubePosition(time);
    vec3 childPos = getChildCubePosition(parentPos, time, childDelay);
    targetPos = mod(focusIndex, 2.0) < 1.0 ? parentPos : childPos;
    
    vec3 cameraPos;
    if (cameraId == 0) {
        // カメラ0: ターゲットを中心とした円運動
        float radius = baseRadius * 0.8;
        float height = 6.0 + sin(time * 0.4) * 2.0;
        cameraPos = targetPos + vec3(
            radius * cos(time * -0.3),
            height,
            radius * sin(time * -0.3)
        );
    }
    else if (cameraId == 1) {
        // カメラ1: ターゲットを中心としたスパイラル
        float t = time * 0.8;
        float spiralRadius = baseRadius * (0.7 + 0.3 * sin(t * 0.5));
        float heightOffset = 10.0 + sin(t * 0.7) * 4.0;
        cameraPos = targetPos + vec3(
            spiralRadius * cos(t),
            heightOffset,
            spiralRadius * sin(t * 1.3)
        );
    }
    else if (cameraId == 2) {
        // カメラ2: ターゲットを中心とした低い位置からの8の字
        float t = time * 0.4;
        cameraPos = targetPos + vec3(
            baseRadius * 0.8 * sin(t),
            max(3.0, 4.0 + sin(time * 0.6) * 2.0),
            baseRadius * 0.6 * sin(t * 2.0)
        );
    }
    else {
        // カメラ3: ターゲットを中心としたカオティックな軌道
        float t = time * 0.5;
        float chaosRadius = baseRadius * (1.0 + 0.4 * sin(t * 1.7));
        cameraPos = targetPos + vec3(
            chaosRadius * sin(t) * cos(t * 0.7),
            max(5.0, 8.0 + cos(t * 0.9) * 3.0),
            chaosRadius * cos(t) * sin(t * 0.6)
        );
    }
    
    // グローバルな上下の揺れを追加
    float globalYOffset = sin(time * 0.1) * 15.0; // 0.1Hzでゆっくりと15.0の振幅で揺れる
    cameraPos.y += globalYOffset;
    
    return cameraPos;
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

vec2 mapObjects(vec3 p) {
    // 立方体の位置と回転
    vec3 cubePos = vec3(0.0);
    vec3 rotatedP = p - cubePos;
    rotatedP = rotateMatrix(normalize(vec3(1.0, 1.0, 1.0)), iTime) * rotatedP;
    
    // 立方体のサイズと距離計算
    vec3 cubeSize = vec3(3.0);
    float cubeDist = sdBox(rotatedP, cubeSize);
    
    // 立方体のマテリアルIDを設定（5.0以上）
    return vec2(cubeDist, 5.0);
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
    
    // 2D回転行列を適用する関数
    mat2 rot2D(float angle) {
        float s = sin(angle);
        float c = cos(angle);
        return mat2(c, - s, s, c);
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
    
    void mainImage(out vec4 fragColor, in vec2 fragCoord) {
        vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
        
        // フィッシュアイレンズ効果の実装
        float baseStrength = 15.5;
        float bpm = 125.0 / 4.0;
        float fourOnFloor = (bpm / 60.0) * 4.0; // 120BPMの4つ打ち = 8Hz
        
        // キックドラムのような強いアクセント
        float kick = step(0.0, sin(iTime * PI * fourOnFloor)) * 10.8;
        
        // よりスムーズなサイドチェーンエフェクト
        float sidechain = pow(abs(sin(iTime * PI * fourOnFloor)), 0.3) * 0.5;
        
        // リズミカルな効果の合成
        float rhythmEffect = kick + sidechain;
        
        float fishEyeStrength = baseStrength + rhythmEffect * 2.0;
        vec2 fishEyeUV = uv * (1.0 + fishEyeStrength * length(uv));
        
        // カメラの設定
        vec3 ro = vec3(0.0, 5.0, - 10.0); // カメラ位置
        vec3 target = vec3(0.0); // 注視点
        
        // カメラの向きを計算
        vec3 forward = normalize(target - ro);
        vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
        vec3 up = cross(forward, right);
        
        // レイの方向を計算（フィッシュアイ効果を適用）
        vec3 rd = normalize(forward + right * fishEyeUV.x + up * fishEyeUV.y);
        
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
            vec3 objColor = mix(color1, color2, mixFactor);
            
            // フレネル効果
            float fresnel = pow(1.0 - max(0.0, dot(n, - rd)), 3.0);
            objColor *= (0.8 + fresnel * 0.4);
            
            // ライティング計算
            col = objColor * (0.2 + 0.4 * baseDiff);
            
            // ソフトシャドウ
            float shadow = calcSoftShadow(p + n * 0.002, baseLight, 0.02, 2.0, 16.0);
            col = col * mix(vec3(0.2), vec3(1.0), shadow);
        } else {
            // 背景色
            col = vec3(0.0);
        }
        
        // ガンマ補正
        col = pow(col, vec3(0.6));
        
        // 出力
        fragColor = vec4(col, alpha);
    }