Class Converter.Common [ Abstract ]
{

Parameter SLASH = {$case($system.Version.GetOS(),"Windows":"\",:"/")};

/// Execute OS command cmd. 
/// timeout - how long to wait for command completion. 
/// If debug is true then output debug information.
ClassMethod execute(cmd As %String, ByRef args As %String, timeout As %Integer = 60, debug As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set code = ""
	set out = ""
	write:debug !, "cmd: ", ..buildFullCommand(cmd, .args), !
	set sc = ..runCommandViaZF(cmd, .args , .out, timeout, $$$YES, .code)
	if debug {
		write "status: "
		if $$$ISERR(sc) {
			write $System.Status.GetErrorText(sc)
		} else {
			write sc
		}
		write !,"code: ", code, !, "out: ", out, !
	}
	
	if code'=0 {
		set sc1 = $$$ERROR($$$GeneralError, "Command: " _ ..buildFullCommand(cmd, .args) _ $$$NL _ " Error code: " _ code _ $$$NL _ "Output: " _ out)
		set sc = $$$ADDSC(sc, sc1)	
	}
	return sc
}

/// do ##class(Converter.Common).runCommandViaZF()
ClassMethod runCommandViaZF(cmd As %String, ByRef args As %String, Output out As %String, timeout As %Integer = 60, deleteTempFile As %Boolean = 1, Output code As %String) As %Status [ CodeMode = objectgenerator ]
{
	set argsCount = $l($$$defMemberKeyGet("%Net.Remote.Utility",$$$cCLASSmethod,"RunCommandViaZF",$$$cMETHformalspec),",")
	if argsCount = 6 {
		do %code.WriteLine($$$TAB _ "set cmd = ..buildFullCommand(cmd, .args)")
		do %code.WriteLine($$$TAB _ "quit ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code)")
	} else {
		do %code.WriteLine($$$TAB _ "quit ..runCommandViaZFInternal(cmd, , .out, timeout, $$$YES, .code,  .args, $$$NO, 1)")
	}
	quit $$$OK
}

/// Run a command using $ZF(-100) and an external temporary file to store the command output. <br>
/// If <var>pDeleteTempFile</var> is 0 (false), the temporary file is not deleted; in this case, it is up to the caller to delete it when done with it.
ClassMethod runCommandViaZFInternal(pCmd As %String, Output pTempFileName As %String, Output pOutput As %String, pOpenTimeout As %Integer = 5, pDeleteTempFile As %Boolean = 1, Output pRetCode As %String, ByRef pCmdArgs, pAsynchronous As %Boolean = 0, pUseShell As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set pOutput = ""
	Set pRetCode = ""
	Set IO = $IO
	Set ZEOFMode = $ZU(68,40,1)
	Set pTempFileName = ""

	Try {
		Set (tFile,pTempFileName) = ##class(%File).TempFilename("txt")
		If tFile="" Set tSC = $$$ERROR($$$CacheError, "Failed to obtain a temporary file name") Quit
		Set cmdFlags = $Select(pUseShell:"/SHELL",1:"") _ $Select(pAsynchronous:"/ASYNC",1:"") _"/STDOUT="""_tFile_"""/STDERR="""_tFile_""""
		#if $l($$$defMemberKeyGet("%Net.Remote.Utility",$$$cCLASSmethod,"RunCommandViaZF",$$$cMETHformalspec),",")>6 
		Set pRetCode = $ZF(-100,cmdFlags,pCmd,.pCmdArgs)
		#endif
		
		Close tFile Open tFile:("RS"):pOpenTimeout
		If '$T Set tSC = $$$ERROR($$$CacheError, "Failed to open temporary file '"_tFile_"'") Quit
		Set TooMuch = 0
		Use tFile
		For {
			// Keep reading through end of file; save only first 32,000 characters
			Set tLine = "" Read tLine:1
			If '$T && (tLine=$C(-1)) Quit  // Exit by timeout
			If 'TooMuch {
				Set:pOutput'="" pOutput = pOutput_$C(13,10)
				If $L(pOutput)+$l(tLine)<32000 {
					Set pOutput = pOutput_tLine
				}
				Else {
					Set pOutput = pOutput_$E(tLine,1,32000-$L(pOutput))_" (more...)"
					Set TooMuch = 1
				}
			}
			If ($ZEOF=-1) Quit  // Exit by EOF
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}

	Try {
		If pDeleteTempFile {
			Close tFile:"D"
		}
		Else {
			Close tFile
		}
	} Catch (ex) {
		// don't overwrite the error status if it's already populated
		Set:$$$ISOK(tSC) tSC = ex.AsStatus()
	}

	If 'ZEOFMode Do $ZU(68,40,0) // Restore ZEOF mode
	Use IO
	
	Quit tSC
}

/// w ##class(Converter.Common).buildFullCommand()
ClassMethod buildFullCommand(cmd As %String, ByRef args As %String) As %String
{
	quit:$d(args)<10 cmd
	set result = $lb(cmd)	
	set key = ""
	for {
		set key=$order(args(key),1,arg) 
		quit:key=""
		set result = result _ $lb(arg)
	}
	quit $lts(result, " ")
}

/// Get name of temporary not-existstig sub-directory inside dir
/// w ##class(Converter.Common).tempDir()
ClassMethod tempDir(dir = {##class(%SYS.System).TempDirectory()}) As %String
{
	set dir = ##class(%File).NormalizeDirectory(dir)
	set exists = ##class(%File).DirectoryExists(dir)
	throw:exists=$$$NO ##class(%Exception.General).%New("<USER>", "Converter.LibreOffice", , "Directory " _ dir _ " does not exist")
	do {
		set subDir = $random(1000000)
		set subDirFull = ##class(%File).SubDirectoryName(dir, subDir, $$$YES)
		set exists = ##class(%File).DirectoryExists(subDirFull)
	} while exists
	return subDirFull
}

/// Get path to libreoffice/soffice
ClassMethod getSO()
{
	if $$$isWINDOWS {
		set path = "soffice"
	} else {
		set path = "export" // "export HOME=/tmp && unset LD_LIBRARY_PATH && soffice"
	}
	return path
}

/// Get path to zip
ClassMethod getZip()
{
	if $$$isWINDOWS {
		set path = "zip"
	} else {
		set path = "zip"
	}
	return path
}

/// Get path to unzip
ClassMethod getUnzip()
{
	if $$$isWINDOWS {
		set path = "unzip"
	} else {
		set path = "unzip"
	}
	return path
}

}

