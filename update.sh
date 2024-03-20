#!/bin/sh
cd flutter_pcsc_platform_interface
flutter pub upgrade
cd ..
cd flutter_pcsc_macos
flutter pub upgrade
cd ..
cd flutter_pcsc_linux
flutter pub upgrade
cd ..
cd flutter_pcsc_windows
flutter pub upgrade
cd ..
cd flutter_pcsc
flutter pub upgrade
cd example
flutter pub upgrade
