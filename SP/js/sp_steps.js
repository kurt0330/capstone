/**
 * sp_steps.js  —  CommuniServe SP Registration Step Logic
 * ---------------------------------------------------------
 * Loaded AFTER form1.js (jQuery address-sync) so both run
 * independently without conflict.
 *
 * Exposes one global object: SP
 *   SP.go(n)              — navigate to step n
 *   SP.toggleStatus(type) — show/hide employed/unemployed sub-panels
 *   SP.toggleSelfSpec(el) — show/hide self-employed spec options
 *   SP.fileChosen(...)    — handle file upload feedback
 *   SP.submit()           — final submission handler
 */

/* ════════════════════════════════════════════════════════════════
   STATE
════════════════════════════════════════════════════════════════ */
const SP = (function () {

    let current = 1;
    const TOTAL  = 5;

    /* ─── helpers ─── */

    function show(id)  { const el = document.getElementById(id); if (el) el.style.display = 'block'; }
    function hide(id)  { const el = document.getElementById(id); if (el) el.style.display = 'none';  }
    function get(id)   { return document.getElementById(id); }
    function val(id)   { const el = get(id); return el ? el.value.trim() : ''; }
    function radio(nm) { const el = document.querySelector(`input[name="${nm}"]:checked`); return el ? el.value : ''; }


    /* ════════════════════════════════════════════════════════════
       NAVIGATION  — SP.go(targetStep)
    ════════════════════════════════════════════════════════════ */
    function go(target) {

        // Forward movement requires current step to be valid
        if (target > current && !validate(current)) return;

        // Hide current panel
        const prev = get('step-' + current);
        if (prev) prev.style.display = 'none';

        // Show target panel
        const next = get('step-' + target);
        if (next) {
            next.style.display = 'block';
            // Re-trigger the CSS animation
            next.classList.remove('step-panel');
            void next.offsetWidth;          // reflow
            next.classList.add('step-panel');
            next.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        // Update progress bar
        document.querySelectorAll('.nav-btn[data-step]').forEach(btn => {
            const s = parseInt(btn.getAttribute('data-step'));
            btn.classList.remove('active', 'done');
            if (s === target) btn.classList.add('active');
            if (s < target)  btn.classList.add('done');
        });

        // Update circle number
        const circle = get('stepCircle');
        if (circle) {
            circle.textContent = target;
            // Micro-bounce
            circle.style.transform = 'scale(1.18)';
            setTimeout(() => { circle.style.transform = 'scale(1)'; }, 220);
        }

        current = target;
    }


    /* ════════════════════════════════════════════════════════════
       VALIDATION — returns true if step is complete
    ════════════════════════════════════════════════════════════ */
    function validate(step) {

        clearErrors();

        if (step === 1) {
            let ok = true;

            // Required text fields
            const required = ['last_name','first_name','date_of_birth',
                              'pres_barangay','pres_city','pres_province','email'];
            required.forEach(id => {
                if (!val(id)) { markInvalid(id); ok = false; }
            });

            // Sex radio
            if (!radio('sex')) {
                toast('Please select your sex.'); ok = false;
            }

            // Civil status radio
            if (!radio('civil_status')) {
                toast('Please select your civil status.'); ok = false;
            }

            // Email format
            const em = val('email');
            if (em && !/\S+@\S+\.\S+/.test(em)) {
                markInvalid('email'); toast('Please enter a valid email address.'); ok = false;
            }

            if (!ok) toast('Please complete all required fields before continuing.');
            return ok;
        }

        if (step === 2) {
            if (!radio('employment_status')) {
                toast('Please select your employment status.'); return false;
            }
            return true;
        }

        if (step === 3) {
            if (!radio('trade_category')) {
                toast('Please select a trade / service category.'); return false;
            }
            return true;
        }

        // Step 4 (assessment placeholder) — always passthrough
        if (step === 4) return true;

        if (step === 5) {
            let ok = true;
            const nid   = get('file_national_id') || document.querySelector('[name="file_national_id"]');
            const photo = get('file_photo')        || document.querySelector('[name="file_photo"]');
            const terms = get('terms_agreed');

            if (!nid   || !nid.files.length)   { toast('Please upload your National ID.'); ok = false; }
            if (!photo || !photo.files.length)  { toast('Please upload your 2×2 photo.');  ok = false; }
            if (!terms || !terms.checked)        { toast('Please check the certification checkbox.'); ok = false; }
            return ok;
        }

        return true;
    }

    /* Mark an input as visually invalid */
    function markInvalid(id) {
        const el = get(id);
        if (!el) return;
        el.classList.add('field-invalid');
        el.addEventListener('input', function clear() {
            el.classList.remove('field-invalid');
            el.removeEventListener('input', clear);
        }, { once: true });
    }

    /* Remove all error marks */
    function clearErrors() {
        document.querySelectorAll('.field-invalid, .select-invalid').forEach(el => {
            el.classList.remove('field-invalid', 'select-invalid');
        });
        const old = get('sp-toast-el');
        if (old) old.remove();
    }

    /* Brief top toast message */
    function toast(msg) {
        // Only show one at a time
        const existing = get('sp-toast-el');
        if (existing) existing.remove();

        const el = document.createElement('div');
        el.id = 'sp-toast-el';
        el.className = 'sp-toast';
        el.textContent = '⚠ ' + msg;
        document.body.appendChild(el);
        setTimeout(() => { if (el.parentElement) el.remove(); }, 3400);
    }


    /* ════════════════════════════════════════════════════════════
       STEP 2 — EMPLOYMENT STATUS TOGGLE
    ════════════════════════════════════════════════════════════ */
    function toggleStatus(type) {
        const empSub  = get('employed_sub');
        const unempSub = get('unemployed_sub');

        if (type === 'employed') {
            if (empSub)   empSub.style.display   = 'block';
            if (unempSub) unempSub.style.display  = 'none';
            // Reset unemployed radios
            document.querySelectorAll('input[name="unemployment_reason"]')
                    .forEach(r => r.checked = false);
        } else {
            if (unempSub) unempSub.style.display  = 'block';
            if (empSub)   empSub.style.display    = 'none';
            // Reset employed radios
            document.querySelectorAll('input[name="employment_type"]')
                    .forEach(r => r.checked = false);
            document.querySelectorAll('input[name="self_employed_spec"]')
                    .forEach(r => r.checked = false);
            const specWrap = get('self_spec_wrap');
            if (specWrap) specWrap.style.display = 'none';
        }
    }

    /* Show self-employed specialization when "Self Employed" is picked */
    function toggleSelfSpec(radio) {
        const wrap = get('self_spec_wrap');
        if (!wrap) return;
        wrap.style.display = (radio && radio.checked) ? 'block' : 'none';
        if (!radio || !radio.checked) {
            document.querySelectorAll('input[name="self_employed_spec"]')
                    .forEach(r => r.checked = false);
        }
    }

    // Also catch "Wage Employed" to hide spec wrap
    document.addEventListener('change', function(e) {
        if (e.target.name === 'employment_type' && e.target.value === 'Wage Employed') {
            const wrap = get('self_spec_wrap');
            if (wrap) wrap.style.display = 'none';
            document.querySelectorAll('input[name="self_employed_spec"]')
                    .forEach(r => r.checked = false);
        }
    });


    /* ════════════════════════════════════════════════════════════
       STEP 1 — AUTO-COMPUTE AGE FROM DATE OF BIRTH
    ════════════════════════════════════════════════════════════ */
    function initAgeCompute() {
        const dob = get('date_of_birth');
        const age = get('age');
        if (!dob || !age) return;

        dob.addEventListener('change', function () {
            const d = new Date(this.value);
            if (isNaN(d.getTime())) { age.value = ''; return; }
            const today = new Date();
            let yr = today.getFullYear() - d.getFullYear();
            const m = today.getMonth() - d.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < d.getDate())) yr--;
            age.value = yr >= 0 ? yr : '';
        });
    }


    /* ════════════════════════════════════════════════════════════
       STEP 5 — FILE CHOSEN FEEDBACK
       fileChosen(inputEl, previewId, zoneId)
    ════════════════════════════════════════════════════════════ */
    function fileChosen(input, previewId, zoneId) {
        const prev = get(previewId);
        const zone = get(zoneId);
        if (!prev) return;

        const file = input.files[0];
        if (!file) { prev.textContent = ''; return; }

        // 5 MB guard
        if (file.size > 5 * 1024 * 1024) {
            prev.style.color = '#E24B4A';
            prev.textContent = '✗ File too large (max 5 MB)';
            input.value = '';
            if (zone) zone.classList.remove('file-ok');
            return;
        }

        prev.style.color = '#1D9E75';
        prev.textContent  = '✓ ' + file.name + ' (' + (file.size / 1024).toFixed(0) + ' KB)';
        if (zone) zone.classList.add('file-ok');

        // Thumbnail for images
        if (file.type.startsWith('image/')) {
            const reader = new FileReader();
            reader.onload = ev => {
                prev.innerHTML = `<img src="${ev.target.result}"
                    style="max-height:54px;max-width:100%;border-radius:5px;
                           margin-top:4px;border:1px solid #ccc;">`;
            };
            reader.readAsDataURL(file);
        }
    }


    /* ════════════════════════════════════════════════════════════
       SUBMIT — SP.submit()
    ════════════════════════════════════════════════════════════ */
    function submit() {
        if (!validate(5)) return;

        const btn = get('btnSubmit');
        if (btn) { btn.disabled = true; btn.textContent = 'Submitting…'; }

        // In production replace with fetch('/your-php-endpoint', { method:'POST', body: buildFormData() })
        console.log('SP Registration payload:', collectData());

        setTimeout(() => {
            // Hide form controls
            ['btnSubmit'].forEach(id => { const el = get(id); if (el) el.style.display = 'none'; });
            const navRow = document.querySelector('#step-5 .nav-row');
            if (navRow) navRow.style.display = 'none';
            document.querySelectorAll('#step-5 .upload-grid, #step-5 .terms-block, #step-5 .step-intro-text')
                    .forEach(el => el.style.display = 'none');

            // Show success
            const ok = get('submitSuccess');
            if (ok) {
                ok.style.display = 'block';
                ok.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }

            // Mark all bar buttons done
            document.querySelectorAll('.nav-btn[data-step]').forEach(b => {
                b.classList.remove('active');
                b.classList.add('done');
            });
            const circle = get('stepCircle');
            if (circle) circle.textContent = '✓';

        }, 900);
    }


    /* Collect all named fields for submission */
    function collectData() {
        const data = {};

        // Text / number / email / tel / date inputs
        document.querySelectorAll('input[name]:not([type="file"]):not([type="radio"]):not([type="checkbox"])')
                .forEach(el => { if (el.name) data[el.name] = el.value; });

        // Radios — only checked
        document.querySelectorAll('input[type="radio"]:checked')
                .forEach(el => { data[el.name] = el.value; });

        // Checkboxes — 1 if checked, 0 if not
        ['is_4ps_beneficiary','is_indigent','is_pwd',
         'is_senior_citizen','is_solo_parent','terms_agreed'].forEach(nm => {
            const el = get(nm);
            data[nm] = el && el.checked ? 1 : 0;
        });

        // Textarea
        const hist = get('employment_history');
        if (hist) data['employment_history'] = hist.value;

        // Select
        const edu = get('highest_education');
        if (edu) data['highest_education'] = edu.value;

        return data;
    }


    /* ════════════════════════════════════════════════════════════
       INIT — run once DOM is ready
    ════════════════════════════════════════════════════════════ */
    function init() {
        // Ensure step 1 is visible (in case CSS shows all by default)
        for (let i = 2; i <= TOTAL; i++) hide('step-' + i);
        show('step-1');

        initAgeCompute();

        // Accent all checkboxes/radios with brand blue
        document.querySelectorAll('input[type="radio"], input[type="checkbox"]')
                .forEach(el => { el.style.accentColor = '#0504AA'; });
    }

    // Run after DOM is fully parsed
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    /* Public API */
    return { go, toggleStatus, toggleSelfSpec, fileChosen, submit };

}());