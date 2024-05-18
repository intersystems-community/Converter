/// Utilities for XSL transformation
Class Converter.Utils.XML [ Abstract ]
{

/// Prepare XSLT transformation
ClassMethod prepareTransform(ByRef stream As %Stream.Object = "", Output transformedStream As %XML.FileCharacterStream, ByRef params, outputEncoding As %String) [ Private ]
{
	set transformedStream = ##class(%XML.FileCharacterStream).%New()
	set transformedStream.TranslateTable = outputEncoding
	
	#dim key As %String = $order(params(""))
	while(key '= "") 
	{
		set params(key) = "'" _ $replace(params(key), "'", "`") _ "'" 	
		set key = $order(params(key))
	}
	
	if (stream = "") set stream = ..getDummyXml()
}

/// XSL-transformation
ClassMethod transform(stream As %Stream.Object = "", xslStream As %Stream.Object, Output transformedStream As %XML.FileCharacterStream, ByRef params, callbackHandler As %XML.XSLT.CallbackHandler = {$$$NULLOREF}, outputEncoding As %String = "UTF8") As %Status
{
	do ..prepareTransform(.stream, .transformedStream, .params, outputEncoding)
	quit ##class(%XML.XSLT.Transformer).TransformStream(stream, xslStream, transformedStream,,.params, callbackHandler)
}

/// XSLT from XData block
ClassMethod transformByXDataXsl(stream As %Stream.Object = "", classNameOrObject, xdataName, Output transformedStream As %XML.FileCharacterStream, ByRef params, callbackHandler As %XML.XSLT.CallbackHandler = {$$$NULLOREF}, outputEncoding As %String = "UTF8") As %Status
{
	#dim className As %String
	
	if $isObject(classNameOrObject)
	{
		set className = classNameOrObject.%ClassName(1)
	}
	else
	{
		set className = classNameOrObject
	}
	
	#dim xslStream As %Stream.Object = ..getClassXData(className, xdataName)
	
	quit ..transform(stream, xslStream, .transformedStream, .params, callbackHandler, outputEncoding)
}

/// Get class XData as a stream
ClassMethod getClassXData(className, xdataName) As %Stream.Object
{
	quit ##class(%Dictionary.CompiledXData).%OpenId(className _ "||" _ xdataName).Data
}

/// Get minimal xml
ClassMethod getDummyXml() As %Stream.Object
{
	quit ..getClassXData(..%ClassName(1), "dummyXml")
}

/// Minimal xml
XData dummyXml
{
<xml/>
}

}

