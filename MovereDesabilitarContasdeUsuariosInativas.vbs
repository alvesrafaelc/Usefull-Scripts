' **********************************************************************
' * Script para mover e desabilitar contas de usuários inativas do AD  *
' * Autor: Adriano Lima e Anderson Carvalho                                                *
' * Esse script move as contas de usuários inativas por mais de 90 dias*
' * para a OU Contas inativas                                          *   
' * ********************************************************************

'Option Explicit

Dim objRootDSE, strConfig, adoConnection, adoCommand, strQuery
Dim adoRecordset, objDC, TempDtCreated, TempDtDelUser, TempLastLogonTimestamp, strDays, intReqCompare
Dim strDNSDomain, objShell, lngBiasKey, lngBias, k, arrstrDCs()
Dim strDN, dtmDate, objDate, lngDate, objList, strUser, objOU, DaysDelete 
Dim strBase, strFilter, strAttributes, lngHigh, lngLow,OUContasDesabilitadas, tempCN, objEmail
Const ADS_UF_ACCOUNTDISABLE = 2

Dim intUAC,objUser
Dim objFSO, objFolder, objTextFile, objFile
Dim strDirectory, strFile, strText
strDirectory = "c:\"
strFile = "\LogScriptContasUsuariosInativas.txt"
strText = ""

' Create the File System Object
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Check that the strDirectory folder exists
If objFSO.FolderExists(strDirectory) Then
	Set objFolder = objFSO.GetFolder(strDirectory)
Else
	Set objFolder = objFSO.CreateFolder(strDirectory)
	objTextFile.WriteLine("Just created " & strDirectory)
End If

If objFSO.FileExists(strDirectory & strFile) Then
	Set objFolder = objFSO.GetFolder(strDirectory)
Else
	Set objFile = objFSO.CreateTextFile(strDirectory & strFile)
	WobjTextFile.WriteLine( "Just created " & strDirectory & strFile)
End If 

set objFile = nothing
set objFolder = Nothing

' OpenTextFile Method needs a Const value
' ForAppending = 8 ForReading = 1, ForWriting = 2
Const ForAppending = 8

Set objTextFile = objFSO.OpenTextFile _
(strDirectory & strFile, ForAppending, True)

' Write log header on the txt file
 
objTextFile.WriteLine("                                                                               " )
objTextFile.WriteLine("   -------------------------     " & Now() & "    -------------------------    " )
objTextFile.WriteLine("                                                                               " )

' Use a dictionary object to track latest lastLogonTimestamp for each user.
Set objList = CreateObject("Scripting.Dictionary")
objList.CompareMode = vbTextCompare

' Obtain local Time Zone bias from machine registry.
Set objShell = CreateObject("Wscript.Shell")
lngBiasKey = objShell.RegRead("HKLM\System\CurrentControlSet\Control\" _
    & "TimeZoneInformation\ActiveTimeBias")
If (UCase(TypeName(lngBiasKey)) = "LONG") Then
    lngBias = lngBiasKey
ElseIf (UCase(TypeName(lngBiasKey)) = "VARIANT()") Then
    lngBias = 0
    For k = 0 To UBound(lngBiasKey)
        lngBias = lngBias + (lngBiasKey(k) * 256^k)
    Next
End If

' Determine configuration context and DNS domain from RootDSE object.
Set objRootDSE = GetObject("LDAP://RootDSE")
strConfig = objRootDSE.Get("configurationNamingContext")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

' Use ADO to search Active Directory for ObjectClass nTDSDSA.
' This will identify all Domain Controllers.
Set adoCommand = CreateObject("ADODB.Command")
Set adoConnection = CreateObject("ADODB.Connection")
adoConnection.Provider = "ADsDSOObject"
adoConnection.Open "Active Directory Provider"
adoCommand.ActiveConnection = adoConnection

strBase = "<LDAP://" & strConfig & ">"
strFilter = "(objectClass=nTDSDSA)"
strAttributes = "AdsPath"
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"

adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 60
adoCommand.Properties("Cache Results") = False

Set adoRecordset = adoCommand.Execute

' Enumerate parent objects of class nTDSDSA. Save Domain Controller
' AdsPaths in dynamic array arrstrDCs.
k = 0
Do Until adoRecordset.EOF
    Set objDC = _
        GetObject(GetObject(adoRecordset.Fields("AdsPath")).Parent)
    ReDim Preserve arrstrDCs(k)
    arrstrDCs(k) = objDC.DNSHostName
    k = k + 1
    adoRecordset.MoveNext
Loop

' Retrieve lastLogonTimestamp attribute for each user on each Domain Controller.
For k = 0 To Ubound(arrstrDCs)
    strBase = "<LDAP://" & arrstrDCs(k) & "/" & strDNSDomain & ">"
    strFilter = "(&(objectCategory=person)(objectClass=user))"
    strAttributes = "distinguishedName,lastLogonTimestamp"
    strQuery = strBase & ";" & strFilter & ";" & strAttributes _
        & ";subtree"
    adoCommand.CommandText = strQuery
    On Error Resume Next
    Set adoRecordset = adoCommand.Execute
    If (Err.Number <> 0) Then
        On Error GoTo 0
        objTextFile.WriteLine("Domain Controller not available: " & arrstrDCs(k))
       
    Else
        On Error GoTo 0
        Do Until adoRecordset.EOF
            strDN = adoRecordset.Fields("distinguishedName")
            lngDate = adoRecordset.Fields("lastLogonTimestamp")
            On Error Resume Next
            Set objDate = lngDate
            If (Err.Number <> 0) Then
                On Error GoTo 0
                dtmDate = #1/1/1601#
            Else
                On Error GoTo 0
                lngHigh = objDate.HighPart
                lngLow = objDate.LowPart
                If (lngLow < 0) Then
                    lngHigh = lngHigh + 1
                End If
                If (lngHigh = 0) And (lngLow = 0 ) Then
                    dtmDate = #1/1/1601#
                Else
                    dtmDate = #1/1/1601# + (((lngHigh * (2 ^ 32)) _
                        + lngLow)/600000000 - lngBias)/1440
                End If
            End If
            If (objList.Exists(strDN) = True) Then
                If (dtmDate > objList(strDN)) Then
                    objList.Item(strDN) = dtmDate
                End If
            Else
                objList.Add strDN, dtmDate
            End If
            adoRecordset.MoveNext
        Loop
    End If
Next

' Output latest lastLogonTimestamp date for each user.
objTextFile.WriteLine("Contas de Usuários desabilitadas e movidas : ")
objTextFile.WriteLine(" ")

For Each strUser In objList.Keys
   strDays = 60
   DaysDelete = 90
   intReqCompare = Now - strDays 
   If (objList.Item(strUser) < intReqCompare)  Then 
		TempLastLogonTimestamp = Trim(objList.Item(strUser))
		' Recupera referência ao objeto
		strUser = "LDAP://" & struser
		set objUser = GetObject(strUser)
	
    	TempDtCreated = objUser.WhenCreated
	    TempDtDelUser = Now () - TempDtCreated
	    ' Move e desabilita as contas inativas por mais de 90 dias,que não estão nas OUs Contas de servico ou Contas Inativas
		If ((Now() - TempDtCreated) > 90 And instr(1,strUser,"OU=Contas de servico")=0 And instr(1,strUser,"OU=Contas Inativas")=0) Then			
			objTextFile.WriteLine( strUser & " ; " & "Last Logon: " & TempLastLogonTimestamp & " ; " & " Dt Criacao: " & objUser.WhenCreated)
			tempCN = objUser.CN
			'  'Muda status da conta para desabilitada
			'objUser.Put "userAccountControl", intUAC OR ADS_UF_ACCOUNTDISABLE
			objUser.SetInfo
			'Recupera referência da OU para onde as contas desabilitadas serão movidas
			OUContasDesabilitadas = "LDAP://ou=usuarios,ou=Contas Inativas,dc=secv,dc=net"
			Set objOU = GetObject(ouContasDesabilitadas)
			'Move a conta antiga para a OU destino
			'objOU.MoveHere strUser, vbNullString
    		TempDtCreated = objUser.WhenCreated
	    	TempDtDelUser = Now () - TempDtCreated
   		End If
   End If    
Next


' Clean up.
adoConnection.Close
Set objRootDSE = Nothing
Set adoConnection = Nothing
Set adoCommand = Nothing
Set adoRecordset = Nothing
Set objDC = Nothing
Set objDate = Nothing
Set objList = Nothing
Set objShell = Nothing

WScript.Echo "O resultado da operação está no arquivo c:\temp\LogScriptContasUsuariosInativas.txt e também foi enviado por email para admredes@secv.net"


objTextFile.Close

'Send the log file by e-mail.
'Set objEmail = CreateObject("CDO.Message")
'objEmail.From = "admredes@secv.net"
'objEmail.To = "admredes@secv.net"
'objEmail.Subject = now() & " - Contas de usuários desabilitadas e movidas!!" 
'objEmail.Textbody = objEmail.TextBody & "A lista de usuários movidos e desabilitados está me anexo." & vbCrLf 
'objEmail.TextBody = objEmail.TextBody & "As contas foram movidas para a OU Contas Inativas/Usuarios."
'objEmail.AddAttachment "c:\temp\LogScriptContasUsuariosInativas.txt"
'objEmail.Configuration.Fields.Item _
' ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
'objEmail.Configuration.Fields.Item _
' ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = _
'"gates"
'objEmail.Configuration.Fields.Item _
' ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
'objEmail.Configuration.Fields.Update
'objEmail.Send


WScript.Quit