// also shutdown the midi thread when the applet is stopped
void stop() {
  if (midi!=null) {
    midi.isActive=false;
  }
  super.stop();
}

class MidiThread extends Thread {

  long previousTime;
  boolean isActive=true;

  MidiThread(double bpm) {
    // interval default is quarter notes
    interval = 1000.0 / (bpm / 60.0);
    previousTime=System.nanoTime();
  }

  void run() {
    try {
      while(isActive) {
        if ( playing == true && output != null ) {
          // calculate time difference since last beat & wait if necessary
          if (!external_sync) {
            chooseTheDuration();
            double timePassed=(System.nanoTime()-previousTime)*1.0e-6;
            while(timePassed < user_int) {
              timePassed=(System.nanoTime()-previousTime)*1.0e-6;
            }
            playTheNote();
            // calculate real time until next beat
            long delay=(long)(user_int-(System.nanoTime()-previousTime)*1.0e-6);
            previousTime=System.nanoTime();
            if ( delay < 0 ) { 
              delay = 0;
            }
            Thread.sleep(delay);
          }
          // DEBUG:
          // println("INTERVAL: "+interval);
          // println("duration: "+note_durations[dur_key]+" note_dur_name: "+note_dur_name[dur_key]+" user_int: "+user_int);
          // println("midi out: "+timePassed+"ms"+" Delay: "+delay+" the_note: "+the_note+" velocity: "+velocity);
        }
      }
    } 
    catch(InterruptedException e) {
      //println("force quit...");
    }
  }
}
