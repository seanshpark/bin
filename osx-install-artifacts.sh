#!/bin/sh
GIT_BASE=~/git
CORECLR_BASE=$GIT_BASE/coreclr
COREFX_BASE=$GIT_BASE/corefx
CLI_BASE=$GIT_BASE/cli

TARGET=~/dotnet/osx.NETCore

mkdir -p $TARGET/runtime
mkdir -p $TARGET/packages
cd $TARGET

#find $CORECLR_BASE/bin/Product/OSX.x64.Debug -name *.exe -exec cp -a {} $TARGET/runtime \;
find $CORECLR_BASE/bin/Product/OSX.x64.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $CORECLR_BASE/bin/Product/OSX.x64.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;

cp -a $CORECLR_BASE/bin/Product/OSX.x64.Debug/corerun $TARGET/runtime/
cp -a $CORECLR_BASE/bin/Product/OSX.x64.Debug/*.dylib $TARGET/runtime/
#cp -a $CORECLR_BASE/bin/Product/OSX.x64.Debug/libcoreclr.so $TARGET~/runtime/
#cp -a $CORECLR_BASE/bin/Product/OSX.x64.Debug/mscorlib.dll $TARGET~/runtime/
#cp -a $CORECLR_BASE/bin/Product/OSX.x64.Debug/System.Globalization.Native.so $TARGET~/runtime/

#find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.exe -exec cp -a {} $TARGET/runtime \;
find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
find $COREFX_BASE/bin/Unix.AnyCPU.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $COREFX_BASE/bin/AnyOS.AnyCPU.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;

find $COREFX_BASE/bin/OSX.AnyCPU.Debug -name *.dll -exec cp -a {} $TARGET/runtime \;
####find $COREFX_BASE/bin/OSX.AnyCPU.Debug -name *.pdb -exec cp -a {} $TARGET/runtime \;
#cp -a $COREFX_BASE/bin/OSX.AnyCPU.Debug/System.Console/System.Console.dll $TARGET/runtime/
#cp -a $COREFX_BASE/bin/OSX.AnyCPU.Debug/System.Diagnostics.Debug/System.Diagnostics.Debug.dll $TARGET/runtime/
cp -a $COREFX_BASE/bin/OSX.x64.Debug/Native/*.dylib $TARGET/runtime/
cp -a $COREFX_BASE/bin/OSX.x64.Debug/Native/*.a $TARGET/runtime/

cd $TARGET/runtime
mkdir tests
mv *.Tests.dll tests
