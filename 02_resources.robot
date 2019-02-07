

*** Settings ***

Documentation          Resource Management 

Library                SROSResources
Library                SSHLibrary
Resource               nuage-cats/cats_lib/resources/cats_common.robot
Resource               nuage-cats/cats_lib/resources/catsutils.robot
Suite Setup            Initialize Connection
Suite Teardown         Drop Connection


*** Variables ***

${HOST}                172.29.7.115
${USERNAME}            admin
${PASSWORD}            admin


*** Test Cases ***

CPU Utilization Below 90 Percent
  [Documentation]      Check to see if current CPU utilization is below a certain percent.
  ${output}=           Execute SROS Command
                       ...                   show system cpu | match expression "Total|^([ ]{3})Idle|^([ ]{3})Usage|Busiest Core Utilization"
  ${result}=           Get CPU Usage         ${output}
  Should Be True       ${result} < 90

Memory Pools Test
  [Documentation]      Check to see if putting load in CPU will cause drop in available memory.
  ${output}=           Execute SROS Command
                       ...                   show system memory-pools | match expression "Current Total Size|Total In Use|Available Memory"
  Save Current Memory Status                 ${output}
  Start Show BGP Routes                      ${HOST}                    ${USERNAME}       ${PASSWORD}
  ${output}=           Execute SROS Command
                       ...                   show system memory-pools | match expression "Current Total Size|Total In Use|Available Memory"
  Get Running Memory   ${output}

Resources Test
  [Documentation]      Check if some system values are within acceptable range.
  Show Card
  Show MDA
  ${output}=                                 Show MDA 3 Resources 
  Parse Table With Four Columns              ${output}                  treshold=0.000000000000001     failOnTreshholdExceed=False     
  ${output}=                                 Show System Resources
  Parse Table With Four Columns              ${output}                  treshold=0.90     failOnTreshholdExceed=True
  ${output}=                                 Show All Cards Resources
  Parse Table With Four Columns              ${output}                  treshold=0.90     failOnTreshholdExceed=True

*** Keywords ***

Initialize Connection
  [Documentation]                            Prepare SSH Connection that is going to be used throughout this test
  #SSHLibrary.Enable Ssh Logging     sshlog.txt
  SROS.Login
  ...   sros_address=${HOST}
  ...   username=${USERNAME}
  ...   password=${PASSWORD}
  ...   timeout=3000 seconds
  
Drop Connection
  [Documentation]                            SSH Connection Cleanup
  SSHLibrary.Close All Connections

Show Card
  Execute SROS Command
  ...   show card

Show MDA
  Execute SROS Command
  ...   show mda

Show MDA 3 Resources
    ${output}=        Execute SROS Command
                      ...   tools dump system-resources 3 
  [Return]            ${output}

Show System Resources
  ${output}=          Execute SROS Command
                      ...   tools dump resource-usage system
  [Return]            ${output}

Show All Cards Resources
  ${output}=          Execute SROS Command
                      ...   tools dump resource-usage card all
  [Return]            ${output}

