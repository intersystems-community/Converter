Class Converter.LibreOffice Extends Common [ Abstract ]
{

/// Convert source file into target file. format - target format. Supported formats: https://wiki.openoffice.org/wiki/Framework/Article/Filter/FilterList_OOo_3_0
/// w $System.Status.GetErrorText(##class(Converter.LibreOffice).convert("C:\temp\1.doc", "C:\temp\1.docx", "docx"))
ClassMethod convert(source As %String, target As %String, format As %String(VALUELIST=",docx,html,mediawiki,csv,pptx,ppt,wmf,emf,svg,xlsx,xls") = "docx") As %Status
{
	#dim sc As %Status = $$$OK
	
	// Basic checks
	return:'##class(%File).Exists(source) $$$ERROR($$$FileDoesNotExist, source)
	set target = ##class(%File).NormalizeFilenameWithSpaces(target)
	return:##class(%File).Exists(target) $$$ERROR($$$GeneralError, "Target file already exists")
	
	// Temp dir to store target file
	set tempDir = ..tempDir()
	set success = ##class(%File).CreateDirectory(tempDir, .out)
	return:'success $$$ERROR($$$GeneralError, "Unable to create directory " _ tempDir _ ", code: " _ out)
	
	// Conversion
	set sc = ..executeConvert(source, tempDir, format)
	quit:$$$ISERR(sc) sc

	// Move conversion result into target
	set sourceName = ##class(%File).GetFilename(source)
	set tempTargetName =  tempDir _ $p(sourceName, ".", 1, *-1) _ "." _ format
	set result = ##class(%File).Rename(tempTargetName, target,.code)
	if result=0 {
		set sc = $$$ERROR($$$GeneralError, "Error moving '" _ tempTargetName _ '" to '" _ target _ "' with code: " _ code)
	}
	quit:$$$ISERR(sc) sc
	
	// Delete temp folder
	set result = ##class(%File).RemoveDirectoryTree(tempDir)
	if result=0 {
		set sc = $$$ERROR($$$GeneralError, "Error removing: " _ tempDir)
	}
	quit sc
}

/// Convert source into format and place it into targetDir
ClassMethod executeConvert(source, targetDir, format) As %Status
{
	// Libreoffice needs targetDir without last slash
	set:$e(targetDir,*)=..#SLASH targetDir = $e(targetDir, 1, *-1)
	
	set timeout = 100
	set cmd = ..getSO()				// Get executable
	set args(1) = "--headless"		// Do not run GUI
	set args(2) = "--writer"		// Use writer converter
	set args(3) = "--convert-to"	// Target format
	set args(4) = format
	set args(5) = "--outdir"		// Directory to output converted files to
	set args(6) = targetDir
	set args(7) = source
	return ..execute(cmd, .args, timeout)
}

}

