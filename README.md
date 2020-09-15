# termess

Facebook provides a way to download all of user's Messenger activities in JSON format. However, each chat is represented by multiple, bad-encoded files

Make analysis of your Messenger communication easier and more comfortable by transforming all those files into a single plain text file with one message per line

Enables very fast and convenient searching through conversations

Files are formatted to be terminal-friendly and intended for use with terminal tools, but potentially usable anywhere else



![Chat example](./example.png)

## USAGE

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

**Skipping this step can cause the rest of script to fail!**


### Step 2: Repair
```
$ termess.sh -r
```
or
```
$ termess.sh -r "path_to_repair_script"
```
Uses included (or your own) script to repair bad encoding of JSON files provided by Facebook

When called without argument, termess will search for repair script in the same directory *termess.sh* is. If not found, user is prompted to enter custom path

**Skipping this step can cause messages will not be displayed correctly!**


### Step 3: Generate
```
$ termess.sh -a
```
or
```
$ termess.sh -a "path_to_dir_where_files_will_be_generated"
```
Creates final files that are ready for further use of your choice

When called without argument, termess will generate files in your current working directory (after your confirmation)

You can use folder *facebook/processed_chats* to save all your final files

```
$ termess.sh -f "path_to_one_chat_folder"
```
Processes just one particular chat

In this case output is only displayed on stdout, but can be redirected to a file by yourself


### Step 4: Enjoy
Now you have everything prepared for your Messenger communication analysis to begin


### Notes

* All steps can be done with a single command:
```
$ termess.sh -p facebook.zip -r -a facebook/processed_chats
```
* Once **-p** and **-r** are executed successfully, they are not needed anymore. You can run the script with just **-a** or **-f** option after that


## TODO

* display some information about sent files, gifs, links, etc. rather than just "null"
* handle newlines in messages correctly
* message reactions
* fix parsing problem of some chats
