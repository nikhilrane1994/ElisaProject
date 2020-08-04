*** Settings ***
Resource          CustomKeywordsLibrary.robot
Library    DatabaseLibrary   

*** Test Cases ***
Demo
    # Write Data Into Excel    OnlineFirstDataSheet.xlsx    UAT_TestDataSheet    Demo    SearchforanAccountname    Basic
    ${Val}    Read Data From Excel    OnlineFirstDataSheet.xlsx    UAT_TestDataSheet    Demo    SearchforanAccountname
    Log To Console    ${Val}
    
