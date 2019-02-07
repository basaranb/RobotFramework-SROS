

*** Settings ***

Documentation          LAG Port Failure and Recover Traffic Distribution

Library                SROSLAG
Library                SSHLibrary
Resource               nuage-cats/cats_lib/resources/cats_common.robot
Resource               nuage-cats/cats_lib/resources/catsutils.robot
Suite Setup            Initialize Connection
Suite Teardown         Drop Connection


*** Variables ***

${HOST}                172.29.7.116
${USERNAME}            admin
${PASSWORD}            admin

${LAGID}               99

# wait timeout for port up/down action
${WAITTIMEOUT}         99999 

# for monitor lag command 
${INTERVAL}            3
${REPEAT}              5


*** Test Cases ***

LAG Must Be UP
  [Documentation]       LAG Must be up for this test to run
  ${output}=            Execute SROS Command
                        ...  show lag ${LAGID}
  ${status}=            Check LAG Up             ${output}
  Should Be Equal       ${status}                UP

Discover Ports  
  [Documentation]       Find port attached to LAG
  ${output}=            Execute SROS Command
                        ...  show lag ${LAGID} port
  ${portlist}=          Discover LAG Ports       ${LAGID}              ${output}
  Set Global Variable   ${portlist}
  :FOR    ${port}    IN    @{portlist}
  \   Log        Found Port: ${port}


View Traffic Before Fail
  [Documentation]       Log traffic distribution on ports before port fail
  Log Traffic


Wait For Port Fail
  [Documentation]       Wait for a port status to become DOWN
  :FOR    ${i}       IN RANGE    1   ${WAITTIMEOUT}
  \   ${status}=             Check All Ports Up 
  \   Log                    ${status}
  \   Exit For Loop If       '${status}' == 'DOWN'
  \   Sleep          1s
  Should Be Equal    '${status}'       'DOWN'


View Traffic After Fail
  [Documentation]       Log traffic distribution on ports after port fail
  Log Traffic


Wait For Port Recover
  [Documentation]       Wait for all ports to recover
  :FOR    ${i}       IN RANGE    1   ${WAITTIMEOUT}
  \   ${status}=             Check All Ports Up 
  \   Exit For Loop If       '${status}' == 'UP'
  \   Sleep          2s
  Should Be Equal            '${status}'       'UP'


View Traffic After Recover
  [Documentation]       Log traffic distribution on ports after all ports recover
  Log Traffic


*** Keywords ***


Initialize Connection
  #SSHLibrary.Enable Ssh Logging     sshlog.txt
  SROS.Login
  ...   sros_address=${HOST}
  ...   username=${USERNAME}
  ...   password=${PASSWORD}
  ...   timeout=3000 seconds
  

Drop Connection
  SSHLibrary.Close All Connections


Check All Ports Up
  ${output}=         Execute SROS Command
                     ...    show lag ${LAGID} port
  ${result}=         Get All Ports Status       ${output}
  [Return]           ${result}


Check Port Status
  [Arguments]    ${port}
  ${output}=         Execute SROS Command
                     ...    show lag ${LAGID} port
  ${state}=          Check LAG Up     ${output}
  [Return]           ${state}


Log Traffic
  Execute SROS Command
  ...     monitor lag 99 interval ${INTERVAL} repeat ${REPEAT} rate 

