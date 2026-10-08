const FieldLocks = {
    init() {
        $(document).on('input change', '.form-group :input', function () {
            const input = $(this);
            if (input.is('.field-lock, .auto-lock-ignore, .destroy-attribute')) return;

            const group = input.closest('.form-group');
            const lockGroup = group.find('input[type=checkbox].field-lock').length
                ? group
                : group.parents('.form-group').has('input[type=checkbox].field-lock').first();
            const lockCheckbox = lockGroup.find('input[type=checkbox].field-lock').first();
            if (!lockCheckbox.length || !lockCheckbox.data('autolock')) return;

            if (FieldLocks.hasNonEmptyValue(this)) {
                lockCheckbox.prop('checked', true);
            }
        });
    },

    hasNonEmptyValue(input) {
        const element = $(input);
        const type = (element.attr('type') || '').toLowerCase();

        if (type === 'file') {
            return !!(input.files && input.files.length);
        }

        if (type === 'radio') {
            return element.is(':checked');
        }

        if (type === 'checkbox') {
            return true; // can't distinguish between no value and unchecked checkbox
        }

        return $.trim(element.val() || '').length > 0;
    }
};

FieldLocks.init();
