﻿/* http://keith-wood.name/calendars.html
   Montenegrin localisation for calendars datepicker for jQuery.
   Written by Miloš Milošević - fleka d.o.o. */
(function($) {
	$.calendars.picker.regional['me-ME'] = {
		renderer: $.calendars.picker.defaultRenderer,
		prevText: '&#x3c;', prevStatus: 'Prikaži prethodni mjesec',
		prevJumpText: '&#x3c;&#x3c;', prevJumpStatus: 'Prikaži prethodnu godinu',
		nextText: '&#x3e;', nextStatus: 'Prikaži sljedeći mjesec',
		nextJumpText: '&#x3e;&#x3e;', nextJumpStatus: 'Prikaži sljedeću godinu',
		currentText: 'Danas', currentStatus: 'Tekući mjesec',
		todayText: 'Danas', todayStatus: 'Tekući mjesec',
		clearText: 'Obriši', clearStatus: 'Obriši trenutni datum',
		closeText: 'Zatvori', closeStatus: 'Zatvori kalendar',
		yearStatus: 'Prikaži godine', monthStatus: 'Prikaži mjesece',
		weekText: 'Sed', weekStatus: 'Sedmica',
		dayStatus: '\'Datum\' DD, M d', defaultStatus: 'Odaberi datum',
		isRTL: false
	};
	$.calendars.picker.setDefaults($.calendars.picker.regional['me-ME']);
})(jQuery);
