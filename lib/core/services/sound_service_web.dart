// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SoundService {
  static void playClick() => _play('''
    var o=c.createOscillator(),g=c.createGain();
    o.connect(g);g.connect(c.destination);
    o.type='sine';o.frequency.value=880;
    g.gain.setValueAtTime(0.3,c.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001,c.currentTime+0.08);
    o.start(c.currentTime);o.stop(c.currentTime+0.09);
  ''');

  static void playNotification() => _play('''
    function b(f,t,d){
      var o=c.createOscillator(),g=c.createGain();
      o.connect(g);g.connect(c.destination);
      o.type='sine';o.frequency.value=f;
      g.gain.setValueAtTime(0.4,c.currentTime+t);
      g.gain.exponentialRampToValueAtTime(0.001,c.currentTime+t+d);
      o.start(c.currentTime+t);o.stop(c.currentTime+t+d+0.02);
    }
    b(880,0,0.12);b(1100,0.15,0.12);b(1320,0.3,0.25);
  ''');

  static void _play(String tones) {
    js.context.callMethod('eval', ['''
      try {
        var c=new(window.AudioContext||window.webkitAudioContext)();
        $tones
      } catch(e){}
    ''']);
  }
}
