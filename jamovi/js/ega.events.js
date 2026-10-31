// -----------------------------------------------------------------------------
// EGAnetLab
// A jamovi module for Exploratory Graph Analysis and evidence-based
// methodological decision support on dimensional structure.
//
// Copyright (C) 2026 Arquímedes De León Chacón Chacón
//
// This file is part of EGAnetLab, licensed under the GNU General Public
// License, version 3 or later. See https://www.gnu.org/licenses/.
// -----------------------------------------------------------------------------

// Theoretical structure: give every factor a default name ("Factor 2", ...)
// when the user adds it, as jamovi's own CFA does.
// ES: Estructura teórica: da a cada factor un nombre por defecto ("Factor 2",
// ...) cuando el usuario lo agrega, como hace el CFA de jamovi.

const events = {

    onFactorsChanged: function(ui) {
        ui.theoryFactors.applyToItems(0, (item, index) => {
            let value = item.controls[0].value();
            if ( ! value || value.trim() === '')
                item.controls[0].setValue('Factor ' + (index + 1));
        });
    }
};

module.exports = events;
