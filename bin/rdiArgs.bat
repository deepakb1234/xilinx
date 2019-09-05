rem #
rem # COPYRIGHT NOTICE
rem # Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
rem #

if not defined RDI_ARGS_FUNCTION (
  goto SETUP
) else (
  goto %RDI_ARGS_FUNCTION%
)

:SETUP
  rem #
  rem # Default to OS platform options
  rem #
  if [%RDI_OS_ARCH%] == [64] (
    set RDI_PLATFORM=win64
  ) else (
    set RDI_PLATFORM=win32
  )

  set RDI_ARGS=
  if defined RDI_BYPASS_ARGS (
      set RDI_ARGS=%*
      set RDI_PROG=%RDI_BYPASS_ARGS%
      set RDI_BYPASS_ARGS=
      goto argsParsed
  )
  :parseArgs
    if [%1] == [] (
      goto argsParsed
    ) else (
    if [%1] == [-m32] (
      set RDI_PLATFORM=win32
    ) else (
    if [%1] == [-m64] (
      if [%RDI_OS_ARCH%] == [64] (
        set RDI_PLATFORM=win64
      ) else (
        echo WARNING: 64bit architecture not detected. Defaulting to 32bit.
      )
    ) else (
    if [%1] == [-exec] (
      set RDI_PROG=%2
      shift
    ) else (
    if [%1] == [-mode] (
      set RDI_ARGS=%RDI_ARGS% %1
      if [%2] == [batch] (
        set RDI_BATCH_MODE=True
        set RDI_ARGS=!RDI_ARGS! %2
        shift
      )
    ) else (
    if [%1] == [-version] (
      if [%_RDI_NEEDS_VERSION%] == [True] (
        set RDI_ARGS_FUNCTION=RDI_EXEC_PRODVERSION
      ) else (
        set RDI_ARGS=%RDI_ARGS% %1
      )     
    ) else (
      set RDI_ARGS=%RDI_ARGS% %1
    ))))))
    shift
    goto parseArgs
  :argsParsed

  if [%RDI_VERBOSE%] == [] (
    set RDI_VERBOSE=False
  )

  rem # Default don't check TclDebug
  if [%XIL_CHECK_TCL_DEBUG%] == [] (
    set XIL_CHECK_TCL_DEBUG=False
  )

  set RDI_DATADIR=%RDI_APPROOT%/data
  set TEMP_PATCHROOT=!RDI_PATCHROOT!
  :TOKEN_LOOP_DATADIR
  for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
    if exist "%%d/data" (
      set RDI_DATADIR=%%d/data;!RDI_DATADIR!
    )
  )
  :CHARPOP_DATADIR
  set CHARPOP=!TEMP_PATCHROOT:~0,1!
  set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
  if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_DATADIR
  if "!CHARPOP!" NEQ ";" goto CHARPOP_DATADIR
  goto TOKEN_LOOP_DATADIR
  :END_TOKEN_LOOP_DATADIR

  set RDI_JAVA_VERSION=9.0.4
  if defined RDI_NEED_OLD_JRE (
    set RDI_JAVA_VERSION=
    set RDI_NEED_OLD_JRE=
  )
  set RDI_JAVAROOT=%RDI_APPROOT%/tps/%RDI_PLATFORM%/jre%RDI_JAVA_VERSION%

  rem #Locate RDI_JAVAROOT in patch areas.
  set TEMP_PATCHROOT=!RDI_PATCHROOT!
  :TOKEN_LOOP_PROG
  for /F "delims=;" %%d in ("!TEMP_PATCHROOT!") do (
    if exist "%%d/tps/%RDI_PLATFORM%/jre%RDI_JAVA_VERSION%" (
      set RDI_JAVAROOT=%%d/tps/%RDI_PLATFORM%/jre%RDI_JAVA_VERSION%
    )
  )
  :CHARPOP_PROG
  set CHARPOP=!TEMP_PATCHROOT:~0,1!
  set TEMP_PATCHROOT=!TEMP_PATCHROOT:~1!
  if "!TEMP_PATCHROOT!" EQU "" goto END_TOKEN_LOOP_PROG
  if "!CHARPOP!" NEQ ";" goto CHARPOP_PROG
  goto TOKEN_LOOP_PROG
  :END_TOKEN_LOOP_PROG
  rem # Silly syntax requires something after a label

  rem #
  rem # Strip /planAhead off %RDI_APPROOT% to discovery the
  rem # common ISE installation.
  rem #
  rem # For separated vivado installs ISE is located under %RDI_APPROOT%/ids_lite
  rem #
  if not [%XIL_PA_NO_XILINX_OVERRIDE%] == [1] (
    if not [%XIL_PA_NO_DEFAULT_OVERRIDE%] == [1] (
      set XILINX=
    )
    if exist "%RDI_APPROOT%/ids_lite/ISE" (
      set XILINX=%RDI_APPROOT%/ids_lite/ISE
    ) else (
      if exist "%RDI_BASEROOT%/ISE" (
        set XILINX=%RDI_BASEROOT%/ISE
      )
    )
  )

  set RDI_SETUP_ENV_FUNCTION=BASENAME
  call "%RDI_BINROOT%/setupEnv.bat" "%RDI_APPROOT%" RDI_INSTALLVERSION    
  set RDI_SETUP_ENV_FUNCTION=DIRNAME
  call "%RDI_BINROOT%/setupEnv.bat" "%RDI_APPROOT%" RDI_INSTALLROOT
  set RDI_SETUP_ENV_FUNCTION=DIRNAME
  call "%RDI_BINROOT%/setupEnv.bat" "!RDI_INSTALLROOT!" RDI_INSTALLROOT

  if not [%XIL_PA_NO_XILINX_SDK_OVERRIDE%] == [1] (
    if "!HDI_APPROOT!" EQU "!RDI_INSTALLROOT!/Scout/!RDI_INSTALLVER!" (
      set XILINX_SDK=!RDI_INSTALLROOT!/Scout/!RDI_INSTALLVER!
    ) else (
      if exist "!RDI_INSTALLROOT!/SDK/!RDI_INSTALLVERSION!" (
      set XILINX_SDK=!RDI_INSTALLROOT!/SDK/!RDI_INSTALLVERSION!
      ) else (
        if exist "!RDI_BASEROOT!/SDK" (
          set XILINX_SDK=!RDI_BASEROOT!/SDK
        )
      )
    )
  )

  set TEMP_DEPENDENCY=!RDI_DEPENDENCY!
  :TOKEN_LOOP_DEPENDENCY
  for /F "delims=;" %%a in ("!TEMP_DEPENDENCY!") do (
    if [%%a] == [XILINX_VIVADO] (
      if not defined XILINX_VIVADO (
        rem # locate parallel install
        if exist "!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!" (
          set XILINX_VIVADO=!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!
          set PATH=!XILINX_VIVADO!/bin;!PATH!
        ) else (
          rem # locate parallel install
          if exist "!RDI_BASEROOT!/Vivado/bin/vivado.bat" (
            set XILINX_VIVADO=!RDI_BASEROOT!/Vivado
            set PATH=!XILINX_VIVADO!/bin;!PATH!
          ) else (
            echo WARNING: Default location for XILINX_VIVADO not found: %VIVADO_DEFAULT%
          )
        )
      )
      set progbasename=!RDI_PROG!
      if !progbasename! == scout_hls (
        set progbasename=vivado_hls
      )
      if !progbasename! == apcc (
        set progbasename=vivado_hls
      )
      if !progbasename! == vivado_hls (
        if defined XILINX_VIVADO (
          if not exist "!RDI_BINROOT!\vivado.bat" (
            if exist !XILINX_VIVADO!/bin/vivado.bat (
              set xil_vivado_lib="!XILINX_VIVADO!/lib/!RDI_PLATFORM!.o"
              if exist !xil_vivado_lib! (
                set PATH=!PATH!;!xil_vivado_lib!
                set RDI_DATADIR=!RDI_DATADIR!;!XILINX_VIVADO!/data
                rem echo Using XILINX_VIVADO=!XILINX_VIVADO!
              )
            )
          )
        )
      )
    ) else (
    if [%%a] == [XILINX_VIVADO_HLS] (
      if not defined XILINX_VIVADO_HLS (
        rem # locate parallel install
        if exist "!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!" (
          set XILINX_VIVADO_HLS=!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!
          set PATH=!XILINX_VIVADO_HLS!/bin;!PATH!
        ) else (
          rem # locate parallel install
          if exist "!RDI_BASEROOT!/Vivado" (
            set XILINX_VIVADO_HLS=!RDI_BASEROOT!/Vivado
            set PATH=!XILINX_VIVADO_HLS!/bin;!PATH!
          ) else (
            echo WARNING: Default location for XILINX_VIVADO_HLS not found: %HLS_DEFAULT%
          )
        )
      )
    ))
  )
  :CHARPOP_DEPENDENCY
  set CHARPOP=!TEMP_DEPENDENCY:~0,1!
  set TEMP_DEPENDENCY=!TEMP_DEPENDENCY:~1!
  if "!TEMP_DEPENDENCY!" EQU "" goto END_TOKEN_LOOP_DEPENDENCY
  if "!CHARPOP!" NEQ ";" goto CHARPOP_DEPENDENCY
  goto TOKEN_LOOP_DEPENDENCY
  :END_TOKEN_LOOP_DEPENDENCY
  rem # Silly syntax requires something after a label
  set RDI_DEPENDENCY=


  if not defined XIL_TPS_ROOT (
    if exist "!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!/tps/%RDI_PLATFORM%" (
      set RDI_TPS_ROOT=!RDI_INSTALLROOT!/Vivado/!RDI_INSTALLVERSION!/tps/%RDI_PLATFORM%
    )
  ) else (
    set RDI_TPS_ROOT=%XIL_TPS_ROOT%
  )


  if exist "%RDI_BASEROOT%/common" (
      set XILINX_COMMON_TOOLS=%RDI_BASEROOT%/common
  )
  if not defined RDI_ARGS_FUNCTION (
    set RDI_ARGS_FUNCTION=RDI_EXEC_DEFAULT
  )

  goto :EOF

:RDI_EXEC_DEFAULT
  "%RDI_PROG%" %RDI_ARGS%
  goto :EOF

:RDI_EXEC_JAVA
  set TEMP_APPROOT=!RDI_APPROOT!
  if not defined RDI_EXECCLASS (
    set RDI_EXECCLASS="ui/PlanAhead"
  )
  if not defined RDI_JAVAARGS (
    set RDI_JAVAARGS=-Dsun.java2d.pmoffscreen=false -Xms128m -Xmx512m -Xss5m
  )
  :TOKEN_LOOP_CLASSPATH
  for /F "delims=;" %%d in ("!TEMP_APPROOT!") do (
    if exist "%%d/lib/classes" (
      if not defined RDI_CLASSPATH (
        set RDI_CLASSPATH=%%d/lib/classes/*
      ) else (
        set RDI_CLASSPATH=!RDI_CLASSPATH!;%%d/lib/classes/*
      )
    )
  )
  :CHARPOP_CLASSPATH
  set CHARPOP=!TEMP_APPROOT:~0,1!
  set TEMP_APPROOT=!TEMP_APPROOT:~1!
  if "!TEMP_APPROOT!" EQU "" goto END_TOKEN_LOOP_CLASSPATH
  if "!CHARPOP!" NEQ ";" goto CHARPOP_CLASSPATH
  goto TOKEN_LOOP_CLASSPATH
  :END_TOKEN_LOOP_CLASSPATH
  rem # Silly syntax requires something after a label

  set RDI_JAVAPROG="%RDI_JAVAROOT%/bin/java" %RDI_JAVAARGS% -classpath "%RDI_CLASSPATH%;" %RDI_EXECCLASS% %RDI_ARGS%
  if [%RDI_VERBOSE%] == [True] (
    echo %RDI_JAVAPROG%
  )
  set RDI_START_FROM_JAVA=True
  %RDI_JAVAPROG%
  goto :EOF

:RDI_EXEC_VBS
  wscript.exe %RDI_VBSLAUNCH% %RDI_PROG% %RDI_ARGS%
  goto :EOF
