/// Loose check: something@something.something.
bool looksLikeEmail(String s) => RegExp(r'.+@.+\..+').hasMatch(s.trim());
