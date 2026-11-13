@echo off
rem Lancer le prototype sans GPU : Godot rend via Mesa (llvmpipe) sur le CPU.
setlocal
set GALLIUM_DRIVER=llvmpipe
start "" "%~dp0godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" --resolution 512x911 --rendering-driver opengl3 --windowed
endlocal
