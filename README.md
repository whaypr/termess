# termess

Terminal application which allows you to transform Messenger JSONs into terminal-friendly files

Generated files can be easily read and searched through with standard terminal tools

## Usage

### Step 0: Help
```
$ termess.sh -h
```
Shows list of all availible options and their description


### Step 1: Prepare
```
$ termess.sh -p "path_to_zip_archive"
```
In your current working directory:

* unzips facebook archive
* creates facebook folder where:
    * prepares folder *processed_chats* for final files
    * separates all media files from actual messages in *media* folder

**Skipping this step can cause the rest of the script to fail!**


### Step 2: Repair
```
$ termess.sh -r
```
or
```
$ termess.sh -r "path_to_repair_script"
```
Uses included (or your own) script to repair bad encoding of JSON files provided by Facebook

When called without argument termess will search for repair script in the same directory *termess.sh* is. If not found, user is prompted to enter custom path

**Skipping this step can cause messages will not be displayed correctly!**


### Step 3: Generate
```
$ termess.sh -a
```
or
```
$ termess.sh -a "path_to_dir_where_files_will_be_generated"
```
Creates final files that are ready for futher use of your choice

When called without argument termess will generate files in your current working directory (after your confirmation)

You can use folder *facebook/processed_chats* to save all your final files

```
$ termess.sh -f "path_to_one_chat_folder"
```
Processes just one particular chat

In this case output is only displayed on stdout, but can be redirected to a file by yourself

---
**NOTE:**

All steps can be done with single command:
```
$ termess.sh -p facebook.zip -r -a facebook/processed_chats
```
---


### Step 4: Enjoy
Now you have everything needed for viewing, processing, searching through or anything else you want to do with your Messanger messages

All of that comfortably right from your terminal


## TODO

* display some information about sent files, gifs, links, etc. instead of "null"
* fix parsing problem in some chats
