# MapCFQuery
Search provided files and directories for `<cfquery></cfquery>` elements. Records tables and columns that are queried/updated and in what file locations. 
Stores information in a Summary.txt file in a provided location.
# How To Use
First, set the `VALID_FILE_TYPES` in Main.java. Default is `.cfm` and `.cfc` files.
When running, you must pass some command-line arguments to the program. The first argument is the location of a directory in which to store the results of the search.
All following arguments are directories/files that you want the program to search through.
# Selenium 
This program utilizes the Selenium WebDriver to autonomously parse SQL commands. By default, a new chrome window will open to carry out the parsing.
If you would not like to have a chrome window appear, uncomment `options.addArguments("--headless");` in the FileSearcher constructor.
## Special Thanks
Special thanks to https://sql-app.infocruncher.com/ for providing a web compatible sql parser.
