cd ../../../flutter
flutter build linux
cd ../build/flutter/linux_arm64
tar -czvf oxigen_protocol_explorer_3_linux_arm64.tar.gz --directory=../../../flutter/build/linux/arm64/release/bundle .
