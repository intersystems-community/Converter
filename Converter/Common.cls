Class Converter.Common [ Abstract ]
{

Parameter SLASH = {$case($system.Version.GetOS(),"Windows":"\",:"/")};

/// Execute OS command cmd. 
/// timeout - how long to wait for command completion. 
/// If debug is true then output debug information.
ClassMethod execute(cmd, timeout As %Integer = 60, debug As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set code = ""
	set out = ""
	write:debug !, "cmd: ", cmd, !
	set sc = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code)
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
		set sc1 = $$$ERROR($$$GeneralError, "Command: " _ cmd _ $$$NL _ " Error code: " _ code _ $$$NL _ "Output: " _ out)
		set sc = $$$ADDSC(sc, sc1)	
	}
	return sc
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

