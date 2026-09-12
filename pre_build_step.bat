@echo off
py "%~dp0datafiles\Shaders\shader_replace.py"
py "%~dp0datasrc\update.py"
py "%~dp0pre_run.py"
