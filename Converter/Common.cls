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
		do %code.WriteLine($$$TAB _ "quit ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code,  .args, $$$NO)")
	}
	quit $$$OK
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
		set path = "export HOME=/tmp && unset LD_LIBRARY_PATH && soffice"
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

