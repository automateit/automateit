@ rem "which" workalike for Windows. Searches current directory and PATH for all extensions, stops after first match, and returns meaningful exit value for "system" or "ERRORLEVEL" checks.
@setlocal
@set P2=.;%PATH%
@for %%e in (%PATHEXT%) do @for %%i in (%1%%e) do @if NOT "%%~$P2:i"=="" echo %%~$P2:i && goto end
@rem REM This exits the shell on failure, so don't use it directly
@exit 1
:end
