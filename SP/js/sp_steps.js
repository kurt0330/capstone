/**
 * sp_steps.js  (Phase 1 Update)
 * CommuniServe SP Registration — Full Step Logic + Backend Submit
 * ─────────────────────────────────────────────────────────────────
 * CHANGE FROM PREVIOUS VERSION:
 *   SP.submit() now sends a real fetch() POST to register_sp.php
 *   using FormData so file uploads (National ID, Photo) work correctly.
 *
 * LOCATION : /SP/js/sp_steps.js
 * LOADED   : after form1.js (address-sync, jQuery)
 * ─────────────────────────────────────────────────────────────────
 */

const SP = (function () {

    /* ── state ── */
    let current = 1;
    const TOTAL = 5;

    /* ── tiny helpers ── */
    const get   = id  => document.getElementById(id);
    const show  = id  => { const e = get(id); if (e) e.style.display = 'block'; };
    const hide  = id  => { const e = get(id); if (e) e.style.display = 'none';  };
    const val   = id  => { const e = get(id); return e ? e.value.trim() : ''; };
    const radio = nm  => { const e = document.querySelector(`input[name="${nm}"]:checked`); return e ? e.value : ''; };


    /* ════════════════════════════════════════════════════════════
       NAVIGATION  —  SP.go(n)
    ════════════════════════════════════════════════════════════ */
    function go(target) {
        if (target > current && !validate(current)) return;

        // Swap panels
        hide('step-' + current);
        const next = get('step-' + target);
        if (next) {
            next.style.display = 'block';
            // Restart CSS animation
            next.classList.remove('step-panel');
            void next.offsetWidth;
            next.classList.add('step-panel');
            next.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        // Update progress bar
        document.querySelectorAll('.nav-btn[data-step]').forEach(btn => {
            const s = parseInt(btn.dataset.step, 10);
            btn.classList.remove('active', 'done');
            if (s === target) btn.classList.add('active');
            if (s < target)  btn.classList.add('done');
        });

        // Bounce the circle number
        const circle = get('stepCircle');
        if (circle) {
            circle.textContent = target;
            circle.style.transform = 'scale(1.18)';
            setTimeout(() => { circle.style.transform = 'scale(1)'; }, 220);
        }

        current = target;
    }


    /* ════════════════════════════════════════════════════════════
       VALIDATION  —  validate(step)
       Returns true if all required fields for the step are filled.
    ════════════════════════════════════════════════════════════ */
    function validate(step) {
        clearErrors();
        let ok = true;

        if (step === 1) {
            ['last_name', 'first_name', 'date_of_birth',
             'pres_barangay', 'pres_city', 'pres_province', 'email']
                .forEach(id => { if (!val(id)) { markInvalid(id); ok = false; } });

            if (!radio('sex'))         { toast('Please select your sex.');         ok = false; }
            if (!radio('civil_status')){ toast('Please select your civil status.'); ok = false; }

            const em = val('email');
            if (em && !/\S+@\S+\.\S+/.test(em)) {
                markInvalid('email');
                toast('Please enter a valid email address.');
                ok = false;
            }
            if (!ok) toast('Please complete all required fields before continuing.');
        }

        if (step === 2) {
            if (!radio('employment_status')) {
                toast('Please select your employment status.'); ok = false;
            }
        }

        if (step === 3) {
            if (!radio('trade_category')) {
                toast('Please select a trade / service category.'); ok = false;
            }
        }

        // Step 4 (assessment placeholder) — always pass
        if (step === 4) return true;

        if (step === 5) {
            const nid     = document.querySelector('[name="file_national_id"]');
            const nidBack = document.querySelector('[name="file_national_id_back"]'); // New check
            const photo   = document.querySelector('[name="file_photo"]');
            // Note: ensure your HTML checkbox ID is 'certify' or whatever matches your form
            const terms   = document.querySelector('input[type="checkbox"]:checked'); 

            if (!nid || !nid.files.length) { toast('Please upload National ID (Front).'); ok = false; }
            if (!nidBack || !nidBack.files.length) { toast('Please upload National ID (Back).'); ok = false; }
            if (!photo || !photo.files.length) { toast('Please upload your 2×2 photo.'); ok = false; }
            if (!terms) { toast('Please accept the certification checkbox.'); ok = false; }
        }

        return ok;
    }

    /* Mark a single input as invalid (red underline) */
    function markInvalid(id) {
        const el = get(id);
        if (!el) return;
        el.classList.add('field-invalid');
        el.addEventListener('input', function clr() {
            el.classList.remove('field-invalid');
            el.removeEventListener('input', clr);
        }, { once: true });
    }

    /* Remove all error marks */
    function clearErrors() {
        document.querySelectorAll('.field-invalid').forEach(e => e.classList.remove('field-invalid'));
        const t = get('sp-toast-el');
        if (t) t.remove();
    }

    /* Brief dismissing toast at top of viewport */
    function toast(msg) {
        const old = get('sp-toast-el');
        if (old) old.remove();
        const el = document.createElement('div');
        el.id = 'sp-toast-el';
        el.className = 'sp-toast';
        el.textContent = '⚠ ' + msg;
        document.body.appendChild(el);
        setTimeout(() => { if (el.parentNode) el.remove(); }, 3500);
    }


    /* ════════════════════════════════════════════════════════════
       STEP 2 — EMPLOYMENT TOGGLES
    ════════════════════════════════════════════════════════════ */
    function toggleStatus(type) {
        const emp   = get('employed_sub');
        const unemp = get('unemployed_sub');
        if (type === 'employed') {
            if (emp)   emp.style.display   = 'block';
            if (unemp) unemp.style.display = 'none';
            document.querySelectorAll('[name="unemployment_reason"]').forEach(r => r.checked = false);
        } else {
            if (unemp) unemp.style.display = 'block';
            if (emp)   emp.style.display   = 'none';
            document.querySelectorAll('[name="employment_type"], [name="self_employed_spec"]')
                     .forEach(r => r.checked = false);
            const sw = get('self_spec_wrap');
            if (sw) sw.style.display = 'none';
        }
    }

    function toggleSelfSpec(radioEl) {
        const wrap = get('self_spec_wrap');
        if (!wrap) return;
        wrap.style.display = radioEl && radioEl.checked ? 'block' : 'none';
        if (!radioEl || !radioEl.checked) {
            document.querySelectorAll('[name="self_employed_spec"]').forEach(r => r.checked = false);
        }
    }

    // Wage Employed → hide spec wrap
    document.addEventListener('change', e => {
        if (e.target.name === 'employment_type' && e.target.value === 'Wage Employed') {
            const wrap = get('self_spec_wrap');
            if (wrap) wrap.style.display = 'none';
            document.querySelectorAll('[name="self_employed_spec"]').forEach(r => r.checked = false);
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
    ════════════════════════════════════════════════════════════ */
    function fileChosen(input, previewId, zoneId) {
        const prev = get(previewId);
        const zone = get(zoneId);
        if (!prev) return;

        const file = input.files[0];
        if (!file) { prev.textContent = ''; return; }

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

        // Image thumbnail
        if (file.type.startsWith('image/')) {
            const reader = new FileReader();
            reader.onload = ev => {
                prev.innerHTML = `<img src="${ev.target.result}"
                    style="max-height:52px;max-width:100%;border-radius:4px;
                           margin-top:4px;border:1px solid #ccc;">`;
            };
            reader.readAsDataURL(file);
        }
    }


    /* ════════════════════════════════════════════════════════════
       SUBMIT  —  SP.submit()
       Builds FormData from the entire form and POSTs to register_sp.php.
       Uses fetch() so multipart file uploads work correctly.
    ════════════════════════════════════════════════════════════ */
    function submit() {
        if (!validate(5)) return;

        const btn = get('btnSubmit');
        if (btn) { btn.disabled = true; btn.textContent = 'Submitting…'; }

        // ── Build FormData (handles both text fields and files) ──
        const fd = new FormData();

        // ── Step 1: Personal Info ──────────────────────────────
        const textFields = [
            'last_name','first_name','middle_name','suffix',
            'date_of_birth','age','contact_number','email',
            'pres_street','pres_barangay','pres_city','pres_province',
            'perm_street','perm_barangay','perm_city','perm_province',
            'father_name','father_contact','mother_name','mother_contact'
        ];
        textFields.forEach(id => {
            const el = get(id);
            if (el) fd.append(id, el.value);
        });

        // Radios
        ['sex','civil_status','parents_civil_status',
         'employment_status','employment_type',
         'unemployment_reason','self_employed_spec',
         'trade_category']
            .forEach(nm => {
                const el = document.querySelector(`input[name="${nm}"]:checked`);
                if (el) fd.append(nm, el.value);
            });

        // Address-sync checkbox
        const sameChk = get('same_as_permanent');
        if (sameChk) fd.append('same_as_permanent', sameChk.checked ? '1' : '0');

        // Socio-economic checkboxes
        ['is_4ps_beneficiary','is_indigent','is_pwd',
         'is_senior_citizen','is_solo_parent'].forEach(nm => {
            const el = get(nm);
            fd.append(nm, el && el.checked ? '1' : '0');
        });

        // ── Step 2: Professional Profile ──────────────────────
        ['highest_education','school_last_attended',
         'course_completed','year_graduated'].forEach(id => {
            const el = get(id);
            if (el) fd.append(id, el.value);
        });
        const hist = get('employment_history');
        if (hist) fd.append('employment_history', hist.value);

        // ── Step 5: File uploads ───────────────────────────────
        ['file_national_id', 'file_national_id_back', 'file_photo', 'file_certificate'].forEach(nm => {
            const el = document.querySelector(`[name="${nm}"]`);
            if (el && el.files[0]) {
                fd.append(nm, el.files[0]);
            }
        });

        // ── POST to PHP backend ────────────────────────────────
        // Path from /SP/html/form1.html → ../../php/register_sp.php
        fetch('../../php/register_sp.php', {
            method: 'POST',
            body:   fd,
            // Do NOT set Content-Type header — browser sets multipart boundary automatically
        })
        .then(res => {
            if (!res.ok && res.status !== 422 && res.status !== 409) {
                // Non-validation server error
                throw new Error('Server returned status ' + res.status);
            }
            return res.json();
        })
        .then(data => {
            if (btn) { btn.disabled = false; btn.textContent = 'Submit Registration ✓'; }

            if (data.success) {
                // ── Show success state ─────────────────────────
                ['btnSubmit'].forEach(id => { const e = get(id); if (e) e.style.display = 'none'; });
                const navRow = document.querySelector('#step-5 .nav-row');
                if (navRow) navRow.style.display = 'none';
                document.querySelectorAll(
                    '#step-5 .upload-grid, #step-5 .terms-block, #step-5 .step-intro-text'
                ).forEach(el => el.style.display = 'none');

                const ok = get('submitSuccess');
                if (ok) {
                    ok.style.display = 'block';
                    ok.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }

                // Mark all nav buttons done
                document.querySelectorAll('.nav-btn[data-step]').forEach(b => {
                    b.classList.remove('active');
                    b.classList.add('done');
                });
                const circle = get('stepCircle');
                if (circle) circle.textContent = '✓';

            } else {
                // ── Show validation/server errors ──────────────
                const msgs = data.errors || [data.error] || ['An unknown error occurred.'];
                toast(msgs[0]);

                // Highlight known invalid fields
                if (data.errors) {
                    data.errors.forEach(msg => {
                        // Try to match error message to a field ID
                        const m = msg.match(/^(\w+) is required/i);
                        if (m) markInvalid(m[1].toLowerCase());
                    });
                }
            }
        })
        .catch(err => {
            if (btn) { btn.disabled = false; btn.textContent = 'Submit Registration ✓'; }
            console.error('[CommuniServe] Submit error:', err);
            toast('Submission failed. Please check your connection and try again.');
        });
    }


    /* ════════════════════════════════════════════════════════════
       INIT
    ════════════════════════════════════════════════════════════ */
    function init() {
        for (let i = 2; i <= TOTAL; i++) hide('step-' + i);
        show('step-1');
        initAgeCompute();
        document.querySelectorAll('input[type="radio"], input[type="checkbox"]')
                .forEach(el => { el.style.accentColor = '#0504AA'; });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    /* Public API */
    return { go, toggleStatus, toggleSelfSpec, fileChosen, submit };

}());