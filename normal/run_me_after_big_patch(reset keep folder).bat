REM Quick deleting old backup folder keep

CD keep

if errorlevel 1 (
	pause
	exit
)

DEL /F/Q/S *.* > NUL

if errorlevel 1 (
	pause
	exit
)

CD ..

if errorlevel 1 (
	pause
	exit
)

RMDIR /Q/S keep

