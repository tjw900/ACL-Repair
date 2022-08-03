clear
get-childitem -directory "U:\" -recurse | foreach-object -process {if ((compare-object (((get-acl -literalpath $PSItem.fullname).access | sort-object -property identityreference).identityreference) (((get-acl -literalpath $PSItem.parent.fullname).access | sort-object -property identityreference).identityreference)) -ne $null){$PSItem.fullname}}
