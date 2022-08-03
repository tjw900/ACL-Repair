clear

$toplevel = "U:\"

$starttime = [datetime]::Now

$filename = $starttime.DateTime.replace(":","-")

echo "Starting at " $starttime

# List of SIDs that are not moving to OnTap, used to filter lists below
# Will need to be constantly updated with newly found legacy SID's
$exclusions = "UNCLE\BigKev","UNCLE\arcs_ad_admin","UNCLE\spomigrate","CREATOR OWNER","EVERYONE","NT AUTHORITY\SYSTEM","BUILTIN\Administrators","BUILTIN\Users","S-1-5-32-767","S-1-5-32-766","admin_tier1nas","admin_tier2nas","admin_tier3nas"

# Recursively gets all directories from the specified top level and performs the cleansing operation on each directory found
# Needs to be changed to work with an input file rather than be hard coded
get-childitem -directory $toplevel -recurse | foreach-object{   
    # Compares the access of the current folder and its parent folder
    # Output is the differences between the two ACL's in text form in the variable $comp
    $acl = ((get-acl -literalpath $PSItem.fullname).access | sort-object -property identityreference -unique).identityreference.value
    $pacl = ((get-acl -literalpath $PSItem.parent.fullname).access | sort-object -property identityreference -unique).identityreference.value
    $comp = ((compare-object $pacl $acl).inputobject)

    # Removes all occurrences of the excluded SIDs from the comparison object
    # Output is only the user relevant differences like user groups and individual users
    if ($comp -ne $null)
    {
        foreach ($exclusion in $exclusions)
        {
            $comp = $comp | Where-Object {$PSitem -ne $exclusion}
        }
    }

    # Now that all the excluded groups have been removed from the comparison, runs additional operations if there are still differences
    if ($comp -ne $null)
    {   
         $PSItem.fullname   
    }
}


$finishtime = [datetime]::Now
echo "Finished  at " $finishtime

$finishtime - $starttime | ft
