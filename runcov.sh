#!/bin/bash
#
# Execution simulation with code coverage
#
# by Jorge Ouahbi (Pandemic of 2020)
#

rm -rf sonar-reports
mkdir sonar-reports

xcodebuild clean -UseModernBuildSystem=NO -verbose build-for-testing -project Example.xcodeproj -scheme Example -destination platform="iOS Simulator",id=0196251E-5C16-4CC6-BC7E-03C7682F7DB3,OS=13.5 -destination-timeout 360 COMPILER_INDEX_STORE_ENABLE=NO > xcodebuild.log

#cat xcodebuild.log | xcpretty -r json-compilation-database -o compile_commands.json

xcodebuild test -project Example.xcodeproj -scheme Example -configuration Debug -enableCodeCoverage YES -destination platform="iOS Simulator",id=0196251E-5C16-4CC6-BC7E-03C7682F7DB3,OS=13.5 -destination-timeout 60 > sonar-reports/xcodebuild.log

slather coverage -i .*Tests.* --input-format profdata --cobertura-xml --output-directory sonar-reports --scheme Example Example.xcodeproj

mv sonar-reports/cobertura.xml sonar-reports/coverage-swift.xml

lizard --xml "." > sonar-reports/lizard-report.xml

sonar-scanner -Dsonar.host.url=http://localhost:9000 --define sonar.projectVersion=2.2.15
