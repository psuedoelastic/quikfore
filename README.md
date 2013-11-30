#
# Author: Kristian Hermansen <kristian.hermansen@gmail.com>
# Date: June, 2011
# Purpose: Extract useful forensic artifacts quickly from Windows machines
#

=Requirements=
* Windows with PowerShell (tested on version 2.0 under Windows 7)
* SYSTEM privileges (psexec or other means)

=Configuration=
This program takes literal strings as input from config files and attempts to scan hosts for forensic artifacts. Here is the layout below.

Script Variables:
* quikfore_base: This is root directory of the quikfore utility (all files) and defaults to "c:\quikfore".
* config_base: This variable points to the directory containing the configuration options which you must edit, which defaults to $quikfore_base\cfgs. If you want to try the example test data, change this to test_cfgs, but you should not need to do so unless you want to debug an issue or see how it works.
* output_logfile: Defines the log output location.

Folders / Files:
* test_data: This sub-folder contains test data for testing the application or seeing how it works. (DO NOT EDIT; TESTS ONLY)
* test_cfgs: This sub-folder contains test configs for testing the application or seeing how it works.
* cfgs: This sub-folder contains the actual configs for searching hosts. You must define all your search terms within here.
* process_names.cfg: Defines the process names to search as they would be referenced in memory with their image name (usually ending in .exe).
* service_names.cfg: Defines the service names to search as called from Windows Services (usually will be named without an extension).
* registry_keys.cfg: Defines the registry keys to search in the hives (keys are the final leaf or "folder"; this utility does not support values, data, types, or names).
* file_scan_paths.cfg: Defines the list of file system paths to include in the recursive search.
* file_names.cfg: Defines the list of file names on disk to search via exact match.
* file_sizes.cfg: Defines the list of file sizes on disk to search via exact match.
* file_md5sums.cfg: Defines the list of md5sums to match files on disk.
* file_strings.cfg: Defines the list of strings to search for in files on disk.

=HowTo=
And here is how you might run it after copying the root directory to all necessary machines.

psexec -i -s powershell -ExecutionPolicy RemoteSigned -file c:\quikfore\quikfore.ps1

=Output=
Interpreting the output is fairly straight forward. The headers / footers of the output log file shows some timestamps and other useful information. Between those sections is the raw data for all matches based on your defined configurations, split into relevant sections. The output will appear as the following from a sample test data run:

"""
**********************
Windows PowerShell Transcript Start
Start time: 20120517015146
Username  : WORKGROUP\SYSTEM 
Machine	  : XPS-WIN7 (Microsoft Windows NT 6.1.7601 Service Pack 1) 
**********************
Transcript started, output file is c:\quikfore\output\2012-05-17@01-51-46.outpu
t.log
[PROCESSES]
lsass.exe
[SERVICES]
lmhosts
spooler
[REGISTRY]
HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application
[FILES]
C:\quikfore\test_data\test_file_md5sum.txt,0,d41d8cd98f00b204e9800998ecf8427e,
C:\quikfore\test_data\test_file_name.txt,9,,
C:\quikfore\test_data\test_file_size.txt,1,,
C:\quikfore\test_data\test_file_string.txt,17,,foobarbaz
C:\quikfore\test_data\subdir\test_file_string_subdir.txt,43,,rqcuser
**********************
Windows PowerShell Transcript End
End time: 20120517015147
"""

The [FILES] section output is comma-separated between the fields "file name", "file size", "md5sum", and "string match".

The only non-intuitive log lines may be the file entries that match, but seemingly have no md5sum or string data. This is because those entries matched on either file name or file size, so we do an early break in order to prevent having to md5sum a potentially large file (eg. if we found a 2GB rar file with the exact name we were searching anyway). Anything with an md5sum listed matched due to md5sum computation. Finally, anything with a string match will have matched on a defined literal string.

=Notes=
Testing on a home desktop machine, this script was able to process about ten gigabytes of data per hour for all the defined forensic parameters. You can drastically speed up your tests by only scanning the file system paths that are highly likely to be most interesting first. Then later on, you can schedule a scan for all drives. This would be my advice. Even if you only scan c:\windows\system32, you will still get all the process, services, and registry information quickly. Further, system32 is a prime target to locate malware quickly.

=Known Issues=
If your are encrypting files using the native Encrypting File System (EFS), then you may encounter cases where files cannot be read, even directly by the system user (this is because they are encrypted using key material only accessible to a logged on user).

