@ECHO OFF

ECHO Egobot looper v0.1

:WHILE
  luvit egobot.lua
  
  REM ECHO %ERRORLEVEL%
  
  IF ERRORLEVEL 255 GOTO CRASH
  IF ERRORLEVEL 44  GOTO STOP
  IF ERRORLEVEL 43  GOTO RESTART
  IF ERRORLEVEL 42  GOTO UPDATE
  GOTO STOP
  
  :CRASH
    ECHO Restarting Egotbot after crash...
    GOTO WHILE
  :RESTART
    ECHO Retarting Egobot...
    GOTO WHILE
  :UPDATE
    ECHO Updating Egobot...
    git pull
    GOTO WHILE
  
GOTO WHILE

:STOP
ECHO Exiting Egobot...