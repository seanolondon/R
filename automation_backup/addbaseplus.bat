@Echo off
SET LOGFILE=MyLogFile.log
call :Logit >> %LOGFILE% 
exit /b 0
:Logit

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\abaseplus_automation_v0.99.R"