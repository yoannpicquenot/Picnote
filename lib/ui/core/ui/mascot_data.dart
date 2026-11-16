/// The mascot faces from the design system. `currentColor` is the face ink,
/// `HIGHLIGHT` the shine in the eyes (usually the background color).
enum MascotMood { cheerful, happy, joy, wink, love, peek, surprised, sleepy }

class MascotSvg {
  const MascotSvg(this.width, this.height, this.body);

  final double width;
  final double height;
  final String body;
}

const _eyeArc =
    'M28.3528 9.9243C21.6789 10.4629 14.8079 14.6895 10.4942 18.7268L6.8689 22.1197L0 14.9569L3.62525 11.564C8.79966 6.72122 17.7091 0.883679 27.5396 0.0902971C32.5963 -0.317807 37.9214 0.61653 42.9144 3.73122C47.8689 6.82192 52.1313 11.8301 55.5251 18.9681C56.6976 21.4342 55.6244 24.3725 53.1281 25.5308C50.6317 26.6891 47.6575 25.629 46.485 23.1628C43.6865 17.2767 40.5456 13.9228 37.5818 12.0739C34.6565 10.2491 31.5484 9.66639 28.3528 9.9243Z';
const _eyeArcRight =
    'M107.647 9.9243C114.321 10.4629 121.192 14.6895 125.506 18.7268L129.131 22.1197L136 14.9569L132.375 11.564C127.2 6.72122 118.291 0.883679 108.46 0.0902971C103.404 -0.317807 98.0786 0.61653 93.0856 3.73122C88.1311 6.82192 83.8687 11.8301 80.4749 18.9681C79.3024 21.4342 80.3756 24.3725 82.8719 25.5308C85.3683 26.6891 88.3425 25.629 89.515 23.1628C92.3135 17.2767 95.4544 13.9228 98.4182 12.0739C101.343 10.2491 104.452 9.66639 107.647 9.9243Z';
const _mouthLeft =
    'M46.6943 68.1006C42.0395 67.4677 36.8093 62.894 34.4008 54.7927L32.976 50L23.3906 52.8497L24.8155 57.6424C27.907 68.0411 35.4768 76.6674 45.347 78.0095C55.7246 79.4205 65.4901 72.488 72.1338 58.3432C73.3078 55.8438 72.2333 52.8659 69.7338 51.6919C67.2344 50.5179 64.2565 51.5924 63.0825 54.0919C57.3263 66.3471 50.8417 68.6646 46.6943 68.1006Z';
const _mouthRight =
    'M89.3056 68.1006C93.9605 67.4677 99.1906 62.894 101.599 54.7927L103.024 50L112.609 52.8497L111.184 57.6424C108.093 68.0411 100.523 76.6674 90.653 78.0095C80.2753 79.4205 70.5099 72.488 63.8662 58.3432C62.6922 55.8438 63.7667 52.8659 66.2661 51.6919C68.7656 50.5179 71.7435 51.5924 72.9175 54.0919C78.6737 66.3471 85.1583 68.6646 89.3056 68.1006Z';
const _eyeBall =
    '<path d="M38 19C38 29.4934 29.4934 38 19 38C8.50659 38 0 29.4934 0 19C0 8.50659 8.50659 0 19 0C29.4934 0 38 8.50659 38 19Z" fill="currentColor"/>'
    '<path d="M31.3124 13.4659C31.3124 16.5034 28.8819 18.9659 25.8838 18.9659C22.8857 18.9659 20.4552 16.5034 20.4552 13.4659C20.4552 10.4283 22.8857 7.96588 25.8838 7.96588C28.8819 7.96588 31.3124 10.4283 31.3124 13.4659Z" fill="HIGHLIGHT"/>'
    '<path d="M20.4552 19.4659C20.4552 20.8466 19.24 21.9659 17.7409 21.9659C16.2419 21.9659 15.0266 20.8466 15.0266 19.4659C15.0266 18.0852 16.2419 16.9659 17.7409 16.9659C19.24 16.9659 20.4552 18.0852 20.4552 19.4659Z" fill="HIGHLIGHT"/>';

String _p(String d) => '<path fill-rule="evenodd" clip-rule="evenodd" d="$d" fill="currentColor"/>';

const _heart =
    '<path d="M19 34C19 34 0 22.5 0 10.5C0 4.5 4.8 0 10.5 0C14.2 0 17.3 2 19 5C20.7 2 23.8 0 27.5 0C33.2 0 38 4.5 38 10.5C38 22.5 19 34 19 34Z" fill="currentColor"/>';

final mascotSvgs = <MascotMood, MascotSvg>{
  MascotMood.happy: MascotSvg(136, 79, _p(_eyeArc) + _p(_eyeArcRight) + _p(_mouthLeft) + _p(_mouthRight)),
  MascotMood.cheerful: MascotSvg(
    136,
    79,
    '<g transform="translate(20 4) scale(0.84)">$_eyeBall</g>'
    '<g transform="translate(84 4) scale(0.84)">$_eyeBall</g>'
    '<path d="M55 60C59.5 63.5 63.8 65 68 65C72.2 65 76.5 63.5 81 60" stroke="currentColor" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
  ),
  MascotMood.joy: MascotSvg(
    136,
    79,
    '${_p(_eyeArc)}${_p(_eyeArcRight)}'
    '<path d="M40 46H96C96 63 83.5 73 68 73C52.5 73 40 63 40 46Z" fill="HIGHLIGHT" stroke="currentColor" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M55 70C58.5 64.5 63 62 68 62C73 62 77.5 64.5 81 70C77.5 72 73 73 68 73C63 73 58.5 72 55 70Z" fill="currentColor"/>'
    '<path d="M22 44C24 41 28 41 30 44M106 44C108 41 112 41 114 44" stroke="currentColor" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" opacity="0.45" fill="none"/>',
  ),
  MascotMood.wink: MascotSvg(
    122,
    87,
    '$_eyeBall'
    '${_p('M111.643 26.6518L115.566 29.7366L121.748 21.8759L117.817 18.7852L114.727 22.7155C117.817 18.7852 117.814 18.7828 117.814 18.7828L117.811 18.78L117.802 18.7731L117.778 18.7545C117.759 18.7399 117.735 18.7211 117.705 18.6981C117.645 18.6523 117.564 18.5901 117.461 18.5131C117.255 18.3592 116.964 18.1458 116.596 17.8854C115.859 17.3652 114.807 16.6537 113.497 15.852C110.891 14.2579 107.188 12.2598 102.858 10.7158C94.3214 7.67185 82.2488 6.06344 71.8493 14.5037C69.7052 16.2439 69.3777 19.3927 71.1179 21.5368C72.8581 23.681 76.0069 24.0084 78.151 22.2683C84.5919 17.0409 92.3825 17.5972 99.4991 20.1349C102.996 21.3818 106.066 23.0288 108.278 24.3821C109.376 25.0541 110.244 25.6418 110.825 26.0524C111.115 26.2574 111.333 26.4173 111.47 26.5203C111.539 26.5718 111.588 26.6091 111.616 26.6305L111.642 26.6504L111.643 26.6518Z')}'
    '<g transform="translate(-7.126 8)">${_p(_mouthLeft)}${_p(_mouthRight)}</g>',
  ),
  MascotMood.love: MascotSvg(
    136,
    79,
    '<g transform="translate(10 0) scale(1.05)">$_heart</g>'
    '<g transform="translate(86 0) scale(1.05)">$_heart</g>'
    '${_p(_mouthLeft)}${_p(_mouthRight)}',
  ),
  MascotMood.peek: MascotSvg(
    136,
    84,
    '<g transform="translate(16 0)"><circle cx="19" cy="19" r="19" fill="currentColor"/><circle cx="29" cy="19" r="6.5" fill="HIGHLIGHT"/><circle cx="21" cy="12" r="2.6" fill="HIGHLIGHT"/></g>'
    '<g transform="translate(82 0)"><circle cx="19" cy="19" r="19" fill="currentColor"/><circle cx="29" cy="19" r="6.5" fill="HIGHLIGHT"/><circle cx="21" cy="12" r="2.6" fill="HIGHLIGHT"/></g>'
    '<g transform="translate(26 -2)">${_p(_mouthLeft)}</g>',
  ),
  MascotMood.surprised: MascotSvg(
    136,
    104,
    '<g transform="translate(18 0) scale(0.6)">${_p(_eyeArc)}</g>'
    '<g transform="translate(36 0) scale(0.6)">${_p(_eyeArcRight)}</g>'
    '<g transform="translate(16 22)">$_eyeBall</g>'
    '<g transform="translate(82 22)">$_eyeBall</g>'
    '<ellipse cx="68" cy="88" rx="11" ry="14" fill="currentColor"/>',
  ),
  MascotMood.sleepy: MascotSvg(
    168,
    79,
    '<g transform="translate(0 26) scale(1 -1)">${_p(_eyeArc)}${_p(_eyeArcRight)}</g>'
    '<g transform="translate(19.6 16) scale(0.72)">${_p(_mouthLeft)}${_p(_mouthRight)}</g>'
    '<path d="M140 4H154L140 18H154" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
    '<path d="M156 26H165L156 35H165" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
  ),
};
