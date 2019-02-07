*** Settings ***

Force Tags              File System
Documentation           Test Suite File to operate File System Related Tasks
Suite Setup		Connect
Suite Teardown		SSHLibrary.Close All Connections
Test Timeout            2 minute

#Library 	 OperatingSystem
Resource         nuage-cats/cats_lib/resources/cats_common.robot
Resource         nuage-cats/cats_lib/resources/sros.robot

*** Test Cases ***

Check CPM redundancy
	[Documentation]      Test case to check the CPM redundancy on the node.
	Check Cards

List Directory
	[Documentation]      Test case which lists the directory structure on the node.
	List Directory	

Create and Check Testfile
        [Documentation]      A testfile is created and given the read only priviledge, it is checked it file attrib command output has "R".
	Create and Check Testfile

Try to Delete Testfile
        [Documentation]      The attempt to delete the testfile with read only priviledge only is done, this test will fail if it can deletes the testfile.
	Try to Delete Testfile

Repair Disk Drive
        [Documentation]      file repair command is applied to a disk drive, the output of the command should give an "OK".
	Repair Disk Drive

Create Test Directory
        [Documentation]      Test case which creates a test directory and check its existance afterwards.
	Create Test Directory

Move Testfile to Testdirectory
        [Documentation]      Test case where it tries to move the testfile under the test directory created one step below. This fails when the file can't be moved. 
	Move Testfile to Testdirectory

Try to Delete Testdirectory
        [Documentation]      test directory is tried to be deleted while it has a file under it. The test fails when the deletion attempt of the directory is successful. 
	Try to Delete Testdirectory

Move Testfile to Root Directory
        [Documentation]      The testcase where it moves the testfile to root directory in order to be able to delete the test directory afterwards. 
	Move Testfile to Root Directory
	
Delete Testdirectory
        [Documentation]      Try to delete the test directory for the second time, this time it should be successful because it should be an empty folder.
	Delete Testdirectory

*** Keywords ***

Connect
    	SROS.Login
   	...            sros_address=172.29.7.115
   	...            username=admin
    	...            password=admin
    	...            timeout=15s

Show Cards
	SROS.Execute SROS Command    show card

Check Cards
	${output} =     SROS.Execute SROS Command
	...     /show card | match cpm
	Should Match Regexp  ${output}  up/active
	Should Match Regexp  ${output}  up/standby
	...    msg=CPMs are not redundant
	...    values=False

List Directory
        Check If Drive Volume Exists    cf1-a:\
        Check If Drive Volume Exists    cf2-a:\
        Check If Drive Volume Exists    cf3-a:\
        Check If Drive Volume Exists    cf1-b:\
        Check If Drive Volume Exists    cf2-b:\
        Check If Drive Volume Exists    cf3-b:\
 
Create and Check Testfile
	SROS.Execute SROS Command    echo "lorem ipsum dolor sit amet" > testfile.txt
	
	${output} =         SROS.Execute SROS Command    file dir	
	Should Match Regexp  ${output}  testfile.txt
        ...    msg=testfile.txt does not exist
        ...    values=False

	SROS.Execute SROS Command   file attrib testfile.txt +r

	${output} =	    SROS.Execute SROS Command   file attrib | match expression testfile.txt
        Should Match Regexp  ${output}  ^ R 
	...    msg=testfile.txt file does not have read (R) permission
        ...    values=False
	
Try to Delete Testfile
        ${output} =         SROS.Execute SROS Command   file delete testfile.txt 
	Should Match Regexp  ${output}  CLI Access is denied for 
        ...    msg=File deleted but it should have been read only
        ...    values=False	
	

Repair Disk Drive
	${output} =         SROS.Execute SROS Command   file repair cf3-a:
	Should Match Regexp  ${output}  Drive cf3: on slot . is OK
        ...    msg=Disk Drive is not OK
        ...    values=False
	
Create Test Directory
	SROS.Execute SROS Command   file md cf3-a:/Testdirectory
	${output} = 	    SROS.Execute SROS Command   file dir cf3-a:/ | match expression Testdirectory
	Should Match Regexp  ${output}	DIR
        ...    msg=Testdirectory not found
        ...    values=False
	#SROS.Execute SROS Command   file dir cf3-a:/

Move Testfile to Testdirectory
	SROS.Execute SROS Command   file attrib testfile.txt -r
	${output} =	    SROS.Execute SROS Command   file move cf3-a:/testfile.txt cf3-a:/Testdirectory
	Should Match Regexp  ${output}  OK
	...    msg=testfile.txt file couldn't be moved
        ...    values=False
	${output} =         SROS.Execute SROS Command   file dir cf3-a:/Testdirectory
	Should Match Regexp  ${output}  testfile.txt
	...    msg=testfile.txt is not under Testdirectory
        ...    values=False

Try to Delete Testdirectory
	SSHLibrary.Write     file rd cf3-a:/Testdirectory
	SSHLibrary.Read Until    Are you sure
	SSHLibrary.Write     y${\n}
	${output}=           SSHLibrary.Read Until Regexp     [A|B]:.*?[#|$|>]
	Should Match Regexp  ${output}   CLI Cannot delete
        ...    msg=Testdirectory deleted but it should have contain testfile.txt
        ...    values=False

Move Testfile to Root Directory
	${output} =         SROS.Execute SROS Command   file move cf3-a:/Testdirectory/testfile.txt ./
	Should Match Regexp  ${output}  OK
        ...    msg=testfile.txt couldn't be moved from Testdirectory to Root directory
        ...    values=False

Delete Testdirectory
	SSHLibrary.Write     file rd cf3-a:/Testdirectory
        SSHLibrary.Read Until    Are you sure
        ${output}=	      SROS.Execute SROS Command	y${\n}	
	Should Match Regexp  ${output}   OK
        ...    msg=Testdirectory couldn't be deleted
        ...    values=False

	${output} =         SROS.Execute SROS Command   file dir cf3-a:/Testdirectory
        Should Match Regexp  ${output}   Not Found
        ...    msg=Testdirectory found but it shouldn't be there
        ...    values=False

Check If Drive Volume Exists
        [Arguments]    ${drive}
	${output} =	    SROS.Execute SROS Command    file dir ${drive}
	Should Not Match Regexp  ${output}  File Not Found
	...    msg=No ${drive} volume drive exist
	...    values=False
