# MappingBasedArchive

This is a plugin for Movable Type.
This plugin provides "Path Based" archive mapping.

![Screenshot](https://raw.githubusercontent.com/usualoma/mt-plugin-MappingBasedArchive/master/artwork/screenshot.png)


## Features

* You can group entries by output path.
* You can use customfield's value easyly for path of "Path Based" archive mapping.
    * Well supported types
        * Drop Down Menu
        * Radio Buttons
* You can use the AnotherCustomFields plugin instead of the customfield.
* Not only you can use the customfield's value directory, but also you can use the range of the value.
* You can sort archive by any value.
* You can set a title of archive by the settings of a mapping.


## Demo Movie

http://screencast.com/t/7DOsUDL42OuO

### Japanese Version

http://screencast.com/t/BTpd3ofH3P


## Installation

1. Download an archive file from [releases](https://github.com/usualoma/mt-plugin-MappingBasedArchive/releases).
1. Unpack an archive file.
1. Upload unpacked files to the MT `plugins` directory.

Should look like this when installed:

    $MT_HOME/
        plugins/
            MappingBasedArchive/


## Quick usage

1. Create a custom fields of "Drop Down Menu".
![Create Custom Field](https://raw.githubusercontent.com/usualoma/mt-plugin-MappingBasedArchive/master/artwork/create-custom-field-shadow.png)
1. Create an archive mapping of "Path Based".
![Create Archive Mapping](https://raw.githubusercontent.com/usualoma/mt-plugin-MappingBasedArchive/master/artwork/create-archive-mapping-shadow.png)
1. Choose output path.
![Choose Output Path](https://raw.githubusercontent.com/usualoma/mt-plugin-MappingBasedArchive/master/artwork/archive-mapping-list-shadow.png)
1. Click pencil icon, and edit detail settings of a mapping. (advanced)
![Edit Template Map](https://raw.githubusercontent.com/usualoma/mt-plugin-MappingBasedArchive/master/artwork/edit-template-map-shadow.png)
1. Do save and publish a template.
1. You can embed links of this archive by using a following snippet.
```mtml
<mt:ArchiveList name="EntryDataTypeMapping">
<a href="<mt:ArchiveLink />"><mt:ArchiveTitle /></a><
</mt:ArchiveList>
```

## Advanced recipe

### By the range

1. Create a custom fields of "Single-Line Text".
    * This field requires a number.
1. Create an archive mapping of "Path Based".
1. Edit output path like this.
   `<mt:NumberField regex_replace="/\d\d$/","00"/>/%i`

Then, these archive files are output.
* 100/index.html
* 200/index.html
* ...

### By the parent category

1. Create an archive mapping of "Path Based".
1. Edit output path like this.
    `<mt:EntryCategories><mt:ParentCategory><mt:CategoryBasename /></mt:ParentCategory></mt:EntryCategories>/%i`


## Supported Tags For Archive
* mt:ArchiveList
* mt:ArchiveTitle
* mt:ArchiveCount
* mt:ArchiveNext
* mt:ArchivePrevious
* mt:ArchiveLink


## Frequently Asked Questions
* Can this plugin output multiple archive files from a mapping?
    * No, this plugin can only output a single archive file from a mapping.


## Supported Publishing Types

* Static publishing
* Dynamic publishing


## Requirements

* MT6
* MT7

## LICENSE

Copyright (c) 2014 Taku AMANO

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
