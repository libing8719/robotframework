*** Settings ***
Suite Setup       Create Output With Robot    ${MODIFIED OUTPUT}    ${EMPTY}    ${TEST DATA}
Suite Teardown    Remove File    ${MODIFIED OUTPUT}
Resource          modifier_resource.robot
Resource          rebot_resource.robot

*** Variables ***
${MODIFIED OUTPUT}    %{TEMPDIR}/pre_rebot_modified.xml

*** Test Cases ***
Modifier as path
    Run Rebot    --prerebotmodifier ${CURDIR}/ModelModifier.py -l ${LOG}    ${MODIFIED OUTPUT}
    Output and log should be modified    visited

Modifier as name
    Run Rebot    --prerebotmodifier ModelModifier --pythonpath ${CURDIR} -l ${LOG}    ${MODIFIED OUTPUT}
    Output and log should be modified    visited

Modifier with arguments separated with ':'
    Run Rebot    --PreRebotModifier ${CURDIR}/ModelModifier.py:new:tags:named=tag -l ${LOG}    ${MODIFIED OUTPUT}
    Output and log should be modified    new    tags    named-tag

Modifier with arguments separated with ';'
    Run Rebot    --prerebot "ModelModifier;1;2;3" --prere "ModelModifier;4;5;n=t" -P ${CURDIR} -l ${LOG}    ${MODIFIED OUTPUT}
    Output and log should be modified    1    2    3    4    5    n-t

Non-existing modifier
    Run Rebot    --prerebotmod NobodyHere -l ${LOG}    ${MODIFIED OUTPUT}
    ${quote} =    Set Variable If    ${INTERPRETER.is_py3}    '    ${EMPTY}
    Stderr Should Match
    ...    ? ERROR ? Importing model modifier 'NobodyHere' failed: *Error:
    ...    No module named ${quote}NobodyHere${quote}\nTraceback (most recent call last):\n*
    Output and log should not be modified

Invalid modifier
    Run Rebot    --prerebotmodifier ${CURDIR}/ModelModifier.py:FAIL:Message -l ${LOG}    ${MODIFIED OUTPUT}
    Stderr Should Start With
    ...    [ ERROR ] Executing model modifier 'ModelModifier' failed:
    ...    Message\nTraceback (most recent call last):\n
    Output and log should not be modified

Error if all tests removed
    ${result} =    Run Rebot Without Processing Output
    ...    --prerebot ${CURDIR}/ModelModifier.py:REMOVE:ALL:TESTS    ${MODIFIED OUTPUT}
    Stderr Should Be Equal To
    ...    [ ERROR ] Suite 'Pass And Fail' contains no tests after model modifiers.${USAGE TIP}\n
    Should Be Equal    ${result.rc}    ${252}

--ProcessmptySuite when all tests removed
    Run Rebot    --ProcessEmptySuite --PreRebot ${CURDIR}/ModelModifier.py:REMOVE:ALL:TESTS    ${MODIFIED OUTPUT}
    Stderr Should Be Empty
    Length Should Be    ${SUITE.tests}    0

Modifiers are used before normal configuration
    ${result} =    Run Rebot
    ...    --include added --prereb ${CURDIR}/ModelModifier.py:CREATE:name=Created:tags=added    ${MODIFIED OUTPUT}
    Stderr Should Be Empty
    Length Should Be    ${SUITE.tests}    1
    ${tc} =    Check test case    Created    FAIL
    Lists should be equal    ${tc.tags}    ${{['added']}}
