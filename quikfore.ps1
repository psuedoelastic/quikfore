#
# Author: Kristian Hermansen <kristian.hermansen@wbconsultant.com>
# Date: May 16, 2012
# Purpose: Extract useful forensic artifacts quickly from Windows machines
# Usage: See README file
#

# Configuration variables
$quikfore_base = "c:\quikfore";
$config_base = "$quikfore_base\cfgs"; # try test_cfgs for the example
$process_names =  @(get-content $config_base\process_names.cfg);
$service_names = @(get-content $config_base\service_names.cfg);
$registry_keys = @(get-content $config_base\registry_keys.cfg);
$file_scan_paths = @(get-content $config_base\file_scan_paths.cfg);
$file_names = @(get-content $config_base\file_names.cfg);
$file_sizes = @(get-content $config_base\file_sizes.cfg);
$file_md5sums = @(get-content $config_base\file_md5sums.cfg);
$file_strings = @(get-content $config_base\file_strings.cfg);
$output_logfile = "$quikfore_base\output\$(get-date -uformat "%Y-%m-%d@%H-%M-%S").output.log";

start-transcript $output_logfile;
#write-output "Started at $(Get-Date) on host $($env:computername)";

# Check processes
write-output "[PROCESSES]";
get-process | % { $process_names -ieq (gci $_.path).name };

# Check services
write-output "[SERVICES]";
get-service | % { $service_names -ieq $_.name }

# Check registry
write-output "[REGISTRY]";
$registry_keys | % { reg query $_ 2>&1>$null; if($?){ $_ } }

# Traverse the file systems
write-output "[FILES]"
$file_scan_paths | 
% {

gci -r -fo -ea 0 $_ | 

# match on file size, file name, file md5sum, or file content
where { 
    !$_.PSIsContainer -and 
    ( $($file_sizes -eq $_.length; clear-variable *_result) -or 
    $($file_names -ieq $_.name; clear-variable *_result) -or 
    $file_md5sums -ieq 
        ($file_md5sums_result = 
            $($algo = [System.Security.Cryptography.HashAlgorithm]::Create("MD5"); 
            $stream = New-Object System.IO.FileStream($_.fullname, [System.IO.FileMode]::Open); 
            $md5StringBuilder = New-Object System.Text.StringBuilder; 
            $algo.ComputeHash($stream) | 
            % { 
                [void] $md5StringBuilder.Append($_.ToString("x2")) 
            }; 
            $md5StringBuilder.ToString(); 
            $stream.dispose();
            )
        ) -or 
    ($file_strings_result = 
        $(select-string -simplematch -list -path $_.fullname -pattern $file_strings; 
        clear-variable *_result)
        )
    )
}  2>$null | 

% { 
    $_.fullname + "," + $_.length + "," + $file_md5sums_result + "," + $file_strings_result.pattern
};

};

#write-output "Ended at $(Get-Date)";
stop-transcript;

# Uncomment the following lines if you want the shell to wait before exiting (debugging)
#write-output "Finished! Press any key to exit..."
#$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")