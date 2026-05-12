

$(document).ready(function () {

    // ─── CONFIG ───────────────────────────────────────────────────
    const FETCH_PENDING_URL = '../../php/fetch_pending.php';

    // ─── STATE ────────────────────────────────────────────────────
    // Cache the full pending dataset so the View button can access
    // any row's complete data without a second network request.
    let pendingProviders = [];

    // ─── INIT ─────────────────────────────────────────────────────
    fetchPendingProviders();

    // ══════════════════════════════════════════════════════════════
    //  1.  FETCH & RENDER PENDING TABLE
    // ══════════════════════════════════════════════════════════════

    function fetchPendingProviders() {
        showTableSkeleton('#pendingTableBody', 7);

        $.ajax({
            url:      FETCH_PENDING_URL,
            method:   'GET',
            dataType: 'json',

            success: function (response) {
                if (response.status !== 'success') {
                    showTableError(
                        '#pendingTableBody', 7,
                        'Server returned an error. Please try again.'
                    );
                    return;
                }

                pendingProviders = response.data;

                // Update stat card + tab badge
                $('#statPending').text(response.count);
                $('#pendingBadge').text(response.count);

                if (pendingProviders.length === 0) {
                    showTableEmpty(
                        '#pendingTableBody', 7,
                        'bi-inbox',
                        'No pending requests at the moment.'
                    );
                    return;
                }

                renderPendingTable(pendingProviders);
            },

            error: function (xhr) {
                showTableError(
                    '#pendingTableBody', 7,
                    'Could not reach the server. Check your connection.'
                );
                console.error('fetch_pending.php error:', xhr);
            }
        });
    }

    function renderPendingTable(providers) {
        const $tbody = $('#pendingTableBody');
        $tbody.empty();

        providers.forEach(function (sp, index) {
            const dateSubmitted = sp.date_submitted
                ? formatDate(sp.date_submitted)
                : '—';

            const idStatus = sp.national_id_front
                ? '<span class="id-badge verified"><i class="bi bi-check-circle-fill me-1"></i>Attached</span>'
                : '<span class="id-badge missing"><i class="bi bi-x-circle-fill me-1"></i>Missing</span>';

            const $row = $(`
                <tr data-provider-id="${sp.provider_id}">
                    <td class="row-num">${index + 1}</td>
                    <td class="fw-600">${escHtml(sp.full_name)}</td>
                    <td>
                        <span class="trade-pill">${escHtml(sp.trade ?? '—')}</span>
                    </td>
                    <td>${escHtml(sp.barangay ?? '—')}</td>
                    <td>${dateSubmitted}</td>
                    <td>${idStatus}</td>
                    <td class="text-center">
                        <div class="action-group">
                            <button class="btn-view js-view-btn"
                                    data-provider-id="${sp.provider_id}"
                                    title="View full details">
                                <i class="bi bi-eye-fill me-1"></i>View
                            </button>
                            <button class="btn-approve js-approve-btn"
                                    data-provider-id="${sp.provider_id}"
                                    title="Approve this provider"
                                    disabled>
                                <i class="bi bi-patch-check-fill me-1"></i>Approve
                            </button>
                            <button class="btn-reject js-reject-btn"
                                    data-provider-id="${sp.provider_id}"
                                    title="Reject this provider"
                                    disabled>
                                <i class="bi bi-x-octagon-fill me-1"></i>Reject
                            </button>
                        </div>
                    </td>
                </tr>
            `);

            $tbody.append($row);
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  2.  SEARCH & FILTER (client-side, no extra request needed)
    // ══════════════════════════════════════════════════════════════

    function applyPendingFilters() {
        const query = $('#pendingSearch').val().toLowerCase().trim();
        const trade = $('#pendingTradeFilter').val().toLowerCase();

        const filtered = pendingProviders.filter(function (sp) {
            const nameMatch = sp.full_name.toLowerCase().includes(query);
            const tradeMatch = trade === '' || (sp.trade ?? '').toLowerCase() === trade;
            return nameMatch && tradeMatch;
        });

        if (filtered.length === 0) {
            showTableEmpty(
                '#pendingTableBody', 7,
                'bi-funnel',
                'No results match your search or filter.'
            );
        } else {
            renderPendingTable(filtered);
        }
    }

    $('#pendingSearch').on('input', applyPendingFilters);
    $('#pendingTradeFilter').on('change', applyPendingFilters);

    // ══════════════════════════════════════════════════════════════
    //  3.  "VIEW" BUTTON → POPULATE & OPEN MODAL
    // ══════════════════════════════════════════════════════════════

    // Delegated event — works even after table rows are re-rendered
    $('#pendingTableBody').on('click', '.js-view-btn', function () {
        const providerId = $(this).data('provider-id');

        // Find the matching record in our cached array
        const sp = pendingProviders.find(function (p) {
            return p.provider_id == providerId;
        });

        if (!sp) {
            console.warn('Provider not found in cache for id:', providerId);
            return;
        }

        populateModal(sp);

        const modal = new bootstrap.Modal(document.getElementById('spDetailsModal'));
        modal.show();
    });

    // ─── POPULATE MODAL ───────────────────────────────────────────

    function populateModal(sp) {

        // ── Modal subtitle (name + trade) ──────────────────────────
        $('#spDetailsModalLabel').html(
            '<i class="bi bi-person-badge-fill me-2"></i>' +
            escHtml(sp.full_name)
        );
        $('#modalSubtitle').text(
            (sp.trade ?? 'Service Provider') + ' · Applicant Review'
        );

        // ── Personal Information grid ──────────────────────────────
        const personalFields = [
            { label: 'Full Name',           value: sp.full_name },
            { label: 'Contact Number',      value: sp.contact_number },
            { label: 'Email',               value: sp.email },
            { label: 'Date of Birth',       value: sp.date_of_birth
                                                    ? formatDate(sp.date_of_birth)
                                                    : null },
            { label: 'Age',                 value: sp.age },
            { label: 'Sex',                 value: sp.sex },
            { label: 'Civil Status',        value: sp.civil_status },
            { label: 'Employment Status',   value: sp.employment_status },
            { label: 'Present Address',     value: sp.present_address },
            { label: 'Permanent Address',   value: sp.permanent_address },
            { label: "Father's Name",       value: sp.fathers_name },
            { label: "Father's Contact",    value: sp.fathers_contact },
            { label: "Mother's Name",       value: sp.mothers_name },
            { label: "Mother's Contact",    value: sp.mothers_contact },
        ];

        renderInfoGrid('#modalPersonalInfo', personalFields);

        // ── Professional Profile grid ──────────────────────────────
        const professionalFields = [
            { label: 'Trade / Skill',       value: sp.trade },
            { label: 'Barangay',            value: sp.barangay },
            { label: 'Years of Experience', value: sp.years_experience
                                                    ? sp.years_experience + ' yr(s)'
                                                    : null },
            { label: 'Job Preference',      value: sp.job_preference },
            { label: 'Other Skills',        value: sp.skills },
            { label: 'Highest Education',   value: sp.highest_education },
            { label: 'Last Employer',       value: sp.last_employer },
            { label: 'Bio / Summary',       value: sp.bio },
            { label: 'Date Submitted',      value: sp.date_submitted
                                                    ? formatDate(sp.date_submitted)
                                                    : null },
        ];

        renderInfoGrid('#modalProfessionalInfo', professionalFields);

        // ── Document Previews ──────────────────────────────────────
        renderDocSlot('#docNationalIdFront', sp.national_id_front, 'National ID — Front');
        renderDocSlot('#docNationalIdBack',  sp.national_id_back,  'National ID — Back');
        renderDocSlot('#docNSRP',            sp.nsrp_form,         'DOLE Registration Form');

        // ── Wire modal action buttons with this provider's ID ──────
        // (Approve/Reject logic will be added in Step 3 — IDs stored as data attrs)
        $('#modalApproveBtn').data('provider-id', sp.provider_id);
        $('#modalRejectBtn').data('provider-id',  sp.provider_id);
    }

    // ─── HELPERS ──────────────────────────────────────────────────

    /**
     * Renders an array of {label, value} objects into a target grid element.
     * Skips rows where value is null/undefined/empty.
     */
    function renderInfoGrid(selector, fields) {
        const $grid = $(selector);
        $grid.empty();

        let hasContent = false;

        fields.forEach(function (field) {
            const val = field.value;
            if (val === null || val === undefined || String(val).trim() === '') return;

            hasContent = true;
            $grid.append(`
                <div class="info-row">
                    <span>${escHtml(field.label)}</span>
                    <span>${escHtml(String(val))}</span>
                </div>
            `);
        });

        if (!hasContent) {
            $grid.append(`
                <div class="info-row placeholder-row-modal">
                    <span class="text-muted">No data on record.</span>
                </div>
            `);
        }
    }

    /**
     * Renders a document preview slot.
     * Shows an <img> tag if a path exists, otherwise a "Not uploaded" placeholder.
     */
    function renderDocSlot(selector, filePath, altText) {
        const $slot = $(selector);
        $slot.empty();

        if (filePath) {
            $slot.html(`
                <img src="${escHtml(filePath)}"
                     alt="${escHtml(altText)}"
                     class="doc-img"
                     onerror="this.replaceWith(missingDocPlaceholder('File could not load.'))"
                >
            `);
        } else {
            $slot.html(`
                <i class="bi bi-file-earmark-x text-muted fs-3"></i>
                <span class="text-muted small">Not uploaded</span>
            `);
        }
    }

    /**
     * Returns a DOM element to swap in when an image fails to load.
     * Used in the onerror handler above.
     */
    window.missingDocPlaceholder = function (msg) {
        const div = document.createElement('div');
        div.className = 'doc-missing-inline';
        div.innerHTML = `<i class="bi bi-exclamation-triangle-fill"></i><span>${msg}</span>`;
        return div;
    };

    // ── TABLE STATE HELPERS ────────────────────────────────────────

    function showTableSkeleton(tbodySelector, cols) {
        const $tbody = $(tbodySelector);
        $tbody.empty();
        for (let i = 0; i < 5; i++) {
            let tds = '';
            for (let j = 0; j < cols; j++) {
                tds += `<td><div class="skeleton-cell"></div></td>`;
            }
            $tbody.append(`<tr class="skeleton-row">${tds}</tr>`);
        }
    }

    function showTableEmpty(tbodySelector, cols, icon, message) {
        $(tbodySelector).html(`
            <tr class="placeholder-row">
                <td colspan="${cols}" class="text-center py-5">
                    <i class="bi ${icon} fs-2 d-block mb-2 text-muted"></i>
                    <span class="text-muted">${message}</span>
                </td>
            </tr>
        `);
    }

    function showTableError(tbodySelector, cols, message) {
        $(tbodySelector).html(`
            <tr class="placeholder-row">
                <td colspan="${cols}" class="text-center py-5">
                    <i class="bi bi-exclamation-triangle-fill fs-2 d-block mb-2 text-danger"></i>
                    <span class="text-danger fw-600">${message}</span>
                </td>
            </tr>
        `);
    }

    // ── UTILITIES ──────────────────────────────────────────────────

    function escHtml(str) {
        if (str == null) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function formatDate(dateStr) {
        if (!dateStr) return '—';
        const d = new Date(dateStr);
        if (isNaN(d)) return dateStr;
        return d.toLocaleDateString('en-PH', {
            year:  'numeric',
            month: 'long',
            day:   'numeric'
        });
    }

});