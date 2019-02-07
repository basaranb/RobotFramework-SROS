
*** Settings ***
Documentation          Resource Management 

Library                Vodafone
Resource               nuage-cats/cats_lib/resources/cats_common.robot
Resource               nuage-cats/cats_lib/resources/catsutils.robot
Suite Setup            Initialize Connection
Suite Teardown         SSHLibrary.Close Connection
*** Variables ***

${CF_USAGE_TRESHOLD_FOR_WARNING}      90

${HOST}                172.29.7.115
${USERNAME}            admin
${PASSWORD}            admin


${HOST2}                172.29.7.116
${USERNAME2}            admin
${PASSWORD2}            admin


*** Test Cases ***

Check Flash Cards
  [Documentation]           Checks Flash card number and their available capacity
  ${output}=           Execute SROS Command
  ...                  show card "a" detail | match expression "Model|Percent"
  ${result}=           Get Flash and Usage     ${output}    ${CF_USAGE_TRESHOLD_FOR_WARNING} 
  Should Be True       ${result}      1

Copy test file
  [Documentation]       Copies file text_b.txt from ${HOST} to ${HOST2} via SCP protocol
  Execute SROS Command
  ...                  echo "lorem ipsum dolor sit amet" > test_b.txt

  SSHLibrary.Write      file scp cf3-a:/test_b.txt ${USERNAME2}@${HOST2}:cf3-a:/ router "management"
  SSHLibrary.Read Until     password:
  SSHLibrary.Write      admin${\n}
  ${output}=            SSHLibrary.Read Until Regexp     [A|B]:.*?[#|$]
  #Log To Console        ${output}

Shutdown file
  [Documentation]      Shuts down a compact flash card. Shutting down cf3-a
  ${output}=           Execute SROS Command
  ...                  show card "a" detail | match expression "Flash|State|State"
  #Log To Console       ${output}
  Execute SROS Command
  ...                  file shutdown cf3-a:
  ${output}=           Execute SROS Command
  ...                  show card "a" detail | match expression "Flash|State|State"
  #Log To Console       ${output}
  Execute SROS Command
  ...                  file no shutdown cf3-a:

Show type command
  [Documentation]      Shows the content of the file
  ${output}=           Execute SROS Command
  ...                  file type cf3-a:/bof.cfg
  #Log To Console       ${output}

Show version command
  [Documentation]      Displays the version of the file
  ${output}=           Execute SROS Command
  ...                  file version cf3-a:/test_b.txt
  #Log To Console       ${output}

  ${output}=           Execute SROS Command
  ...                  file version cf3-a:/bof.cfg
  #Log To Console       ${output}

  ${output}=           Execute SROS Command
  ...                  file version cf3-a:/boot.ldr
  #Log To Console       ${output}


Show version check command
  [Documentation]      Validates TiMOS image files
  ${output}=           Execute SROS Command
  ...                  file version check TiMOS-SR-15.0.R5/iom.tim
  #Log To Console       ${output}
  ${output}=           Execute SROS Command
  ...                  file version check TiMOS-SR-15.0.R5/cpm.tim
  #Log To Console       ${output}
  ${output}=           Execute SROS Command
  ...                  file version check TiMOS-SR-15.0.R5/boot.ldr
  #Log To Console       ${output}

Show wildcard usage
  [Documentation]      Wildcard replaces any string
  Execute SROS Command
  ...                  echo "lorem ipsum dolor sit amet" > testfile.txt
  Execute SROS Command
  ...                  echo "lorem ipsum dolor sit amet" > testfile1.txt
  Execute SROS Command
  ...                  echo "lorem ipsum dolor sit amet" > testfile2.txt

  ${output}=           Execute SROS Command
  ...                  file dir cf3-a:/
  #Log To Console       ${output}
  
  ${output}=           Execute SROS Command
  ...                  file delete cf3-a:/test* force
  #Log To Console       ${output}

  ${output}=           Execute SROS Command
  ...                  file dir cf3-a:/
  #Log To Console       ${output}


 
*** Keywords ***

Initialize Connection
  SROS.Login
  ...   sros_address=${HOST}
  ...   username=${USERNAME}
  ...   password=${PASSWORD}
  ...   timeout=3000 seconds
  
Show BGP Routes
  Execute SROS Command
  ...   show router bgp routes | match Routes

Show Card
  ${output}=    Execute SROS Command
  ...   show card
  [Return]    ${output}

Show MDA
  Execute SROS Command
  ...   show mda

Show MDA 3 Resources
  Execute SROS Command
  ...   tools dump system-resources 3 

Show System Resources
  Execute SROS Command
  ...   tools dump resource-usage system

Show All Cards Resources
  Execute SROS Command
  ...   tools dump resource-usage card all

