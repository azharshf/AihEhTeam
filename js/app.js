// app.js

/**
 * Main Application Logic
 * Handles UI state, form navigation, BMI calculation, and ties ML/Rules engines together.
 */

document.addEventListener('DOMContentLoaded', () => {
    
    const form = document.getElementById('lipid-form');
    const steps = document.querySelectorAll('.form-step');
    const indicators = document.querySelectorAll('.step');
    const progressBar = document.getElementById('progress-bar');
    const emergencyAlert = document.getElementById('emergency-alert');
    
    // Checkboxes
    const symptomNone = document.getElementById('symptom_none');
    const dangerChecks = document.querySelectorAll('.danger-check input');
    const allChecks = document.querySelectorAll('input[name^="symptom_"]');
    
    // BMI Elements
    const heightInput = document.getElementById('height');
    const weightInput = document.getElementById('weight');
    const bmiDisplay = document.getElementById('bmi-display');
    const bmiCategory = document.getElementById('bmi-category');
    
    // Theme
    const themeBtn = document.getElementById('theme-toggle');
    let isDark = true; // Default dark

    // Navigation state
    let currentStep = 1;
    const totalSteps = 5;
    
    // --- Theme Toggle ---
    themeBtn.addEventListener('click', () => {
        isDark = !isDark;
        document.body.setAttribute('data-theme', isDark ? 'dark' : 'light');
        themeBtn.innerHTML = isDark ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
    });

    // --- Emergency Symptoms Logic ---
    symptomNone.addEventListener('change', (e) => {
        if(e.target.checked) {
            allChecks.forEach(cb => {
                if(cb.id !== 'symptom_none') cb.checked = false;
            });
            emergencyAlert.classList.add('hidden');
        }
    });

    dangerChecks.forEach(cb => {
        cb.addEventListener('change', () => {
            if(cb.checked) {
                symptomNone.checked = false;
                emergencyAlert.classList.remove('hidden');
            } else {
                // check if any danger still checked
                const anyDanger = Array.from(dangerChecks).some(c => c.checked);
                if(!anyDanger) emergencyAlert.classList.add('hidden');
            }
        });
    });

    // --- BMI Auto-Calculate ---
    const calcBMI = () => {
        const h = parseFloat(heightInput.value);
        const w = parseFloat(weightInput.value);
        if (h > 0 && w > 0) {
            const h_m = h / 100;
            const bmi = (w / (h_m * h_m)).toFixed(1);
            bmiDisplay.innerText = bmi;
            
            let cat = "", colorClass = "";
            if(bmi < 18.5) { cat = "Underweight"; colorClass = "text-warning"; }
            else if(bmi < 25) { cat = "Normal weight"; colorClass = "text-success"; }
            else if(bmi < 30) { cat = "Overweight"; colorClass = "text-warning"; }
            else { cat = "Obese"; colorClass = "text-danger"; }
            
            bmiCategory.innerText = cat;
            bmiCategory.className = `metric-desc ${colorClass}`;
            
            // Store BMI internally for ML model
            form.dataset.bmi = bmi;
        }
    };
    heightInput.addEventListener('input', calcBMI);
    weightInput.addEventListener('input', calcBMI);

    // --- Form Navigation ---
    const updateProgress = (step) => {
        const pct = ((step - 1) / (totalSteps - 1)) * 100;
        progressBar.style.width = `${pct}%`;
        
        indicators.forEach(ind => {
            const indStep = parseInt(ind.getAttribute('data-step'));
            if(indStep <= step) ind.classList.add('active');
            else ind.classList.remove('active');
        });
    };

    const showStep = (stepNumber) => {
        steps.forEach(s => s.classList.remove('active'));
        document.getElementById(`step-${stepNumber}`).classList.add('active');
        updateProgress(stepNumber);
    };

    // Next/Prev Buttons
    document.querySelectorAll('.next-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            // Basic validation for current step
            const currentStepDiv = document.getElementById(`step-${currentStep}`);
            const requiredInputs = currentStepDiv.querySelectorAll('input[required], select[required]');
            let valid = true;
            requiredInputs.forEach(input => {
                if(!input.value) {
                    input.style.borderColor = 'var(--danger)';
                    valid = false;
                } else {
                    input.style.borderColor = 'var(--card-border)';
                }
            });
            
            if(valid) {
                currentStep = parseInt(btn.getAttribute('data-next'));
                showStep(currentStep);
            }
        });
    });

    document.querySelectorAll('.prev-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            currentStep = parseInt(btn.getAttribute('data-prev'));
            showStep(currentStep);
        });
    });

    // --- Form Submission & Analysis ---
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Collect Data
        const formData = new FormData(form);
        const data = Object.fromEntries(formData.entries());
        data.bmi = form.dataset.bmi;

        // Determine if we have emergency symptoms
        const hasEmergency = data.symptom_chest_pain || data.symptom_stroke || data.symptom_sob || data.symptom_abdomen;
        
        // Determine if we have lipid lab values
        const hasLipids = data.tc || data.ldl || data.hdl || data.tg || data.lpa;

        // Run Analysis
        let result = {};
        
        if (hasEmergency) {
            result.category = "Emergency";
            result.gaugeValue = 180;
            result.message = "Emergency warning: Your symptoms may be urgent. Please seek emergency medical care now.";
            result.typeBadge = "Symptom Triage";
        } 
        else {
            // 2026 ACC/AHA Rule-Based Analysis
            const rulesResult = RulesEngine.analyzeLipids(data);
            result.category = rulesResult.category;
            result.message = rulesResult.message;
            result.breakdown = rulesResult.breakdown;
            result.preventRisk = rulesResult.preventRisk;
            result.lpaAssessment = rulesResult.lpaAssessment;
            result.cacRecommendation = rulesResult.cacRecommendation;
            result.therapyEscalation = rulesResult.therapyEscalation;
            result.typeBadge = "2026 ACC/AHA Rule-Based Analysis";
            
            // Map category to gauge (0-180)
            const gMap = { "Low": 45, "Moderate": 90, "High": 135, "Very High": 180 };
            result.gaugeValue = gMap[result.category];
            
            // Show/Hide Lipid Breakdown UI
            if (hasLipids) {
                document.getElementById('lipid-breakdown-section').classList.remove('hidden');
                renderLipidTable(result.breakdown, data.lipid_unit);
            } else {
                document.getElementById('lipid-breakdown-section').classList.add('hidden');
                const mlResult = MLPredictor.predictRisk(data);
                result.factors = mlResult.topFactors;
                renderFactors(result.factors);
            }
        }

        // Show Results Dashboard
        document.getElementById('assessment-form').classList.add('hidden');
        document.getElementById('progress-container').classList.add('hidden');
        document.getElementById('results-dashboard').classList.remove('hidden');
        
        // Render Dashboard Data
        renderDashboard(result, data);
        
        // Scroll to top
        window.scrollTo(0,0);
    });

    // --- Render Functions ---
    const renderDashboard = (result, userData) => {
        // Alert Banner
        const alertBox = document.getElementById('primary-alert');
        const alertContent = document.getElementById('alert-content');
        
        alertBox.className = 'alert'; // Reset
        if(result.category === 'Emergency' || result.category === 'Very High' || result.category === 'High') {
            alertBox.classList.add('danger-alert');
            alertBox.querySelector('i').className = 'fas fa-exclamation-triangle';
        } else if (result.category === 'Moderate') {
            alertBox.classList.add('warning-alert');
            alertBox.querySelector('i').className = 'fas fa-exclamation-circle';
        } else {
            alertBox.classList.add('info-alert');
            alertBox.querySelector('i').className = 'fas fa-check-circle';
        }
        
        alertContent.innerHTML = `<strong>${result.category} Risk Category (2026 ACC/AHA Guideline)</strong><p>${result.message}</p>`;

        // Gauge Animation
        setTimeout(() => {
            document.getElementById('risk-gauge-fill').style.transform = `rotate(${result.gaugeValue}deg)`;
            let color = 'var(--success)';
            if(result.gaugeValue > 70) color = 'var(--warning)';
            if(result.gaugeValue > 120) color = 'var(--danger)';
            document.getElementById('risk-gauge-fill').style.background = color;
        }, 300);

        document.getElementById('risk-gauge-text').innerText = result.category;
        document.getElementById('risk-description').innerText = `Your profile aligns with a ${result.category.toLowerCase()} ASCVD concern pattern under 2026 guidelines.`;
        document.getElementById('analysis-type-badge').innerText = result.typeBadge;

        // Render 2026 Guideline Cards
        render2026Highlights(result);

        // Lifestyle Coach
        renderFoodSwaps(LifestyleCoach.getFoodSwaps(userData));
        renderTimeline(LifestyleCoach.getActionPlan(userData, result.category));
    };

    const render2026Highlights = (result) => {
        // PREVENT Card
        const preventDisplay = document.getElementById('prevent-risk-display');
        if (result.preventRisk) {
            preventDisplay.innerHTML = `
                <div class="stat-highlight">
                    <div><strong>10-Yr Risk:</strong> ${result.preventRisk.label10Yr}</div>
                    <div><strong>30-Yr Risk:</strong> ${result.preventRisk.label30Yr}</div>
                </div>
                <p class="text-sm mt-xs"><strong>Status:</strong> ${result.preventRisk.status}</p>
            `;
        } else {
            preventDisplay.innerHTML = `<p class="text-muted text-sm">PREVENT™ Risk applies to primary prevention adults (ages 30–79 without ASCVD).</p>`;
        }

        // Lp(a) Card
        const lpaDisplay = document.getElementById('lpa-display');
        if (result.lpaAssessment) {
            const isHigh = result.lpaAssessment.isHigh;
            lpaDisplay.innerHTML = `
                ${result.lpaAssessment.value ? `<p><strong>Measured Lp(a):</strong> ${result.lpaAssessment.value} ${result.lpaAssessment.unit}</p>` : ''}
                <p class="text-sm ${isHigh ? 'text-danger font-semibold' : ''}">${result.lpaAssessment.recommendation}</p>
            `;
        }

        // CAC Card
        const cacDisplay = document.getElementById('cac-display');
        if (result.cacRecommendation && result.cacRecommendation.recommended) {
            cacDisplay.innerHTML = `
                <p class="text-sm text-warning"><strong>Recommended (COR 1):</strong> 10-Yr ASCVD Risk ≥ 3%. CAC scoring is recommended to refine risk assessment & guide LLT decisions.</p>
            `;
        } else {
            cacDisplay.innerHTML = `<p class="text-sm text-muted">CAC scoring recommended when 10-yr risk ≥ 3% with LLT uncertainty.</p>`;
        }

        // Therapy Escalation Card
        const escDisplay = document.getElementById('escalation-display');
        if (result.therapyEscalation) {
            escDisplay.innerHTML = `
                <p class="text-sm ${result.therapyEscalation.isNotAtTarget ? 'text-danger' : 'text-success'}">
                    ${result.therapyEscalation.guidelineAdvice}
                </p>
            `;
        } else {
            escDisplay.innerHTML = `<p class="text-sm text-muted">Guide LLT based on risk level using % reduction, LDL-C (<100 mg/dL), and Non-HDL-C (<130 mg/dL) targets.</p>`;
        }
    };

    const renderLipidTable = (breakdown, unit) => {
        const tbody = document.getElementById('lipid-table-body');
        tbody.innerHTML = '';
        breakdown.forEach(b => {
            const tr = document.createElement('tr');
            let statusClass = 'status-ideal';
            if(b.status.includes('Borderline')) statusClass = 'status-borderline';
            else if(b.status.includes('High') || b.status.includes('Very High') || b.status.includes('Low')) statusClass = 'status-high';
            
            tr.innerHTML = `
                <td>${b.marker}</td>
                <td><strong>${b.value}</strong> ${unit}</td>
                <td>${b.target}</td>
                <td><span class="status-pill ${statusClass}">${b.status}</span></td>
            `;
            tbody.appendChild(tr);
        });
        
        document.getElementById('factors-list').innerHTML = '<p class="text-muted">Clinical rules derived from 2026 ACC/AHA Dyslipidemia Guidelines based on your precise blood test data.</p>';
    };

    const renderFactors = (factors) => {
        const list = document.getElementById('factors-list');
        list.innerHTML = '';
        if(!factors) return;

        // Find max for relative scaling
        const maxW = Math.max(...factors.map(f => f.weight));
        
        factors.forEach(f => {
            const pct = (f.weight / maxW) * 100;
            const el = document.createElement('div');
            el.className = 'factor-item';
            el.innerHTML = `
                <div class="factor-name"><i class="fas ${f.icon}"></i> ${f.name}</div>
                <div class="factor-weight"><div class="weight-fill" style="width: ${pct}%"></div></div>
            `;
            list.appendChild(el);
        });
    };

    const renderFoodSwaps = (swaps) => {
        const container = document.getElementById('swaps-container');
        container.innerHTML = '';
        swaps.forEach(s => {
            const card = document.createElement('div');
            card.className = 'swap-card';
            card.innerHTML = `
                <div class="swap-title"><i class="fas fa-exchange-alt text-muted"></i> Swap Suggestion</div>
                <div class="swap-from">${s.from}</div>
                <div class="swap-to">${s.to}</div>
                <div class="swap-desc">${s.desc}</div>
            `;
            container.appendChild(card);
        });
    };

    const renderTimeline = (plan) => {
        const tl = document.getElementById('plan-timeline');
        tl.innerHTML = '';
        plan.forEach(day => {
            const li = document.createElement('li');
            li.innerHTML = `
                <div class="time-title">${day.title}</div>
                <div class="time-desc">${day.desc}</div>
            `;
            tl.appendChild(li);
        });
    };

    // --- Tabs & Retake ---
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById(btn.getAttribute('data-tab')).classList.add('active');
        });
    });

    document.getElementById('retake-btn').addEventListener('click', () => {
        document.getElementById('results-dashboard').classList.add('hidden');
        document.getElementById('assessment-form').classList.remove('hidden');
        document.getElementById('progress-container').classList.remove('hidden');
        form.reset();
        bmiDisplay.innerText = '--';
        bmiCategory.innerText = 'Enter height & weight';
        currentStep = 1;
        showStep(1);
        window.scrollTo(0,0);
    });
});
