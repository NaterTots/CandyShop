@echo off
set "CANDY_GODOT=C:\Users\hodge\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%CANDY_GODOT%" (
  echo Godot was moved. Import project.godot in Godot 4.7.2 and press F6 or F5.
  pause
  exit /b 1
)
start "Candy Shop" "%CANDY_GODOT%" --path "%~dp0."
