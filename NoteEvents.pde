void chooseTheNote() {
  ////////////////////////////////////////////////////////////////
  // calculate a MIDI note value from 0-127 based on brightestX
  if (mirror_on) {
    noteValue = int( ((float)(width-brightestX) / width) * (note_range_max-note_range_min) ) + note_range_min;
  }
  else {
    noteValue = int( ((float)(brightestX) / width) * (note_range_max-note_range_min) ) + note_range_min;
  }
  // div by 12 to get the octave we're in
  octave = floor(noteValue * .08333); // instead of divide by 12

  // use the remainder to get a scale position 
  int scale_pos = 0;

  // Weighted randomness: randomize notes based on user adjusted probability distributions
  if ( note_prob == true ) {
    scale_key = 4; // chromatic
    scale_pos = weightedRandom(nwsum,note_weights);
  }
  else {
    // use the remainder to get a scale position 
    scale_pos = round( (((float)noteValue * .08333) - octave) * (scales[scale_key].length-1) );
  }
  // Simple randomness: shift the scale_pos up or down when note_rand > value
  if ( !note_prob && note_rand > random(1,100) ) {
    float r = random(1);
    if (r > 0.5) { // go up
      float r2 = random(1);
      if (r2 > 0.5 && scale_pos < (scales[scale_key].length-1)) {
        // calculate biggest possible increase (bpi)
        int bpi = scales[scale_key].length - scale_pos;
        scale_pos = scale_pos + (int)(bpi * (random(1,note_rand)*.01)); // vs div by 100
      }
      else if (scale_pos > 0) { // go down
        scale_pos = scale_pos - (int)(scale_pos * (random(1,note_rand)*.01));
      }
    }
  }
  // caluclate velocity (0-127) based on brightestY
  velocity = int( ((float)(height-brightestY) / height) * 127 );

  // calculate the_note based on scale, octave and transposition
  the_note = scales[scale_key][scale_pos]+(octave * 12)+transposition;

  // keep the note within allowable range
  while( the_note > 127 ) {
    the_note -= 12;
  }
}

// Calculate the duration based on free mode, bpm mode, or external sync
void chooseTheDuration() {
  if ( free_time == true && !external_sync ) {
    user_int = (512 - (avg_brightness * (2.0 + ft_calib)));
    if (user_int < 20 ) {
      user_int = 20;
    }
    // println("midi.user_int: "+midi.user_int+" ft_calib: "+ft_calib+" avg_brightness: "+avg_brightness);
  }
  else {
    user_dur = nd[dur_key];
    // randomize duration based on probability distribution when dur_prob is true 
    if (dur_prob == true) {
      dur_key = weightedRandom(wsum,dur_weights);
      while( dur_key > nd.length-1 ) {
        --dur_key;
      }
      //println("DUR_KEY: "+dur_key+" length: "+nd.length);
      user_dur = nd[dur_key];
      if (dot_prob >= random(1,100)) {
        if (!external_sync) {
          user_dur += ( user_dur * .5 ); // vs divide by 2
        }
        else if ( dur_key < nd.length ) { // add -1 to prevent dotted 64th 
          user_dur += ( user_dur * .5 ); 
        }
      }
    }
    else if ( dotted_note == true ) {
      if (!external_sync) {
        user_dur += ( user_dur * .5 );
      }
      else if ( dur_key < nd.length ) { // add -1 to prevent dotted 64th
        user_dur += ( user_dur * .5 );
      }
    }
    if (!external_sync) {
      user_int = interval * user_dur;
    }
  }
}
//// Function to return a random value from an array based on weights
int[] randomizeProbabilities(int weights[]) { 
  int count = weights.length; 
  for (int i = 0; i < count; ++i) {
    weights[i] = (int)random(0,100);
  } 
  return weights; 
}
//// Function to return a random value from an array based on weights
int weightedRandom(int sum, int weights[]) { 
    int count = weights.length; 
    int i = 0; 
    int n = 0; 
    float num = random(0, sum); 
    while(i < count){
        n += weights[i]; 
        if(n >= num){
            break; 
        }
        i++;
    } 
    return i; 
}

void processEvents(SyncEvent s) {
  switch (s.getStatus()){
    case SyncEvent.TIMING_CLOCK:
      //println("EXT SYNC: "+pulseCount+" durPC: "+midi.durPC+" user_dur: "+midi.   user_dur);
      durPC = processExternalSync(durPC);
      //println("EXT SyncEvent.TIMING_CLOCK: "+SyncEvent.TIMING_CLOCK+" pulseCount: "+pulseCount);
      if (pulseCount == pulses_per_quarter * 8 ) {
        pulseCount = pulseStart - 1; // subtract 1 to make up for ++
      }
      ++pulseCount;
      break;
    case SyncEvent.START: 
      //playing = true;
      //println("SyncEvent.START: "+SyncEvent.START);
      pulseCount = pulseStart;
      init_start = true;
      break;
    case SyncEvent.STOP: 
      playing = false;
      setStartStop(playing);
      //println("SyncEvent.STOP: "+SyncEvent.STOP); 
      pulseCount = pulseStart;
      break;
  }
}

void stopAllNotes() {
  if (output != null) {
    for (int c = 0; c < 16; ++c) {
      output.sendController(c, 123, 1);
    }
  }
}

void playTheNote() {
  if (playing == true) {
    // turn off previous note
    output.sendNoteOff(previous_midi_out, previous_note, 0);
    // choose the new note
    chooseTheNote();
      
    // Play the_note if rest probability less than random 1-100 otherwise it's a "rest"
    if ( rest_prob < random(1,100) ) {
      // play new note
      valid = output.sendNoteOn(midi_out, the_note, velocity);
    }
    // set previous note and midi channel
    previous_note = the_note;
    previous_midi_out = midi_out;
  }
}

// External Sync method
int processExternalSync(int dpc) {
  if ( playing == true && output != null ) {
    if ( dpc == 1 ) {
      chooseTheDuration();
    }
    // wait til durPC matches the duration
    if ( init_start == false ) {
      if ( dpc == user_dur ) {
        //println("DPC: "+dpc+" USER_DUR:"+user_dur+" PULSECOUNT: "+pulseCount);
        dpc = 1;
        playTheNote();
        //lastPulsePlayed = pulseCount;
      }
      else {
        ++dpc;
      }
    }
    else {
      if (pulseCount % pulses_per_quarter == 0) {
        dpc = 1;
        playTheNote();
        //lastPulsePlayed = pulseCount;
        init_start = false;
      }
      else {
        ++dpc;
      }
    }    
  }
  return dpc;
}
