*** Settings ***
Resource          CustomKeywordsLibrary.robot
Library    DatabaseLibrary   

*** Test Cases ***
Demo
     Write Data Into Excel    OnlineFirstDataSheet.xlsx    UAT_TestDataSheet    Demo    SearchforanAccountname    BasicNeww1
    Create File    ${CURDIR}/data.txt   Subscriber : 'SUB074125895'\n
    Append To File    ${CURDIR}/data.txt    Order : 'ON0478541' 
    
