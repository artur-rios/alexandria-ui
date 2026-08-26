import 'package:alexandria_ui/features/playback/presentation/media/device_layer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which pass of a device painter to draw (UC-21, FR-PL-07).
void main() {
  test('GivenDeviceLayer_WhenItsValuesAreRead_ThenChassisComesBeforeForeground', () {
    // The stage paints `chassis` first and `foreground` last (Finding 2):
    // the medium has to land between the two, behind the part of the device
    // — the tonearm, the door, the lid — that is meant to be seen touching
    // or covering it. `DeviceLayer.values`' own order is what a caller that
    // iterates it (as every device painter's test file's golden loop does)
    // relies on to draw the two passes in that order.
    expect(DeviceLayer.values, [DeviceLayer.chassis, DeviceLayer.foreground]);
  });
}
