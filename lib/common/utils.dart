import 'dart:math';

import 'package:address/address.dart';

String generateRandomString(int len, {List<int>? dict}) {
  var r = Random();
  dict ??= [for (var i = 89; i <= 122; i += 1) i];
  List<int> charcodes = List.generate(len, (index) {
    var res = r.nextInt(dict!.length - 1) + 1;
    return dict[res];
  });
  return String.fromCharCodes(charcodes);
}

String generateRandomStringAlNum(int len, {bool allowCapitals = true}) {
  return generateRandomString(
    len,
    dict:
        [for (var i = 48; i <= 57; i += 1) i] +
        (allowCapitals
            ? [for (var i = 65; i <= 90; i += 1) i]
            : [] as List<int>) +
        [for (var i = 97; i <= 122; i += 1) i],
  );
}

Address addressFromJsonMap(Map<String, dynamic> jsonMap) {
  return Address(
    country: jsonMap["country"],
    fullName: jsonMap["full-name"],
    city: jsonMap["city"],
    postalCode: jsonMap["postal-code"],
    zone: jsonMap["zone"],
    addressLine1: jsonMap["address"],
    addressLine2: jsonMap["address-complement"],
  );
}

Map<String, dynamic> addressToJsonMap(Address address) {
  return Map.fromEntries(
    {
      "country": address.country,
      "full-name": address.fullName,
      "city": address.city,
      "postal-code": address.postalCode,
      "zone": address.zone,
      "address": address.addressLine1,
      "address-complement": address.addressLine2,
    }.entries.where((e) => e.value != null),
  );
}
