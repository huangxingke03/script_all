#!/bin/bash

cd ~/work/code/workCode/kp31/VoiceAssistant/VoiceAssistantApiService || exit 1
echo "切换API库根目录 ： /VoiceAssistant/VoiceAssistantApiService"

echo "========== 开始打包 VoiceAssistantApi =========="

SDK_NAME="VoiceAssistantApi"
DEFAULT_SDK_VERSION="1.8.5"
RAW_VERSION_INPUT="${1:-}"
OUTPUT_DIR="libs"
SOURCE_JAR="build/intermediates/aar_main_jar/release/classes.jar"
GRADLE_CMD="gradle"
BUILD_TASK="build"

normalize_version() {
    local raw_version="$1"

    if [ -z "$raw_version" ]; then
        echo "$DEFAULT_SDK_VERSION"
        return 0
    fi

    if [[ "$raw_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$raw_version"
        return 0
    fi

    if [[ "$raw_version" =~ ^[0-9]{3}$ ]]; then
        echo "${raw_version:0:1}.${raw_version:1:1}.${raw_version:2:1}"
        return 0
    fi

    echo "错误: 版本号格式不支持: ${raw_version}" >&2
    echo "支持示例: 1.8.7 或 187" >&2
    return 1
}

SDK_VERSION="$(normalize_version "$RAW_VERSION_INPUT")" || exit 1
JAR_NAME="${SDK_NAME}_${SDK_VERSION}.jar"

if [ -x "../gradlew" ]; then
    GRADLE_CMD="../gradlew"
elif [ -x "./gradlew" ]; then
    GRADLE_CMD="./gradlew"
fi

if [ -n "$RAW_VERSION_INPUT" ]; then
    if [ "$RAW_VERSION_INPUT" != "$SDK_VERSION" ]; then
        echo "使用自定义版本号：${RAW_VERSION_INPUT} -> ${SDK_VERSION}"
    else
        echo "使用自定义版本号：${SDK_VERSION}"
    fi
else
    echo "使用默认版本号：${SDK_VERSION}"
    echo "可通过以下方式自定义版本号：./make_voice_assistant_api_kp31.sh 1.8.6"
    echo "也支持简写：187 -> 1.8.7，211 -> 2.1.1"
fi

echo "使用构建命令：${GRADLE_CMD} ${BUILD_TASK}"
echo "正在打包 class 文件..."

if ! "$GRADLE_CMD" "$BUILD_TASK" --quiet; then
    echo "❌ 打包失败，Gradle 构建未通过"
    exit 1
fi

if [ ! -f "$SOURCE_JAR" ]; then
    echo "❌ 打包失败，未找到源码 jar：${SOURCE_JAR}"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "打包完成，正在生成目标 jar..."

if [ -f "${OUTPUT_DIR}/${JAR_NAME}" ]; then
    echo "删除已有同名包：${OUTPUT_DIR}/${JAR_NAME}"
    rm -f "${OUTPUT_DIR}/${JAR_NAME}"
fi

cp "$SOURCE_JAR" "${OUTPUT_DIR}/${JAR_NAME}"

if [ $? -ne 0 ]; then
    echo "❌ 复制 jar 失败"
    exit 1
fi

echo "✅ 打包成功！"
echo "输出文件：${OUTPUT_DIR}/${JAR_NAME}"
ls -lh "$OUTPUT_DIR"
