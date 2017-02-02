# Converter
Convert documents from InterSystems Cache easily using:

 - LibreOffice

# Install

1. Download and import code
2. In OS:
   - Linux: apt-get install libreoffice-core libreoffice-writer
   - Windows: install [libreoffice](https://www.libreoffice.org/download/libreoffice-fresh/)
3. Add `soffice` to PATH

# Use

Call from the terminal: 

```
set sc = ##class(Converter.LibreOffice).convert(source, target, format)
write $System.Status.GetErrorText(sc)
```

Where:
- source - file to convert
- target - result file
- format - specification for target file. Possible values: `docx,html,mediawiki,csv,pptx,ppt,wmf,emf,svg,xlsx,xls`. More possible values [here](wiki.openoffice.org/wiki/Framework/Article/Filter/FilterList_OOo_3_0).

# Errors

1. Libreoffice errors
   - Instal latest stable Libreoffice (5.2.5 atm). Minimally supported version is 4.2
