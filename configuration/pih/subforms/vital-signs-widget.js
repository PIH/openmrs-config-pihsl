

    const priorities = {
        GREEN: {
            value: 0,
            message: "Normal",
            className: "triage-label-green"
        },
        YELLOW: {
            value: 1,
            message: "Prompt",
            className: "triage-label-yellow"
        },
        ORANGE: {
            value: 2,
            message: "Urgent",
            className: "triage-label-orange"
        },
        RED: {
            value: 3,
            message: "STAT",
            className: "triage-label-red"
        }
    };

    function getPrioritiesClasses() {
        let classNames = [];
        for (const priority in priorities) {
            classNames.push(priorities[priority].className);
        }
        return classNames.join(" ");
    }

    const classNames = getPrioritiesClasses();

    function evaluateBpSystolic(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if (numericValue &lt; 80) {
                return priorities.RED;
            } else if ((numericValue &gt; 139) &amp;&amp; (numericValue &lt; 160)) {
                return priorities.YELLOW;
            } else if (numericValue &gt; 159) {
                return priorities.RED;
            }
        }
        return retValue;
    }

    function evaluateBpDiastolic(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if (numericValue &lt; 51) {
                return priorities.RED;
            } else if ((numericValue &gt; 89) &amp;&amp; (numericValue &lt; 110)) {
                return priorities.YELLOW;
            } else if (numericValue &gt; 109) {
                return priorities.RED;
            }
        }
        return retValue;
    }

    function evaluateHeartRate(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if (numericValue &lt; 110) {
                return priorities.GREEN;
            } else if ((numericValue &gt; 109) &amp;&amp; (numericValue &lt; 120)) {
                return priorities.YELLOW;
            } else if (numericValue &gt; 119) {
                return priorities.RED;
            }
        }
        return retValue;
    }

    function evaluateRespiratoryRate(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if (numericValue &lt; 20) {
                return priorities.GREEN;
            } else if ((numericValue &gt; 19) &amp;&amp; (numericValue &lt; 30)) {
                return priorities.YELLOW;
            } else if (numericValue &gt; 29) {
                return priorities.RED;
            }
        }
        return retValue;
    }

    function evaluateTemperature(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if ((numericValue &lt; 35) || (numericValue &gt;= 38)) {
                return priorities.RED;
            } else if ((numericValue &gt; 37.6) &amp;&amp; (numericValue &lt; 38)) {
                return priorities.YELLOW;
            }
        }
        return retValue;
    }

    function evaluateFhr(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if ((numericValue &lt; 80) || (numericValue &gt;= 200)) {
                return priorities.RED;
            } else if ((numericValue &lt; 101) || (numericValue &gt; 159)) {
                return priorities.YELLOW;
            }
        }
        return retValue;
    }

    function evaluateOxigenSaturation(value) {
        let retValue = priorities.GREEN;
        if (value != null &amp;&amp; !(Number.isNaN(value))) {
            let numericValue = Number(value);
            if (numericValue &lt;= 92) {
                return priorities.RED;
            } else if ((numericValue &gt; 92) &amp;&amp; (numericValue &lt; 95)) {
                return priorities.YELLOW;
            }
        }
        return retValue;
    }

    let vitalsInfo = {
        bp_systolic: {
            evaluate: evaluateBpSystolic,
            value: null
        },
        bp_diastolic: {
            evaluate: evaluateBpDiastolic,
            value: null
        },
        heart_rate: {
            evaluate: evaluateHeartRate,
            value: null
        },
        respiratory_rate: {
            evaluate: evaluateRespiratoryRate,
            value: null
        },
        temperature_c: {
            evaluate: evaluateTemperature,
            value: null
        },
        o2_sat: {
            evaluate: evaluateOxigenSaturation,
            value: null
        },
        fhr: {
            evaluate: evaluateFhr,
            value: null
        }
    };

    function evaluateVitals() {
        let priority = priorities.GREEN;
        let priorityValue = 0;
        for (const obj in vitalsInfo) {
            let vitalValue = vitalsInfo[obj].value;
            let evalPriority = vitalsInfo[obj].evaluate(vitalValue);
            priorityValue = priorityValue + evalPriority.value;
        }
        if (priorityValue &gt;= 2) {
            priority = priorities.RED;
        }
        return priority;
    }

    function calculatePriority() {
        let globalPriority = evaluateVitals();
        if (globalPriority.value &gt;= 2) {
            let drNotified = jq('#contactDr input[type="checkbox"]').is(':checked');
            if ( !drNotified ) {
                jq('.submitButton.confirm.right').attr('disabled', true);
            }
            jq("#confirmMsg").show();
        } else {
            jq('.submitButton.confirm.right').attr('disabled', false);
            jq("#confirmMsg").hide();
        }
        jq('#sticky').removeClass(classNames).addClass(globalPriority.className);
        jq('#statusMessage').text(globalPriority.message);
        return globalPriority;
    }

jq(document).ready( function() {

    jq('#contactDr input[type="checkbox"]').on('change', function() {
        if (jq(this).is(':checked')) {
            // Checkbox is checked
            jq('.submitButton.confirm.right').attr('disabled', false);
        } else {
            calculatePriority();
        }
    });

    // the following calculations happen only in the view mode
    jq(".vitals-values").find('.value').each( function() {
        const vitalsId = jq(this).parent("span").attr('id');
        const vitalValue = jq(this).text();
        let inputElement = jq(this);
        jq(inputElement).removeClass('value');
        jq(inputElement).removeClass(classNames);
        let colorCodingDiv = jq("#" + vitalsId).closest(".colorCodingValue");
        if (vitalsId) {
            if (vitalValue) {
                vitalsInfo[vitalsId].value = vitalValue;
                let vitalsPriority = vitalsInfo[vitalsId].evaluate(vitalsInfo[vitalsId].value);
                if ( vitalsPriority &amp;&amp; colorCodingDiv) {
                    setTimeout(() => {
                        jq(colorCodingDiv).addClass(vitalsPriority.className);
                    }, 100);
                }
            } else {
                vitalsInfo[vitalsId].value = null;
                setTimeout(() => {
                    jq(inputElement).addClass('value');
                }, 100);
            }
        }
    });

    jq(".vitals-values").find('input').on("blur", function() {
        const vitalsId = jq(this).closest("span").attr('id');
        const vitalValue = jq(this).val();
        let inputElement = jq(this);
        jq(inputElement).removeClass('legalValue');
        jq(inputElement).removeClass(classNames);
        if (vitalsId) {
            if (vitalValue) {
                vitalsInfo[vitalsId].value = vitalValue;
                let vitalsPriority = vitalsInfo[vitalsId].evaluate(vitalsInfo[vitalsId].value);
                if (vitalsPriority) {
                    setTimeout(() => {
                        jq(inputElement).removeClass('legalValue').addClass(vitalsPriority.className);
                    }, 100);
                }
            } else {
                vitalsInfo[vitalsId].value = null;
                setTimeout(() => {
                    jq(inputElement).addClass('legalValue');
                }, 100);
            }
        }
        calculatePriority();
    });

    jq(".vitals-values").find('input').attr('autocomplete', 'off');
    jq(".vitals-values").find('input').trigger("blur");
    calculatePriority();

});