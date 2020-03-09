# Copy File to VM (Person running this should have access within the Guest)
$vm = Get-VM XXX
Get-Item C:\Temp\forMD.txt | Copy-VMGuestFile -Destination C:\Temp -VM $vm -LocalToGuest -GuestUser Administrator -GuestPassword '50ft5(rv)'

# Copy File From VM (Person running this should have access within the Guest)
$vm = Get-VM XXX
Copy-VMGuestFile -Source D:\MD\RyanMagic -Destination C:\Temp -VM $vm -GuestToLocal -GuestUser Administrator -GuestPassword '50ft5(rv)'
