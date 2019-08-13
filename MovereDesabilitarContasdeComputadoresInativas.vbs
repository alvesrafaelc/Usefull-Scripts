' ********************************************************
' * Script para mover e desabilitar contas inativas do AD*
' * Autor: Adriano Lima e Anderson Carvalho                                 * 
' * ******************************************************

Option Explicit

Dim strFilePath, objFSO, objFile, adoConnection, adoCommand
Dim objRootDSE, strDNSDomain, strFilter, strQuery, adoRecordset
Dim strComputerDN, objShell, lngBiasKey, lngBias
Dim objDate, dtmPwdLastSet, k, objEmail, TextBody
Dim intDays, strTargetOU, objTargetOU, objComputer
Dim intTotal, intInactive, intNotMoved, intNotDisabled

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("Wscript.Shell")
objFSO.CreateTextFile("c:\OldComputers.txt")


' Specify the log file. This file will be created if it does not
' exist. Otherwise, the program will append to the file.

strFilePath = "c:\OldComputers.txt"

' Specify the minimum number of days since the password was last set for
' the computer account to be considered inactive.
intDays = 90

' Specify the Distinguished Name of the Organizational Unit into
' which inactive computer objects will be moved.
strTargetOU = "OU=Contas Inativas,ou=Computadores,dc=secv,dc=net"

' Bind to target Organizational Unit.
On Error Resume Next
Set objTargetOU = GetObject("LDAP://" & strTargetOU)
If (Err.Number <> 0) Then
    On Error GoTo 0
    Wscript.Echo "Organization Unit not found: " & strTargetOU
    Wscript.Quit
End If
On Error GoTo 0

' Open the log file for write access. Append to this file.
On Error Resume Next
Set objFile = objFSO.OpenTextFile(strFilePath, 8, True, 0)
If (Err.Number <> 0) Then
    On Error GoTo 0
    Wscript.Echo "File " & strFilePath & " cannot be opened"
    Set objFSO = Nothing
    Wscript.Quit
End If
On Error GoTo 0

' Obtain local time zone bias from machine registry.
lngBiasKey = objShell.RegRead("HKLM\System\CurrentControlSet\Control\" & "TimeZoneInformation\ActiveTimeBias")
If (UCase(TypeName(lngBiasKey)) = "LONG") Then
    lngBias = lngBiasKey
ElseIf (UCase(TypeName(lngBiasKey)) = "VARIANT()") Then
    lngBias = 0
    For k = 0 To UBound(lngBiasKey)
        lngBias = lngBias + (lngBiasKey(k) * 256^k)
    Next
End If

' Use ADO to search the domain for all computers.
Set adoConnection = CreateObject("ADODB.Connection")
Set adoCommand = CreateObject("ADODB.Command")
adoConnection.Provider = "ADsDSOOBject"
adoConnection.Open "Active Directory Provider"
Set adoCommand.ActiveConnection = adoConnection

' Determine the DNS domain from the RootDSE object.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("DefaultNamingContext")

' Filter to retrieve all computer objects.
strFilter = "(objectCategory=computer)"

' Retrieve Distinguished Name and date password last set.
strQuery = "<LDAP://" & strDNSDomain & ">;" & strFilter & ";distinguishedName,pwdLastSet;subtree"

adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 30
adoCommand.Properties("Cache Results") = False

' Write information to log file.
objFile.WriteLine "Pesquisando contas de computatores inativas:"
objFile.WriteLine "Início: " & Now
objFile.WriteLine "Base da pesquisa: " & strDNSDomain
objFile.WriteLine "Arquivo de log: " & strFilePath
objFile.WriteLine "Dias de inatividade: " & intDays
objFile.WriteLine "OU destino: " & strTargetOU
objFile.WriteLine "----------------------------------------------"

' Initialize totals.
intTotal = 0
intInactive = 0
intNotMoved = 0
intNotDisabled = 0

' Enumerate all computers and determine which are inactive.
Set adoRecordset = adoCommand.Execute
Do Until adoRecordset.EOF
    strComputerDN = adoRecordset.Fields("distinguishedName").Value
    If Instr(strComputerDN,"OU=Domain Controllers") = 0 And InStr(strComputerDN, "OU=Contas Inativas") = 0 Then
    ' Escape any forward slash characters, "/", with the backslash
    ' escape character. All other characters that should be escaped are.
    strComputerDN = Replace(strComputerDN, "/", "\/")
    intTotal = intTotal + 1
    ' Determine date when password last set.
    Set objDate = adoRecordset.Fields("pwdLastSet").Value
    dtmPwdLastSet = Integer8Date(objDate, lngBias)
    If InStr(dtmPwdLastSet, "1/1/1601") = 0 Then
    ' Check if computer object inactive.
    If (DateDiff("d", dtmPwdLastSet, Now) > intDays) Then
        ' Computer object inactive.
        intInactive = intInactive + 1
        objFile.WriteLine "Inactive: " & strComputerDN & " - password last set: " & dtmPwdLastSet
        ' Move computer object to the target OU.
        On Error Resume Next
''''''''''''''''''''''''''''''''''''''        Set objComputer = objTargetOU.MoveHere("LDAP://" & strComputerDN, vbNullString)
        If (Err.Number <> 0) Then
            On Error GoTo 0
            intNotMoved = intNotMoved + 1
            objFile.WriteLine "Cannot move: " & strComputerDN
        End If
        ' Disable the computer account.
        On Error Resume Next
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''        objComputer.AccountDisabled = True
        ' Save changes to Active Directory.
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''        objComputer.SetInfo
        If (Err.Number <> 0) Then
            On Error GoTo 0
            intNotDisabled = intNotDisabled + 1
            objFile.WriteLine "Não pôde desabilitar: " & strComputerDN
        End If
        On Error GoTo 0
   End If
   End If
   End If
    adoRecordset.MoveNext
Loop
adoRecordset.Close

' Write totals to log file.
objFile.WriteLine "Término: " & Now
objFile.WriteLine "Total de computadores encontrados:    " & intTotal
objFile.WriteLine "Inativos:                             " & intInactive
objFile.WriteLine "Contas inativas não movidas:          " & intNotMoved
objFile.WriteLine "Contas inativas não desabilitadas:    " & intNotDisabled
objFile.WriteLine "----------------------------------------------"

' Display summary.
'Wscript.Echo "Computer objects found:         " & intTotal
'Wscript.Echo "Inactive:                       " & intInactive
'Wscript.Echo "Inactive accounts not moved:    " & intNotMoved
'Wscript.Echo "Inactive accounts not disabled: " & intNotDisabled
'Wscript.Echo "See log file: " & strFilePath

' Clean up.
objFile.Close
adoConnection.Close
Set objFile = Nothing
Set objFSO = Nothing
Set objShell = Nothing
Set adoConnection = Nothing
Set adoCommand = Nothing
Set objRootDSE = Nothing
Set adoRecordset = Nothing
Set objComputer = Nothing

'Wscript.Echo "Done"

Function Integer8Date(objDate, lngBias)
    ' Function to convert Integer8 (64-bit) value to a date, adjusted for
    ' time zone bias.
    Dim lngAdjust, lngDate, lngHigh, lngLow
    lngAdjust = lngBias
    lngHigh = objDate.HighPart
    lngLow = objDate.LowPart
    ' Account for bug in IADsLargeInteger property methods.
    If (lngHigh = 0) And (lngLow = 0) Then
        lngAdjust = 0
    End If
    lngDate = #1/1/1601# + (((lngHigh * (2 ^ 32)) + lngLow) / 600000000 - lngAdjust) / 1440
    Integer8Date = CDate(lngDate)
End Function

WScript.Echo "O resultado da operação está no arquivo c:\OldComputers.txt e também foi enviado por email para admredes@secv.net"

'Email Notification
 
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''Set objEmail = CreateObject("CDO.Message")
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.From = "admredes@secv.net"
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.To = "admredes@secv.net"
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Subject = now() & "Contas de computador desabilitadas e movidas"
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Textbody = objEmail.TextBody & "A lista de computadores movidos e desabilitados está me ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''anexo." & vbCrLf 
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.TextBody = objEmail.TextBody & "As contas foram movidas para a OU Contas ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''Inativas/Computadores."
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.AddAttachment "C:\OldComputers.txt"
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''"gates.secv.net" 
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Configuration.Fields.Item ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Configuration.Fields.Update
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''objEmail.Send