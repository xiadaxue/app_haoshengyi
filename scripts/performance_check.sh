#!/bin/bash

echo "启动Flutter性能分析..."
flutter run --profile --trace-startup

echo "生成性能日志..."
flutter build apk --profile
cd build
flutter trace-to-timeline timeline.json timeline.timeline
