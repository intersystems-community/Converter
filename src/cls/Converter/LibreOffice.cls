Class Converter.LibreOffice Extends Common [ Abstract ]
{

/// Convert a file %1 into %2 format and place it into %3 directory (name equal to %1 name, extension = %2)
Parameter COMMAND = "%4 --headless --writer --convert-to %2 --outdir %3 %1";

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
	set cmd = $$$FormatText(..#COMMAND, source, format, targetDir, ..getSO())
	return ..execute(cmd, timeout)
}

}

