/// Печать страницы в браузере.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// В браузере печать доступна.
bool webPrintAvailable() => true;

/// Вызвать системный диалог печати браузера (`window.print()`).
///
/// В браузере глобальный объект (`globalContext`) — это и есть `window`,
/// поэтому вызов метода `print` открывает диалог печати.
void printPage() {
  globalContext.callMethod('print'.toJS);
}
