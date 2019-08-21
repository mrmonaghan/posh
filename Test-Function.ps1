function Test-Function {
        Get-Process A* | Select-Object -First 5 -ExpandProperty Name
}
Test-Function