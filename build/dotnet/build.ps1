dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output linux-arm --self-contained --runtime linux-arm
dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output linux-arm64 --self-contained --runtime linux-arm64
dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output linux-x64 --self-contained --runtime linux-x64
dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output win-x64 --self-contained --runtime win-x64
dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output win-x86 --self-contained --runtime win-x86
dotnet publish ../../dotnet/oXigenProtocolExplorer3/oXigenProtocolExplorer3.csproj --configuration Release --output osx-x64 --self-contained --runtime osx-x64

pause
