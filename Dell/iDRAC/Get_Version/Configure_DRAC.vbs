Option Explicit

const ForWriting = 2
const ForReading = 1

main

Public Sub main()

    Dim ipfile
    Dim dracconfigfile
    Dim logfile
    Dim racadm_command
    Dim command

    Dim fso 'As FileSystemObject
    Dim file 'As TextStream
    Dim log 'As TextStream
    
    Dim line 'As String
    
    On Error Resume Next
   
    ' File containing a list of IP address - one in each line
    ipfile = "ipaddr.txt"
    
    ' This is the drac configuration file which contains the configuration.
    dracconfigfile = "password.cfg"
    
    ' Logfile to store the logs of the execution
    logfile = "config.Log"
    
    ' RACADM command to be executed

    ' Intel
    racadm_command = "racadm -u root -p XXX$"
    'racadm_command = "racadm -u root -p (Th3L!tsR0ut)"

    ' Unix
    ' racadm_command = "racadm -u Admin -p S@v3_a11#"

    Set fso = CreateObject("Scripting.FileSystemObject")
    
    If Not fso.FileExists(ipfile) Then
        'MsgBox "IP address file " & ipfile & " not found or cannot be read"
        WScript.echo "IP address file " & ipfile & " not found or cannot be read."
        WScript.Quit
    End If
    If Not fso.FileExists(dracconfigfile) Then
        'MsgBox "DRAC configuration file " & dracconfigfile & " not found or cannot be read"
        WScript.echo "DRAC configuration file " & dracconfigfile & " not found or cannot be read"
        WScript.Quit
    End If

    ' Logfile gets overwritten everytime this script is executed
    If fso.FileExists(logfile) Then
        fso.DeleteFile logfile, False
    End If

    Set log = fso.OpenTextFile(logfile, ForWriting, True)
    'log.WriteLine "Starting batch configuration of DRAC from file " & ipfile

    Set file = fso.OpenTextFile(ipfile, ForReading, False)

    Do Until file.AtEndOfStream
        line = file.ReadLine
        
        'Ingnore blank lines
        If Len(line) > 0 Then
            
            ' Ingnore comments (lines with a ;)
            If Mid(line, 1, 1) <> ";" Then
            
               'WScript.echo "Configuring DRAC at ip address: " & line
               
               log.WriteLine "========================================"
               log.WriteLine "DRAC IP " & line
               
               command = racadm_command & " -r " & line & " getconfig -g idracinfo"
               'command = racadm_command & " -r " & line & " config -f password.cfg"
               'command = racadm_command & " -r " & line & " sslcsrgen -g -f G:\Ryan\iDRAC_Hardening\zSSL.req"
               'command = racadm_command & " -r " & line & " sslcertupload -t 1 -f G:\Ryan\iDRAC_Hardening\iDRAC_Cert.cer"
               'command = "ping " & line 'debug hack
               
               'log.WriteLine command
               log.WriteLine ProcessCommand(command)
               
            End If
            
        End If
        
    Loop

    if Err.Number <> 0 then
      'WScript.echo "Error in main " & Err.Description
      log.WriteLine "Error in main " & Err.Description
    End if

   'WScript.echo "done"
   'log.WriteLine "done"

   file.Close
   log.Close
    
End Sub

Private Function ProcessCommand(command)

   Dim WshShell 'As Object
   Dim objScriptExec 'As Object
   Dim strStdOut
	Dim sReturn

   Set WshShell = CreateObject("WScript.Shell")
   
   'WScript.echo command
   
   Set objScriptExec = WshShell.Exec(command)
   strStdOut = objScriptExec.StdOut.ReadAll
   'WScript.echo strStdOut

	if objScriptExec.Exitcode <> 0 then
	  'WScript.echo "Failed. See logfile for details"
	else
	  'WScript.echo "DRAC configured successfully"
	End if

	if Err.Number <> 0 then
     	  sReturn = "Error processing " & command & ". " & Err.Description
	else
	  sReturn = strStdOut
	End if

   Set objScriptExec = Nothing
	
   ProcessCommand = sReturn

   'WScript.echo "" 'empty line
   
End Function