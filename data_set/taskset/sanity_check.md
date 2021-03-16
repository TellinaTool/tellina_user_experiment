# Tellina sanity check
Sanity check to ensure that the current version of Tellina can handle this representative set of tasks. Each task is verified against the original prompt (tagged as 'prompt') and an 'adapted prompt'. The original prompt is simply the title of the original post from which the task was derived from. The adapted prompt aims to be closer to how someone would solve a specific problem in this context.

A set of suggestions were tagged as 'helpful' if it contains the answer or a part of the answer. If the suggestions were nonsensical or unusable to solve the task, it was tagged as 'unhelpful'.

- Using original prompts: 8 helpful, 8 unhelpful
- Adapted prompts: 15 helpful, 1 unhelpful

Tellina often has trouble with vague sentences or ones that have no context, which is why with no modifications, the original prompts do so poorly: They do not represent how programmers would use Tellina. Indeed, with the adapted prompts that are closer to the prompts participants would input in Tellina, we observe much more helpful results.

# Details
For each sampled post, we try the original prompt as well as an adaptation that's closer to how Tellina will be used during the user experiment.

For each prompt, we report the top 3 suggestions for traceability.

## 1. http://www.bashoneliners.com/oneliners/70/ (Print the lines of file2 that are missing in file1)
One-liner: `comm -23 file2 file1`

### Prompt: Print the lines of file2 that are missing in file1
- `comm -1 -3 file1 file2`
- `sort file1 file2 | uniq`
- `join < ( sort file2 )`

Helpful

### Adapted prompt: Print the lines in foo.txt that are not in bar.txt
- `comm -1 -3 foo.txt bar.txt`
- `comm -1 -3 foo.txt foo.txt`
- `join -v 1 foo.txt`

Helpful

## 2. https://www.commandlinefu.com/commands/view/42/display-which-distro-is-installed (Display which distro is installed) 
One-liner: `cat <file>`

### Prompt: Display which distro is installed
- `find . -name '[__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK][__SP__UNK]__SP__UNK'

Unhelpful

### Adapted prompt: Display the content of index.html
- `cat index.html`
- `rev index.html`
- `find . -type f -exec cat {} \; -exec cat {} \; -exec cat {} \; -exec cat {} \; -exec cat {} \;`

Helpful

## 3. https://www.commandlinefu.com/commands/view/1295/quickly-rename-a-file (Quickly rename a file)
One-liner: `mv filename.{old,new}`

### Prompt: Quickly rename a file
- `find . -type f -exec ls -s {} \; | xargs -0 -I {} rm {}`
- `find . -type f -exec ls -s {} \; | xargs -0 -I {} rename 's/ /_/g' {}`
- `find . -type f -exec ls -s {} \; | sort -n | head -n quickly`

Unhelpful

### Adapted prompt: Rename index.txt to index.csv
- `mv index.txt index.csv`
- `rename 's/\.txt/index.txt' index.csv`
- `rename 's/\.txt/.txt/' index.csv`

Helpful

## 4. https://stackoverflow.com/questions/1529946/ (Linux: copy and create destination dir if it does not exist)
One-liner: `mkdir -p "$d" && cp file "$d"`

### Prompt: Copy and create destination dir if it does not exist
- `cp -n`
- `cp -r dir_dir dir1`
- `cp -R dir /path/to/dir`

Helpful (Copy directory)

### Adapted prompt: Copy folder src in new folder a/b
- `find a/b -type d -exec mkdir -p {} \;`
- `find a/b -type d -print0 | xargs -0 -I {} cp -t a/b {}`
- `find a/b -type d -print0 | xargs -0 -I {} cp a/b {}`

Helpful (`mkdir -p`)

## 5. https://stackoverflow.com/questions/3137094/ (How to count lines in a document?)
One-liner: `wc -l <filename>`

### Prompt: How to count lines in a document?
- `cat /dev/urandom | tr -d -c '[0-9]+' | wc -c`
- `cat /dev/urandom | tr -d -c '[0-9] ' | wc -c`
- `cat /dev/urandom | tr -d -c '[a-z]' | wc -c`

Unhelpful

### Adapted prompt: Count lines in index.html
- `wc -l index.html`
- `cat index.html | wc -l`
- `wc index.html`

Helpful

## 6. https://superuser.com/questions/482435/ (How to remove all files starting with a certain string in Linux)
One-liner: `find  . -name 'name*' -exec rm {} \;`

### Prompt: How to remove all files starting with a certain string in Linux
- `find . -type f -exec grep "linux" {} \; -exec rm {} \;`
- `find /usr/share/linux -type f -exec grep "linux" {} \; -exec rm {} \;`
- `find /tmp -type f -exec grep "linux" {} \; -exec rm {} \;`

Helpful

### Adapted prompt: Remove all files starting with "prefix"
- `find . -name 'prefix*' -exec rm {} \;`
- `find . -type f -name 'prefix*' -exec rm {} \;`
- `find . -name "prefix*" -exec rm {} \;`

Helpful

## 7. https://stackoverflow.com/questions/4997693/ (Given two directory trees, how can I find out which files differ by content?)
One-liner: `diff --brief --recursive dir1/ dir2/`

### Prompt: Given two directory trees, how can I find out which files differ by content?
- `find out -type f -exec file {} \;`
- `find out -type f -user ? -exec ls -l {} \;`
- `find out -type f -exec md5 {} \;`

Not helpful

### Adapted prompt: Compare different files in directory foo and bar
- `diff foo bar`
- `find foo bar -type f -exec diff {} {} \; -exec diff {} {} \; -exec diff {} {} \;`
- `find foo bar -type f -exec diff {} {} \; -exec diff {} {} \; -exec diff {} {} \; -exec diff {} {} \;`

Helpful

## 8. https://unix.stackexchange.com/questions/144208/ (find files without extension)
One-liner: `find . -type f ! -name "*.*"`

### Prompt: Find files without extension
- `find . -type f -printf "%f\n"`
- `find . -type f -name "*.pl"`
- `find . -type f -name "*.find"`

Helpful

### Adapted prompt: Find files with no extensions
- `find . -type f -name "*.extension"`
- `find . -type f -name "*.Z"`
- `find . -type f -name "*.pl"`

Helpful

## 9. https://superuser.com/questions/392872/ (Delete files with regular expression)
One-liner: `ls | grep -P "^A.*[0-9]{2}$" | xargs -d"\n" rm`

### Prompt: Delete files with regular expression
- `find ./ -type f -exec rm -f {} \;`

Unhelpful

### Adapted prompt: Delete files matching a regexp
- `find /tmp -type f -name "*.txt" -exec rm -f {} \;`

Unhelpful

## 10. http://www.bashoneliners.com/oneliners/193/ (Find all files recursively with specified string in the filename and output any lines found containing a different string.)
One-liner: `find . -name *conf* -exec grep -Hni 'matching_text' {} \; > matching_text.conf.list`

### Prompt: Find all files recursively with specified string in the filename and output any lines found containing a different string.
- `find . -type f -exec grep -H -n "${ind}" \; -exec grep -H -n "${ind}" \; -exec grep -H -n "${ind}" {} \;`

Helpful

### Adapted prompt: find lines containing foo in files named bar
- `find / -name bar -print | xargs -I {} grep foo {}`
- `find . -name bar -print | xargs -I {} grep foo {}`
- `find . -name foo -type f -print | xargs -I {} grep -i -l foo {}`

Helpful

## 11. https://www.commandlinefu.com/commands/view/1798/quick-access-to-the-ascii-table. (Quick access to the ascii table)
One-liner: `man ascii`

### Prompt: Quick access to the ascii table
- `su username`
- `apropos -r ( date '+%Y-%m-%d %l:%l:%M:%S' )`
- `apropos -r ( date '+%Y-%m-%d %l:%M:%S' )`

Unhelpful

### Adapted prompt: Show manual for ascii command
- `man ascii`
- `echo "$ascii" | xargs -I {} dirname {} | xargs -I {} dirname {} | xargs -I {} dirname {} | xargs -I {} file {}`

Helpful


## 12. https://unix.stackexchange.com/questions/93323/ (List subdirectories only n level deep)
One-liner: `find /usr/share/festival/lib/voices -maxdepth 2 -mindepth 2 -type d -exec basename {} \;`

### Prompt: List subdirectories only n level deep
- `jobs -l`
- `ls -d /path/to/dir`
- `echo "$n" | cut -d '/' -f 2 | xargs -I {} ls -l {}`

Unhelpful

### Adapted prompt: List two level deep subdirectories in dir
- `find dir -mindepth 2 -maxdepth 2 -type d -exec ls -l {} \;`
- `find dir -mindepth 2 -maxdepth 2 -type d -exec ls -l -d {} \;`
- `find dir -maxdepth 2 -type d -exec ls -l -d {} \;`

Helpful

## 13. https://www.commandlinefu.com/commands/view/353/extract-tarball-from-internet-without-local-saving (Extract tarball from internet without local saving)
One-liner: `wget -qO - ""http://www.tarball.com/tarball.gz"" | tar zxvf -"`

### Prompt: Extract tarball from internet without local saving
- `echo ( hostname )`
- `echo "$internet" | rev | cut -d '/' -f 4-`
- `echo "$tarball" | rev | cut -d '/' -f 4-`

Unhelpful

### Adapted prompt: Download and extract tarball from http://example.com/tarball.tar.gz
- `curl http://example.com/tarball.tar.gz | tar -x -v -f -`
- `curl http://example.com/tarball/tarball.tar.gz | tar -x -v -f -`
- `tar -c -z -f http://example.com/tarball.tar.gz | tar -x -v -f -`

Helpful

## 14. https://superuser.com/questions/633605/ (How to create symbolic links to all files (class of files) in a directory?)
One-liner: `ln -s ../source/*.bar .`

### Prompt: How to create symbolic links to all files (class of files) in a directory?
- `ln -s -f ( cat /path/to/? )`
- `ln -s -f ( readlink -f "$0" )`
- `ln -s -f ( find adirectory -type f -exec ln -s {} \; -exec ln -s {} /dev/null \; )`

Helpful

### Adapted prompt: Create symbolic links for all files in directory
- `find ./ -type f -exec ln -s {} \;`
- `find ./ -type f -exec ln -s {} /dev/null \;`
- `find /tmp -type f -print0 | xargs -0 -I {} ln -s -f {} {}`

Helpful

## 15. http://www.bashoneliners.com/oneliners/61/ (Recursively remove all empty sub-directories from a directory tree)
One-liner: `find . -depth  -type d  -empty -exec rmdir {} \;`

### Prompt: Recursively remove all empty sub-directories from a directory tree
- `find . -depth -empty -type d -exec rmdir {} \;`
- `find . -depth -type d -empty -exec rmdir {} \;`
- `find . -type d -empty -exec rmdir {} \;`

Helpful

### Adapted prompt: Remove all the empty subdirectories in directory
- `find . -type d -empty -exec rmdir {} \;`
- `find . -type d -empty -exec rmdir -v -p --ignore-fail-on-non-empty {} +`

Helpful

## 16. https://www.commandlinefu.com/commands/view/6652 (Remove all but one specific file1)
One-liner: `rm -f !(survivior.txt)`

### Prompt: Remove all but one specific file1
- `find . -type f -name "*.specific" -exec rm -f {} \;`
- `find . -type f -name "*.txt" -exec rm -f {} \;`
- `find . -type f -name "*.but" -exec rm -f {} \;`

Helpful

### Adapted prompt: Remove all files except foo.txt
- `find . -name foo.txt -exec rm {} \;`
- `find . -type f -name foo.txt -exec rm {} \;`
- `find . -type f -name "foo.txt" -exec rm -f {} \;`

Helpful