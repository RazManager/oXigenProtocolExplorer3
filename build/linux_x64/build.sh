cd ../../flutter
flutter build linux
cd ../build/linux_x64
tar -czvf oxigen_protocol_explorer_3-linux-x64.tar.gz --directory=../../flutter/build/linux/x64/release/bundle .