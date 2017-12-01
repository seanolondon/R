@Echo off
SET LOGFILE=MyLogFile.log
call :Logit >> %LOGFILE% 
exit /b 0
:Logit

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddSeptember.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddJuly.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddJune.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddApril.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddMarch.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddFebruary.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddDecember.R"

PATH C:\Program Files\R\R-3.4.1\bin;%path%
Rscript "D:\FME Scheduled_tasks\R_tasks\AddNovember.R"