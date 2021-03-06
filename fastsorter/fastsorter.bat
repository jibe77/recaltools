@echo off
color 3f
set releaseDate=30.12.2016
title fastsorter ver. %releaseDate%

rem Copy sorted files into destination folder? [Y/N]
set "copyMode=y"
if /i "%copyMode%"=="y" (set appendTitle=[Copy Mode]) else set appendTitle=[Log Mode]

rem Set prefix for output file (used only if copyMode=n)
set prefixMiss=missing_in_

rem Set defaults to launch directory
set rootSource=%~dp0
set rootFolder=%~dp0

:listSources
title fastsorter ver. %releaseDate% - Source file selection %appendTitle%
rem Show folder names in current directory
echo Available sources for sorting:
for /f "delims=: tokens=1*" %%a in ('dir /b /a-d *.txt^| findstr /n "^"') do (
  set "mapArray[%%a]=%%b"
  set "count=%%a"
  echo %%a: %%b
)

:checkSources
set type=source
setlocal EnableDelayedExpansion
if not exist !mapArray[1]! cls & echo No source file (.txt) found on current directory! & goto SUB_folderBrowser
if %count% gtr 1 set /a browser=%count%+1 & echo.!browser!: Open Folder Browser? & goto whichSource
if %count% equ 1 echo. & set /p "oneSource=Use !mapArray[1]! as source? [Y/N]: "
if /i "%oneSource%"=="y" (set "sourceFile=1" & echo. & goto listFolders) else goto SUB_folderBrowser

:whichSource
echo.
rem Select source file (.txt)
echo Which one is the source file you want to use? Choose %browser% to change directory.
set /p "sourceFile=#: "
if %sourceFile% equ %browser% goto SUB_folderBrowser
setlocal EnableDelayedExpansion
if exist !mapArray[%sourceFile%]! echo. & goto listFolders
echo Incorrect input^^! & goto whichSource

:listFolders
setlocal DisableDelayedExpansion
title fastsorter ver. %releaseDate% - System folder selection %appendTitle%
rem Show folder names in current directory
cd %~dp0
set count=0
echo Available folders for sorting:
for /f "delims=: tokens=1*" %%a in ('dir /b /a:d ^| findstr /n "."') do (
  set "mapArray2[%%a]=%%b"
  set "count=%%a"
  echo %%a: %%b
)

:checkFolders
set type=root
setlocal EnableDelayedExpansion
if not exist !mapArray2[1]! cls & echo No folders found on current directory! & goto SUB_folderBrowser
if %count% gtr 1 set /a browser=%count%+1 & echo.!browser!: Open Folder Browser? & goto whichSystem
if %count% equ 1 echo. & set /p "oneFolder=Use !mapArray2[1]! as target? [Y/N]: "
if /i "%oneFolder%"=="y" (set "whichSystem=1" & goto whichFolder) else goto SUB_folderBrowser

:whichSystem
echo.
rem Select system folder
echo Which system do you want to sort? Choose %browser% to change directory.
set /p "whichSystem=#: "
if %whichSystem% equ %browser% goto SUB_folderBrowser
setlocal EnableDelayedExpansion
if exist !mapArray2[%whichSystem%]! echo. & goto createFolder
echo Incorrect input^^! & goto whichSystem

:createFolder
rem Create destination folder
if /i not "%copyMode%"=="y" goto sortFiles
set destFolder=!mapArray[%sourceFile%]:~0,-4!
if not exist ".\!mapArray2[%whichSystem%]!\!destFolder!" md ".\!mapArray2[%whichSystem%]!\!destFolder!"

:sortFiles
rem Look inside the source file and copy the files to the destination folder
title fastsorter ver. %releaseDate% - Sorting files in progress... %appendTitle%
set system=!mapArray2[%whichSystem%]!
for /f "delims=" %%a in ('type "%rootSource%\!mapArray[%sourceFile%]!"') do (
	setlocal DisableDelayedExpansion
	if exist ".\%system%\%%a" (
		if /i "%copyMode%"=="y" copy ".\%system%\%%a" ".\%system%\%destFolder%\%%a" >nul
		echo %%a
	) else (
		echo.
		echo %%a missing & echo.
		if /i not "%copyMode%"=="y" echo %%a >> "%~dp0%prefixMiss%%system%.txt"
		)
	endlocal
)

title fastsorter ver. %releaseDate% - Sorting files finished! %appendTitle%

popd & pause >nul & exit

:SUB_folderBrowser
setlocal DisableDelayedExpansion
if %count% lss 1 set /p "openBrowser=Open Folder Browser? [Y/N]: "
if %count% lss 1 (
	if not "%openBrowser%"=="y" exit
)
set count=0 & echo Opening Folder Browser... & echo.
if "%type%"=="root" echo Select the root system folder, not the system itself!

rem PowerShell-Subroutine to open a Folder Browser
set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please choose a %type% folder.',0,0).self.path""
for /f "usebackq delims=" %%i in (`powershell %psCommand%`) do set "newRoot=%%i"

if "%type%"=="source" set rootSource=%newRoot%
if "%type%"=="root" set rootFolder=%newRoot%

rem Change working directory
if "%type%"=="source" cls & pushd %rootSource% & goto listSources
if "%type%"=="root" cls & pushd %rootFolder% & setlocal EnableDelayedExpansion & echo Selected source file: !mapArray[%sourceFile%]! & echo. & goto listFolders
