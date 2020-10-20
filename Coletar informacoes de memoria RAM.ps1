Get-WmiObject Win32_PhysicalMemory |
        Select-Object PSComputerName, DeviceLocator, Manufacturer, PartNumber, 
        @{ label = "Size/GB"; expression = { $_.Capacity / 1GB } },
        Speed, Datawidth, TotalWidth |
        Format-Table -AutoSize