# List to store details of unattached managed disks
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$unattached_managed_disk_object = $null
$unattached_managed_disk_object = @()

# Obtaining list of Managed disks
$managed_disk_list = Get-AzDisk

# Obtaining list of Storage Accounts
$storage = Get-AzStorageAccount

# List to store details of unattached managed disks
$unattached_un_managed_disk_object = $null
$unattached_un_managed_disk_object = @()

###########################################################
# Obtaining list of unattached MANAGED disks
###########################################################
 Write-Output " `n`n*************** Obtaining list of unattached MANAGED disks *************** " -ForegroundColor Cyan

    foreach($managed_disk_list_iterator in $managed_disk_list){
        if($managed_disk_list_iterator.ManagedBy -EQ $null){
            
            Write-Output "Collecting data about an unattached managed disk... `n" -ForegroundColor Gray
            # Creating a temporary PSObject to store the details of unattached managed disks
            $unattached_managed_disk_object_temp = new-object PSObject 
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $managed_disk_list_iterator.ResourceGroupName
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "Name" -Value $managed_disk_list_iterator.Name
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "DiskSizeGB" -Value $managed_disk_list_iterator.DiskSizeGB
            $unattached_managed_disk_object_temp | add-member -membertype NoteProperty -name "Location" -Value $managed_disk_list_iterator.Location

            # Adding the objects to the final list
            $unattached_managed_disk_object += $unattached_managed_disk_object_temp
        }
    }

    Write-Output "Creating CSV file for Unattached Managed Disks ==> unattached_managed_disks.csv" -ForegroundColor Green
    $unattached_managed_disk_object | Export-Csv "unattached_managed_disks.csv" -NoTypeInformation -Force
###########################################################
# Obtaining list of unattached UN-MANAGED disks
###########################################################
Write-Output " `n`n*************** Obtaining list of unattached UN-MANAGED disks *************** " -ForegroundColor Cyan

    foreach ($storageIterator in $storage) {
        
        Write-Output "`n`n Iterating over a storage account...." -ForegroundColor Gray
        $storageAccountName = $storageIterator.StorageAccountName
        $storageAccountContext = $storageIterator.Context
        $storageAccountContainer = Get-AzStorageContainer -Context $storageAccountContext

    
        foreach($storageAccountContainer_iterator in $storageAccountContainer){
            
            Write-Output "Iterating over the Container..." -ForegroundColor Gray
            $blob = Get-AzStorageBlob -Container $storageAccountContainer_iterator.Name -Context $storageAccountContext

                foreach ($blobIterator in $blob) {
                
                    if($blobIterator.Name -match ".vhd" -and $blobIterator.ICloudBlob.Properties.LeaseStatus -eq "Unlocked"){
                        #Write-Output "`n" "Blob Name: " $blobIterator.Name " -- LeaseStatus: " $blobIterator.ICloudBlob.Properties.LeaseStatus " -- Container: " $storageAccountContainer_iterator.Name " -- Storage Name:" $storageIterator.StorageAccountName " -- RG Name:" $storageIterator.ResourceGroupName

                        Write-Output "Collecting data about an unattached un-managed disk..." -ForegroundColor Gray
                        $unattached_un_managed_disk_object_temp = new-object PSObject 
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $storageIterator.ResourceGroupName
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "StorageName" -Value $storageIterator.StorageAccountName
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "StorageContainerName" -Value $storageAccountContainer_iterator.Name
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "BlobName" -Value $blobIterator.Name
                        $unattached_un_managed_disk_object_temp | add-member -membertype NoteProperty -name "LeaseStatus" -Value $blobIterator.ICloudBlob.Properties.LeaseStatus
                    
                        # Adding the objects to the final list
                        $unattached_un_managed_disk_object += $unattached_un_managed_disk_object_temp
                    }
                

        #"`n" + "Blob Name: " + $blobIterator.Name + " -- LeaseStatus: " + $blobIterator.ICloudBlob.Properties.LeaseStatus | Out-File c:\AzureUnusedVHDs\VHDlist.txt -Append
                }

        }

    }

    
    Write-Output "Creating CSV file for Unattached Un-Managed Disks ==> unattached_un_managed_disks.csv" -ForegroundColor Green
    $unattached_un_managed_disk_object| Export-Csv "unattached_un_managed_disks.csv"
$Context = New-AzStorageContext -StorageAccountName "unattached" -StorageAccountKey "6xWmOQ3gM5fHpcGmm83u0eMmYPUAFtlDKOoclNwg3VptAJAByli7REDIi3+N06TKV27q7jP9Q6Vx+AStIx/u2w=="
Set-AzStorageBlobContent -Context $Context -Container "unattacheddisk" -File "unattached_un_managed_disks.csv" -Blob "unattached_unmanaged_disk.csv"
Write-Host "Job is Completed"

Write-Output "Creating CSV file for unattached_managed_disk_object ==> unattached_un_managed_disks.csv" -ForegroundColor Green
    $unattached_managed_disk_object| Export-Csv "unattached_managed_disk_object.csv"
$Context = New-AzStorageContext -StorageAccountName "unattached" -StorageAccountKey "6xWmOQ3gM5fHpcGmm83u0eMmYPUAFtlDKOoclNwg3VptAJAByli7REDIi3+N06TKV27q7jP9Q6Vx+AStIx/u2w=="
Set-AzStorageBlobContent -Context $Context -Container "unattacheddisk" -File "unattached_managed_disk_object.csv" -Blob "unattached_managed_disk.csv"
Write-Host "Job is Completed"
