@echo off
rem Lance le jeu dans le navigateur : serveur local + ouverture automatique.
rem Fermer la fenetre noire arrete le jeu.
setlocal
cd /d "%~dp0"

set PY=python
where python >nul 2>nul || set PY="C:\Users\Isl4m\.workbuddy-ai\binaries\python\versions\3.13.12\python.exe"

%PY% "%~dp0tools\jouer.py"
if errorlevel 1 pause
endlocal
