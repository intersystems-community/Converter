Include %occIO

Class Converter.Footer Extends Converter.Common
{

/// Use %3 (unzip) to unzip %1 file into %2 dir
Parameter UNZIP = "%3 %1 -d %2";

/// Use zip (%1) to archive dir %3 into file %2. 
/// Tried with: 7z "%1 a -tzip %2 %3*" - does not work correctly on linux
Parameter ZIP = "cd %3 && %1 -r %2 ./";

Parameter FOOTERMASK = "footer*.xml";

/// Add text to docx source footer. Output result into target
/// w $System.Status.GetErrorText(##class(Converter.Footer).modifyFooter("C:\Temp\docx\2.docx", "C:\Temp\docx\21.docx", "TESTEST"))
ClassMethod modifyFooter(source As %String, target As %String = {source}, text As %String) As %Status
{
	// Basic checks
	return:'##class(%File).Exists(source) $$$ERROR($$$FileDoesNotExist, source)
	set target = ##class(%File).NormalizeFilenameWithSpaces(target)
	return:##class(%File).Exists(target) $$$ERROR($$$GeneralError, "Target file already exists")
	
	// Temp dir to store target file
	set tempDir = ..tempDir()
	set success = ##class(%File).CreateDirectory(tempDir, .out)
	return:'success $$$ERROR($$$GeneralError, "Unable to create directory " _ tempDir _ ", code: " _ out)
	
	// Unpack document into a folder
	set sc = ..executeUnzip(source, tempDir)
	quit:$$$ISERR(sc) sc

	// Add footer into each doc section
	set sc = ..addFooterToSections(tempDir)
	quit:$$$ISERR(sc) sc
	
	// Add empty (invalid)footer and register it
	set sc = ..addDefaultFooter(tempDir)
	quit:$$$ISERR(sc) sc	
	
	// Replace all footer*.xml files with ours
	set sc = ..modifyFooterFiles(tempDir, text)
	quit:$$$ISERR(sc) sc
	
	// Pack document
	set sc = ..executeZip(tempDir, target)
	quit:$$$ISERR(sc) sc

	// Delete temp dir
	set result = ##class(%File).RemoveDirectoryTree(tempDir)
	if result=0 {
		set sc = $$$ERROR($$$GeneralError, "Error removing: " _ tempDir)
	}	

	quit sc
}

/// Unpack source file into targetDir
ClassMethod executeUnzip(source, targetDir) As %Status
{
	set timeout = 100
	set cmd = $$$FormatText(..#UNZIP, source, targetDir, ..getUnzip())
	return ..execute(cmd, timeout)
}

/// Replace all footer*.xml files with ours
ClassMethod modifyFooterFiles(targetDir, text) As %Status
{
	#dim sc As %Status = $$$OK
	
	set footerName = ##class(%File).TempFilename("xml")
	set sc = ..generateNewFooter(footerName, text)
	quit:$$$ISERR(sc) sc
	
	set targetDir = ##class(%File).SubDirectoryName(targetDir, "word", $$$YES)
	#dim rs As %SQL.ClassQueryResultSet = ##class(%File).FileSetFunc(targetDir, ..#FOOTERMASK)
	while rs.%Next() {
		set result = ##class(%File).CopyFile(footerName, rs.Name, $$$YES, .code)
		if result=0 {
			set sc = $$$ERROR($$$GeneralError, "Error replacing '" _ rs.Name _ '" with '" _ newFooter _ "'. Code: " _ code)
		}
		quit:$$$ISERR(sc)
	}
	return sc
}

/// Create new valid footer with tiext into fileName
ClassMethod generateNewFooter(fileName, text) As %Status
{
	#dim sc As %Status = $$$OK
	set file = ##class(%Stream.FileCharacter).%New()
	set sc = file.LinkToFile(fileName)
	quit:$$$ISERR(sc)
	
	#dim stream As %Stream.TmpCharacter  = ##class(%Stream.TmpCharacter).%New()
	#dim transformedStream As %Stream.Object
	
	do stream.Write("<xml>" _ text _ "</xml>")
	set sc = ##class(Converter.Utils.XML).transformByXDataXsl(stream, $classname(), "footerXSL", .transformedStream)
	quit:$$$ISERR(sc)
	
	set sc = file.CopyFromAndSave(transformedStream)
	kill file
	quit sc
}

/// Pack folder into a document
/// do ##class(Converter.Footer).generateDocx("C:\Temp\docx\out", "C:\Temp\docx\21.docx")
ClassMethod executeZip(targetDir, docx) As %Status
{
	set timeout = 100
	set cmd = $$$FormatText(..#ZIP, ..getZip(), docx, targetDir)
	return ..execute(cmd, timeout)
}

/// Add default footer to a document
ClassMethod addDefaultFooter(targetDir) As %Status
{
	set sc = ..addDefaultFooterType(targetDir)
	quit:$$$ISERR(sc) sc
	
	set sc = ..addDefaultFooterFile(targetDir)
	quit:$$$ISERR(sc) sc

	set sc = ..addDefaultFooterRelationship(targetDir)
	quit sc
}

/// Add overrride into [Content_Types].xml
ClassMethod addDefaultFooterType(targetDir) As %Status
{
	set filename = targetDir _ "[Content_Types].xml"

	set file = ##class(%Stream.FileCharacter).%New()
	set sc = file.LinkToFile(filename)
	quit:$$$ISERR(sc) sc
	
	set stream = ##class(%Stream.TmpCharacter).%New()
	do stream.Write($ZCVT(file.Read($$$MaxLocalLength),"O","UTF8"))
	
	set sc = ##class(Converter.Utils.XML).transformByXDataXsl(stream, $classname(), $$$CurrentMethod, .transformedStream)
	quit:$$$ISERR(sc) sc
	
	set sc = file.CopyFromAndSave(transformedStream)
	quit sc
}

/// Add empty invalid footer file
ClassMethod addDefaultFooterFile(targetDir) As %Status
{
	set targetDir = ##class(%File).SubDirectoryName(targetDir, "word", $$$YES)
	set footerFile = ##class(%Stream.FileCharacter).%New()
	do footerFile.LinkToFile(targetDir _ "footer0.xml")
	do footerFile.Write($$$OK)
	set sc = footerFile.%Save()
	quit sc
}

/// Add rId0 relationship
ClassMethod addDefaultFooterRelationship(targetDir) As %Status
{
	set targetDir = ##class(%File).SubDirectoryName(targetDir, "word", $$$YES)
	set relsDir = ##class(%File).SubDirectoryName(targetDir, "_rels", $$$YES)
	
	set filename = relsDir _ "document.xml.rels"

	set file = ##class(%Stream.FileCharacter).%New()
	set sc = file.LinkToFile(filename)
	quit:$$$ISERR(sc) sc
	
	set stream = ##class(%Stream.TmpCharacter).%New()
	do stream.Write($ZCVT(file.Read($$$MaxLocalLength),"O","UTF8"))
	
	set sc = ##class(Converter.Utils.XML).transformByXDataXsl(stream, $classname(), $$$CurrentMethod, .transformedStream)
	quit:$$$ISERR(sc) sc
	
	set sc = file.CopyFromAndSave(transformedStream)
	quit:$$$ISERR(sc) sc
	
	
	set footerFile = ##class(%Stream.FileCharacter).%New()
	do footerFile.LinkToFile(targetDir _ "footer0.xml")
	set sc = footerFile.Write($$$OK)
	quit:$$$ISERR(sc) sc
	set sc = footerFile.%Save()
		
	quit sc
}

XData addDefaultFooterType
{
<xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns="http://schemas.openxmlformats.org/package/2006/content-types"  version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes" indent="no"  />
<xsl:param name="new">
<Override PartName="/word/footer0.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
</xsl:param>

<xsl:template match="/*">
<xsl:copy>
<xsl:copy-of select="@* | node()"/> 
<xsl:copy-of select="$new"/>
</xsl:copy>
</xsl:template>
</xsl:stylesheet>
}

XData addDefaultFooterRelationship
{
<xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns="http://schemas.openxmlformats.org/package/2006/relationships"  version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes" indent="no"  />
<xsl:param name="new">
<Relationship Id="rId0" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer0.xml"/>
</xsl:param>

<xsl:template match="/*">
<xsl:copy>
<xsl:copy-of select="$new"/>
<xsl:copy-of select="@* | node()"/>

</xsl:copy>
</xsl:template>
</xsl:stylesheet>
}

/// Add footer to each document section
ClassMethod addFooterToSections(targetDir) As %Status
{
	#dim sc As %Status = $$$OK
	set targetDir = ##class(%File).SubDirectoryName(targetDir, "word", $$$YES)
	set filename = targetDir _ "document.xml"
	
	set file = ##class(%Stream.FileCharacter).%New()
	//set file.TranslateTable = "UTF8"
	set sc = file.LinkToFile(filename)
	quit:$$$ISERR(sc) sc
	
	set stream = ##class(%Stream.TmpCharacter).%New()
	do stream.Write($ZCVT(file.Read($$$MaxLocalLength),"O","UTF8"))
	
	set sc = ##class(Converter.Utils.XML).transformByXDataXsl(stream, $classname(), $$$CurrentMethod, .transformedStream)
	quit:$$$ISERR(sc) sc
	
	set sc = file.CopyFromAndSave(transformedStream)
	quit sc
}

XData addFooterToSections
{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
version="1.0">
<xsl:output method="xml" omit-xml-declaration="yes" indent="yes" />
<xsl:template match="//@* | //node()">
<xsl:copy>
<xsl:apply-templates select="@*"/>
<xsl:apply-templates select="node()"/>
</xsl:copy>
</xsl:template>
<xsl:template match="//w:sectPr">
<xsl:element name="{name()}" namespace="{namespace-uri()}">
<xsl:copy-of select="./namespace::*"/>
<xsl:apply-templates select="@*"/>
<xsl:copy-of select="./*[local-name() != 'footerReference']"/>
<w:footerReference w:type="default" r:id="rId0"/>
<w:footerReference w:type="first" r:id="rId0"/>
<w:footerReference w:type="even" r:id="rId0"/>
</xsl:element>
</xsl:template>
</xsl:stylesheet>
}

/// Footer
XData footerXSL
{
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://schemas.openxmlformats.org/package/2006/relationships" version="1.0">
<xsl:output method="xml" omit-xml-declaration="no" indent="yes" standalone="yes"/>
<xsl:template match="/">

<w:ftr xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" mc:Ignorable="w14 w15 wp14">
<w:p>
<w:r>
<w:rPr>
<w:lang w:val="en-US"/>
</w:rPr>
<w:t><xsl:value-of select="//xml/text()"/></w:t>
</w:r>
</w:p>
</w:ftr>
</xsl:template>
</xsl:stylesheet>
}

}

