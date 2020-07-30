*** Settings ***
Library           OperatingSystem
#Library           robot.api.logger
Library           String
Library           Collections
Library           CreateExcelFile.py
Library           CreateExcelFile.ExcelUtility
Library           BuiltIn
Library           GetFreeSims.py
Library           GetFreeSims.CNMUtility
Library           Collections
Library           Dialogs
Library           OperatingSystem
Library           String
Library           QWeb
Library           ../pacelibraries/SFWeb.py
Library           DateTime

*** Variables ***
${sFileName}      ${CURDIR}${/}OnlineFirstDataSheet.xlsx
${sSheetName}
${Global Cantact Name}    ${EMPTY}
${Global Billing Account}    ${EMPTY}
${InteractionCaseID_GlobalVariable}    ${EMPTY}
${caseid_globalvariable}    ${EMPTY}
${FaultCaseTicketNumber_GlobalVariable}    ${EMPTY}
${SubscriptionNumber1_GlobalVariable}    ${EMPTY}
${SubscriptionNumber2_GlobalVariable}    ${EMPTY}
${SimNumber_GlobalVariable}    ${EMPTY}
${SubscriptionInventoryFileName}    ${CURDIR}${/}SubscriptionInventoryFileName.xlsx
${EPPDataCreationFileName}    ${CURDIR}${/}EPPDataCreation.xlsx
${ImagesPath}     ${CURDIR}${/}Images
${SimInventoryFileName}    ${CURDIR}${/}SimInventory.xlsx
${MobileSuspendedSubscription}    ${EMPTY}
${MobileTerminatedSubscription}    ${EMPTY}
${MassMACDFileName}    ${CURDIR}${/}MassMACDNetti.xlsx
${VakioSLA}    ${CURDIR}${/}VakioSLA.xlsx
${VMARecalulation}    ${CURDIR}${/}VMARecalculation.xlsx
${ProfileLanguage}    ${EMPTY}
${OrderToCancel}    ${EMPTY}
${sResultFilePath}    ${EMPTY}
${sResultFile}    ${EMPTY}
${SubscriptionNumber}    ${EMPTY}
${DeviceCatogoryName}    ${EMPTY}
${ELSACatogoryName}    ${EMPTY}
${MobileCatogory}    ${EMPTY}
${DateInYearMonthDayFormat}    ${EMPTY}
${PreInstallationText}    ${EMPTY}
${OrderNumberff}    ${EMPTY}
${OrderNumberff1}    ${EMPTY}
${language}       English
${MobileProductMassMACD}    ${CURDIR}${/}MobileProductMassChange.xlsx
${BROWSER}      gc

*** Keywords ***
Appstate
    [Arguments]                 ${state}    ${arg1}=None
    ${state}=                   Convert To Lowercase    ${state}
    Set Test Variable           ${state}
    RunKeywordAndReturnIf       '${state}' == 'login'
    ...                         Appstate login
    RunKeywordAndReturnIf       '${state}' == 'main'
    ...                         Appstate main
    RunKeywordAndReturnIf       '${state}' == 'setup'
    ...                         Appstate setup    ${arg1}
    RunKeywordAndReturnIf       '${state}' == 'inpersonate'
    ...                         Appstate inpersonate    ${arg1}
    Fail                        Unknown appstate: ${state}
      

Appstate Login
    [Documentation]             Check that session is logged in. If not, then log in.
    ...                         If we get session expired popup, we try to log in again.
    ${ended}=                   IsText             Your session has ended
    RunKeywordIf                ${ended}           GoTo    about:blank
    ${ended}=                   IsText             Istuntosi on päättynyt
    RunKeywordIf                ${ended}           GoTo    about:blank
    ${logged}=                  IsElement          //*[@class\='slds-icon-waffle']
    FOR    ${i}                 IN RANGE    3
        Return From Keyword If      ${logged}
        SetConfig               TextMatch    //*[not(self::script) and normalize-space(translate(., "\u00a0", " "))\="{0}" and not(descendant::*[normalize-space(translate(., "\u00a0", " "))\="{0}"])]|//input[(@type\="button" or @type\="reset" or @type\="submit") and normalize-space(translate(@value, "\u00a0", " "))\="{0}"]|//*[@title\="{0}"]|//*[@value\="{0}"]|//*[@alt\="{0}"]
        Go To                       ${sf_address}
        TypeText                    Username             ${SFDC_USERNAME}
        TypeSecret                  Password             ${SFDC_PASSWORD}
        ClickText                   Log In
        SetConfig                   XHRTimeout           none
        IsElement                   //*[@class\='slds-icon-waffle']    20s
        Sleep                       4s
        ${ended}=                   IsText                      Your session has ended
        Exit For Loop If            ${ended} == ${FALSE}
        ${ended}=                   IsText                      Istuntosi on päättynyt
        Exit For Loop If            ${ended} == ${FALSE}
    END
    #VerifyText                ${GlobalProperties_TestEnvironment}
    Sleep                       3s
    ${SalesforceClassicView}    IsElement            //*[@id\='AppBodyHeader']    20s
    Run Keyword If              '${SalesforceClassicView}' == 'True'     ClickText    Switch to Lightning Experience
    VerifyElement               //*[@class\='slds-icon-waffle']    20s
    
Appstate main
    [Documentation]             Takes browser to SalesForce main page, logs in if necessary.
    ...                         Closes other windows if open.
    SetConfig                   CssSelectors       On
    SwitchWindow                1
    CloseOthers
    Appstate Login

Appstate setup
    [Documentation]             Goes to setup page and types search term to Quick Find box.
    ...                         Then clicks search term if found.
    [Arguments]                 ${setup location}
    Should Not Be Equal         None    ${setup location}    Setup target is missing from Appstate   Setup
    Appstate                    login
    ScanClick                   Setup     //*[@id\='related_setup_app_home']    # Setup for current app
    ClickText                   related_setup_app_home    selector=id
    SwitchWindow                NEW
    VerifyText                  Most Recently Used
    TypeText                    Quick Find      ${setup location}
    VerifyText                  Try using Global Search.
    VerifyText                  ${setup location}
    ClickText                   ${setup location}

Appstate inpersonate
    [Documentation]             Goes to setup page, types search term to search box.
    ...                         Then selects it.
    [Arguments]                 ${new_user}
    Should Not Be Equal         None    ${new_user}    New user is missing from Appstate   inpersonate
    Appstate login
    ${personated}=              IsText           Logged in as ${new_user}    3s
    ReturnFromkeywordIf         ${personated}
    ScanClick                   Setup     //*[@id\='related_setup_app_home']
    ClickText                   related_setup_app_home    selector=id
    Sleep                       1s
    SwitchWindow                NEW
    Sleep                       1s
    VerifyText                  Most Recently Used
    TypeText                    Search Setup    ${new_user}
    Sleep                       2s
    VerifyText                  Search Setup
    ClickText                   Search Setup
    VerifyText                  //*[@title\="${new_user}"]
    Sleep                       1s
    SkimClick                   //*[@title\="${new_user}"]
    SkimClick                   Login
    Sleep                       3s
    ${VerifyUserLoggedIn}       IsText            Logged in        30s
    Run Keyword Unless          ${VerifyUserLoggedIn}        Refresh Page
    Run Keyword Unless          ${VerifyUserLoggedIn}        Sleep    6s
    ${started}=                 IsText            Getting Started    15s
    ReturnFromkeywordIf         ${started} == ${FALSE}
    ${url}=                     GetUrl
    ${url_trunc}=               fetch from left    ${url}    .com
    ${new_url}=                 Catenate   SEPARATOR=    ${url_trunc}  .com
    GoTo                        ${new_url}
    VerifyText                  ${new_user}

DetectCurrentLanguage
    [Documentation]         Returns 'eng' or 'fin' depending which language is on
    ${lang}=                WordBranch    Näytä profiili   View profile
    ReturnFromKeywordIf     '${lang}' == 'Näytä profiili'    fin
    ReturnFromKeywordIf     '${lang}' == 'View profile'      eng

SetLanguage
    [Documentation]    Changes language. If language is alreayd set
    ...                don't do anything.
    [Arguments]               ${lang}=${language}
    VerifyElement             //*[@class\='slds-icon-waffle']
    RunKeywordAndReturnIf     '${lang}' == 'Finnish'
    ...                       SetLanguageFinnish
    RunKeywordAndReturnIf     '${lang}' == 'English'
    ...                       SetLanguageEnglish
    Fail                      Unknown language: ${lang}

SetLanguageFinnish
    ${lang}=     WordBranch    Näytä profiili   View profile
    Return From Keyword If    '${lang}' == 'Näytä profiili'
    ClickText    View profile
    Clicktext    Settings
    ${page}=     IsText                  Locale
    RunKeywordUnless    ${page}
    ...          ScanClick    Language & Time Zone    Locale    timeout=10s
    Dropdown     Language     Suomi
    ClickText    Save
    Sleep        5s
    IsText       Näytä profiili          timeout=5s
    IsText       Näytä profiili          timeout=5s

SetLanguageEnglish
    ${lang}=     WordBranch    Näytä profiili   View profile
    Return From Keyword If    '${lang}' == 'View profile'
    ClickText    Näytä profiili
    Clicktext    Asetukset
    ${page}=     IsText                  Paikkamääritys
    RunKeywordUnless    ${page}
    ...                 ScanClick    Kieli ja aikavyöhyke    Paikkamääritys     timeout=30s
    Dropdown     Kieli        English
    ClickText    Tallenna
    Sleep        5s
    IsText       View profile            timeout=5s
    IsText       View profile            timeout=5s

PE
    [Arguments]             ${cause_str}= Test execution paused. Press OK to continue.
    Pause Execution         ${cause_str}

SetGlobalEnvVariable
    [Documentation]                   Read GlobalProperties_TestEnvironment variable from either command line or environment variables
    ${testenv_var}=                   Get Variable Value    ${GlobalProperties_TestEnvironment}
    ${testenv_var}=                   Run Keyword If        '${testenv_var}' != 'None'    Remove String    ${testenv_var}    ${SPACE}    _Org
    ${testenv_var}                    Convert To String     ${testenv_var}
    Return From Keyword If            '${testenv_var}' != 'None'    ${testenv_var}
    ${testenv_var}=                   Get Environment Variable    GlobalProperties_TestEnvironment
    ${testenv_var}=                   Remove String    ${testenv_var}    ${SPACE}    _Org
    ${testenv_var}                    Convert To String     ${testenv_var}
    Return From Keyword               ${testenv_var}

Set Variables
    [Documentation]         Verifies that environment variables are defined and loads them.
    ...                     Password is loaded from command line so it is not logged
    Environment Variable Should Be Set    SFDC_USERNAME                       msg=Environment variable SFDC_USERNAME is not set. You must run environment script before starting testing.
    Variable Should Exist                 ${SFDC_PASSWORD}                    msg=Password is not set. You must supply password from command line option: -v SFDC_PASSWORD:%SFDC_PASSWORD%
    ${SFDC_USERNAME}=                     Get Environment Variable            SFDC_USERNAME
    ${GlobalProperties_TestEnvironment}=  SetGlobalEnvVariable

    ${sf_address}=                        SetEnvironmentAddress                       

    Set Suite Variable                ${sf_address}
    Set Suite Variable                ${SFDC_USERNAME}
    Set Suite Variable                ${GlobalProperties_TestEnvironment}
    Set Suite Variable                ${sSheetName}    ${GlobalProperties_TestEnvironment}_TestDataSheet

SetEnvironmentAddress
    [Documentation]         Choosing URL Based on Enviornment
    ${environment}=                       Get Environment Variable    GlobalProperties_TestEnvironment
    ${environment}=                       Remove String       ${environment}                          ${SPACE}    _Org
    ${sf_address}=                        Set Variable If    '${environment}' == 'ElisaProduction'    https://login.salesforce.com/
    Return From Keyword If                '${environment}' == 'ElisaProduction'    ${sf_address}
    ${sf_address}=                        Set Variable If    '${environment}' != 'ElisaProduction'    https://test.salesforce.com/
    Return From Keyword                   ${sf_address}

Setup Suite
    Set Variables
    SetConfig               DefaultTimeout      60s
    Open Browser            about:blank         ${BROWSER}

Teardown Suite
    Close All Browsers

UseApp
    [Documentation]         Switches to new SalesForce application with switch button.
    ...                     Parameter is application name (JSON Import)
    [Arguments]             ${application}
    ${AppsEng}=             SetVariable    Apps
    ${AppsFin}=             SetVariable    Sovellukset
    ${ViewAllEng}=          SetVariable    View All
    ${ViewAllFin}=          SetVariable    Näytä kaikki
    ${ViewProfileEng}=      SetVariable    View profile
    ${ViewProfileFin}=      SetVariable    Näytä profiili
    ${AllItemsEng}=         SetVariable    All Items
    ${AllItemsFin}=         SetVariable    Kaikki sovellukset
    ${AppLauncherEng}=      SetVariable    App Launcher
    ${AppLauncherFin}=      SetVariable    Sovelluskäynnistin
    ${SearchAppsEng}=       SetVariable    Search apps or items...
    ${SearchAppsFin}=       SetVariable    Hae sovelluksia tai kohteita...

    ${lang}=                DetectCurrentLanguage
    VerifyText              //*[contains(@class, 'appLauncher')]//button
    ScanClick               //*[contains(@class, 'appLauncher')]//button    	${Apps${lang}}
    ${ViewAll}              IsElement                  					//*[contains(@class,'button')][text()\='${ViewAll${lang}}']
    Run Keyword If          '${ViewAll}' == 'True'     					IsText    (//*[@aria-label\='${Apps${lang}}']//a)[1]     5s

    ClickText               ${ViewProfile${lang}}
    VerifyText              //*[contains(@class, 'appLauncher')]//button
    ScanClick               //*[contains(@class, 'appLauncher')]//button    	${Apps${lang}}
    ${ViewAll}              IsElement                  					//*[contains(@class,'button')][text()\='${ViewAll${lang}}']
    Run Keyword If          '${ViewAll}' == 'True'     					ClickElement    //*[contains(@class,'button')][text()\='${ViewAll${lang}}']
    Run Keyword If          '${ViewAll}' == 'True'     					IsText    (//*[@aria-label\='Apps']//a)[1]     5s
    Run Keyword If          '${ViewAll}' == 'True'     					VerifyNoElement    //*[contains(@class,'button')][text()\='${ViewAll${lang}}']
    VerifyText              ${AllItems${lang}}
    VerifyText              ${AppLauncher${lang}}
    Sleep                   3
    TypeText                ${SearchApps${lang}}    			   		${application}
    VerifyText              ${application}             					60s
    SkimClick               ${application}             					${AllItems${lang}}

WordBranch
    [Documentation]     Keyword gets two strings as input. It then searches for them and returns on found. This is useful in appstate where we need to detect what page we are on
    [Arguments]         ${first}    ${second}    ${timeout}=15s
    ${timeout_s}=       Convert Time             ${timeout}
    ${timeout_i}=       Convert To Integer       ${timeout_s}
    FOR    ${i}    IN RANGE    ${timeout_s}
        ${first_found}=     IsText    ${first}       timeout=0.4s
        Return From Keyword If     ${first_found} == True     ${first}
        ${second_found}=    IsText    ${second}      timeout=0.4s
        Return From Keyword If     ${second_found} == True    ${second}
        Sleep    0.2
    END

Global Search For Links
    [Arguments]    ${SearchLabel}    ${SelectionNameFromResultWrapper}
       
    VerifyText              //input[contains(@title,'Search')]
    TypeText               //input[contains(@title,'Search')]          ${SearchLabel}\n
    Sleep    4s    
    ${AccountText}    Is Text    Account Name 
    Run Keyword If    '${AccountText}' == 'False'    VerifyText     (//*[@class\='slds-input slds-combobox__input'])[1]    60
    Run Keyword If    '${AccountText}' == 'False'    Scan Click     (//*[@class\='slds-input slds-combobox__input'])[1]    (//*[text()\='Accounts'])[1]   
    # Debug On           
    Run Keyword If    '${AccountText}' == 'False'    VerifyText              (//*[text()\='Accounts'])[1]    50
    Run Keyword If    '${AccountText}' == 'False'    Click Text              (//*[text()\='Accounts'])[1]
    Run Keyword If    '${AccountText}' == 'False'    VerifyText         //input[contains(@title,'Search')]
    Run Keyword If    '${AccountText}' == 'False'    TypeText           //input[contains(@title,'Search')]       ${SearchLabel}\n   
    Sleep                   1
    VerifyText              Search Results
    Sleep                   2
    ScrollTo                Account Name               timeout=25s
    VerifyText              //*[text()\='${SelectionNameFromResultWrapper}'][@data-aura-class\='uiOutputURL' or @class\='gridTitle slds-page-header__title slds-text-color--default']/../../../../..//th//*[@title\='${SearchLabel}']    100s
    ClickElement            //*[text()\='${SelectionNameFromResultWrapper}'][@data-aura-class\='uiOutputURL' or @class\='gridTitle slds-page-header__title slds-text-color--default']/../../../../..//th//*[@title\='${SearchLabel}']
    VerifyNoElement         //*[text()\='${SelectionNameFromResultWrapper}'][@data-aura-class\='uiOutputURL' or @class\='gridTitle slds-page-header__title slds-text-color--default']/../../../../..//th//*[@title\='${SearchLabel}']

Open given Excel file
    #Set File directory paths
    #${pre}    ${post} =    Split String    ${CURDIR}    OnlineFirstAutomation    1
    #${GettingSourceDirectory}    Catenate    SEPARATOR=    ${pre}    OnlineFirstAutomation
    Set Global Variable    ${sFileName}    ${CURDIR}${/}OnlineFirstDataSheet.xlsx
    Set Global Variable    ${SubscriptionInventoryFileName}    ${CURDIR}${/}SubscriptionInventoryFileName.xlsx
    Set Global Variable    ${SimInventoryFileName}    ${CURDIR}${/}SimInventory.xlsx
    Set Global Variable    ${VMARecalulation}    ${CURDIR}${/}VMARecalculation.xlsx
    Set Global Variable    ${EPPDataCreationFileName}    ${CURDIR}${/}EPPDataCreation.xlsx
    #Check that the given Excel Exists
    ${inputfileStatus}    ${msg}    Run Keyword And Ignore Error    OperatingSystem.File Should Exist    ${sFileName}
    Run Keyword If    "${inputfileStatus}"=="PASS"    info    ${sFileName} Test data file exist
    ...    ELSE    Fail    Cannot locate the given Excel file.
    #Open Excel    ${sFileName}
    Log    ${sFileName}
    Log    Read given excel file
     
TestCaseID
    ${pre}    ${post} =    Split String    ${TEST_NAME}    /    1
    #log    ${pre}
    #log    ${post}
    [Return]    ${pre}
    
Create Result File
    [Documentation]    Create a result file at runtime
    ${sResultFile}    Add TimeStamp to File    ${sResultFilePath}
    #Create Result file at the given location
    Create File    ${sResultFile}
    Append To File    ${sResultFile}    TC_Number\tTC_Desc\tStatus\tComments\n
    Set Global Variable    ${sResultFile}    ${sResultFile}

Add TimeStamp to File
    [Arguments]    ${sResultFilePath}
    [Documentation]    Creating the Name of the Results file based on the current TimeStamp
    ${date}    OperatingSystem.Run    echo %date%
    ${yyyy}    ${mm}    ${dd}    Split String    ${date}    /
    ${time}    OperatingSystem.Run    echo %time%
    ${hh}    ${min}    ${sec}    Split String    ${time}    :
    #Creating TimeStamp
    ${timestamp}    Set Variable    ${mm}${dd}${yyyy}_${hh}${min}
    log    ${timestamp}
    ${sfileName}    Set Variable    ${sResultFilePath}_${timestamp}.xls
    [Return]    ${sfileName}

Append Test Details to Results File
    [Documentation]    Adding Test Case Details to Results File
    #Fetch TC No
    ${sTCNo}    ${sTestDesc}    Split String    ${TESTNAME}    _
    Append To File    ${sResultFile}    ${sTCNo}\t${sTestDesc}\t

TestCaseName
    ${pre}    ${post} =    Split String    ${TEST_NAME}    /    1
    #log    ${pre}
    #log    ${post}
    [Return]    ${post}

Read Data From Excel Xlrd
    [Arguments]    ${TestCaseID}    ${ColumnName}
    ${SearchData}    Read Data From Excel    ${sFileName}    ${sSheetName}    ${TestCaseID}    ${ColumnName}
    [Return]    ${SearchData}

Get Free Sim From CNM
    ${freesim1}    Run Keyword If    '${GlobalProperties_TestEnvironment}' == 'UAT'    GetFreeSims.CNMUtility.Get Free Sim From RM And CNM UAT
    ${freesim}    Run Keyword If    '${GlobalProperties_TestEnvironment}' == 'UAT'    Convert To String    ${freesim1}
    Return From Keyword If    '${GlobalProperties_TestEnvironment}' == 'UAT'    ${freesim}
    #
    ${freesim1}    Run Keyword If    '${GlobalProperties_TestEnvironment}' == 'DEVint'    GetFreeSims.CNMUtility.get Free Sim From RM and CNM Devint
    ${freesim}    Run Keyword If    '${GlobalProperties_TestEnvironment}' == 'DEVint'    Convert To String    ${freesim1}
    Return From Keyword If    '${GlobalProperties_TestEnvironment}' == 'DEVint'    ${freesim}
    
Read System Storage
    [Arguments]    ${SheetName}
    ScanClick                   Setup     //*[@id\='related_setup_app_home']
    ClickText                   related_setup_app_home    selector=id
    Sleep                       1s
    SwitchWindow                NEW
    Sleep                       1s
    VerifyText                  Most Recently Used
    TypeText                    Quick Find    Storage Usage
    Sleep                       2s
    VerifyText                  Quick Find
    ClickText                   Quick Find
    ClickElement                //*[contains(@class,'parent')]//*[@title\='Storage Usage']
    #
    Log Screenshot
    @{TotalRows}    Create List    Data Storage    File Storage    Big Object Storage
    FOR    ${Rows}    IN    @{TotalRows}
        Write To Row Data    ${SheetName}    ${Rows}
    END
    #
    @{TotalRows}    Create List    Attributes    Orchestration Step Dependencies    Orchestration Steps    Conditional Step Criterias    Attribute Fields
    ...    Hubs    Exception Error Log    Accounts    Contacts    Orchestration Processes    Product Configurations
    ...    Billing Accounts
    : FOR    ${Rows}    IN    @{TotalRows}
    \    Write To Row Data for Current Data Storage Usage    ${SheetName}    ${Rows}
    Switch Window    2

Write To Row Data
    [Arguments]    ${SheetName}    ${Rows}
    @{names}=    Create List    Limit    Used    Percent Used
    ${RecordNumber}    Set Variable    ${0}
    ${Data Storage element}    Catenate    SEPARATOR=    //*[text()\='    ${Rows}    ']/ancestor::tr/td
    @{Data Storage}    Get Text Of All Elements    ${Data Storage element}
    FOR    ${Data}    IN    @{Data Storage}
        Log    ${names[${RecordNumber}]}
        ${NewSimNumber}    Write Data Into Excel    ${CURDIR}${/}SystemStorageData.xlsx    ${SheetName}    ${Rows}    ${names[${RecordNumber}]}
        ...    ${Data}
        ${RecordNumber}    Evaluate    ${RecordNumber} + 1
    END

Write To Row Data for Current Data Storage Usage
    [Arguments]    ${SheetName}    ${Rows}
    @{names}=    Create List    Limit    Used    Percent Used
    ${RecordNumber}    Set Variable    ${0}
    ${Data Storage element}    Catenate    SEPARATOR=    //*[text()\='    ${Rows}    ']/ancestor::tr/td
    @{Data Storage}    Get Text Of All Elements    ${Data Storage element}
    FOR    ${Data}    IN    @{Data Storage}
         Log    ${names[${RecordNumber}]}
         ${NewSimNumber}    Write Data Into Excel    ${CURDIR}${/}SystemStorageData.xlsx    ${SheetName}    ${Rows}    ${names[${RecordNumber}]}
         ...    ${Data}
         ${RecordNumber}    Evaluate    ${RecordNumber} + 1
    END

Get Text Of All Elements
    [Arguments]    ${Variable_xpath}
    ${xpath}    Set Variable    ${Variable_xpath}
    ${count}=    GetElementCount    ${xpath}
    ${names}=    Create List
    FOR    ${i}    IN RANGE    1    ${count} + 1
         ${name}=    GetText    (${xpath})[${i}]
         Sleep    2s
         Append To List    ${names}    ${name}
         log    ${names}
    END
    [Return]    @{names}

    
Reload And Wait For An Element For MACDs
    [Arguments]    ${ElementToWaitTill120Seconds}
    FOR    ${INDEX}    IN RANGE    1    12
         Log    ${INDEX}
         Sleep    10s
         ScrollTo    Details    timeout=25s
         VerifyText    Details
         ClickText     Details
         Sleep    6s
         ${LookforElement}=    IsElement    ${ElementToWaitTill120Seconds}
         Run Keyword If    '${LookforElement}' == 'False'    Refresh Page
         Run Keyword Unless    '${LookforElement}' == 'False'    Exit For Loop
    END
