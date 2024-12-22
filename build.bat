:: --------------------------------------
:: Batch to deploy 
::

@echo off
set curdir=%cd%


:: basic settings
set copyRoot=..\..\Coding
set root=.

set host=tasmota-test02-635c38-7224

:: copy from master repo
if exist "%copyRoot%" (
copy /y %copyRoot%\Common\B03Stateman.be .
)

call :upload autoexec.be
call :upload B03StateMan.be
call :upload Demo.be


goto :eof

:: ------------- Sub-routines

:upload
 ::echo upload: got %1
 curl -v "http://%host%/ufsd?delete=/%1"  > NUL
 curl -v --form "ufsu=@%1" "http://%host%/ufsu" > NUL
 goto :eof




