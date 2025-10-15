extension RemovePrefix on String {
  String? removePrefix(final String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    } else {
      return null;
    }
  }
}
