/// Sound labels supplied by the caption author, never inferred from audio.
String captionSoundCues(String caption) => RegExp(r'\[[^\]\n]+\]')
    .allMatches(caption).map((match) => match.group(0)!).join(' ');
