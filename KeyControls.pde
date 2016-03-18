//// Keyboard controls ////
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      if (free_time == true) {
        ft_calib += 0.25;
      }
      else if (!free_time && user_bpm < max_bpm) {
        ++user_bpm;
        int_preset[c_preset][0] = user_bpm;
        setUserBPM();
      }
    } 
    else if (keyCode == DOWN) {
      if (free_time == true && ft_calib > 0) {
        ft_calib -= 0.25;
      }
      else if (!free_time & user_bpm > min_bpm) {
        --user_bpm;
        int_preset[c_preset][0] = user_bpm;
        setUserBPM();
      }      
    }
    else if (keyCode == LEFT) {
      if (midi_out > 0) {
        //--midi_out; // not sure why this subtracts
        controlP5.controller("MIDI_OUT").setValue((float)midi_out);
      }
    }
    else if (keyCode == RIGHT) {
      if (midi_out < 15) {
        midi_out += 2; // not sure why i need to add 2... :(
        controlP5.controller("MIDI_OUT").setValue((float)midi_out);
      }
    }
    else if (keyCode == SHIFT) {
      sustain = !sustain;
      setSustain(-1);
    }
  }
  else {
    // Transposition key controls
    for (int i = 0; i < piano_key.length; ++i) {
      if (key == piano_key[i] && keyEvent.isControlDown() == false && 
          keyEvent.isAltDown() == false ) {
        transposition = i;
        int_preset[c_preset][1] = transposition;
        t7.setValue("Current Transposition: "+key_pos[transposition]);
      }
    }
    // Note duration key controls
    for (int i = 0; i < nd.length; ++i) {
      if (key == duration_key[i]) {
        dur_key = i;
        previous_dur_key = dur_key;
        int_preset[c_preset][2] = dur_key;
        if (i == nd.length-1) {
          dotted_note = false;
          dotted = "";
        }
        t6.setValue("Current Duration: "+dotted+note_dur_name[dur_key]);
      }
    }
    // Scale key controls
    for (int i = 0; i < scales_key.length; ++i) {
      if (key == scales_key[i]) {
        scale_key = i;
        int_preset[c_preset][3] = scale_key;
        previous_scale_key = scale_key;
        t8.setValue("Current Scale: "+scale_names[scale_key]);
      }
    }
    // Key controls for presets TODO: FIX THIS!!!
    for (int i = 0; i < 10; ++i) {
      String x = Integer.toString(i);
      char num = x.charAt(0);
      if (key == num && keyEvent.isControlDown()) {
        // needed to activate the 10th radio
        if (i==0) {
          x="10";
        }
        //println("--------------------------------> preset: "+(i+61)+" activate: "+x);
        presets.activate(x);
        radioPresets(60+i);
      }
    }
    // turn on / off filters
    for (int i = 1; i < 5; ++i) {
      String x = filter_keys[i-1];
      char val = x.charAt(0);
      if (key == val) {
        filter_on[i-1] = !filter_on[i-1];
        t11.setValue("Filter "+filter_names[i-1]+" set to "+filter_on[i-1]);
      }
    }
    // Toggle to free_time mode
    if (key == 'f') {
      free_time = !free_time;
      setFreeStatus();
    }
    // Toggle to dotted_note mode
    if (key == '.') {
      dotted_note = !dotted_note;
      setDotted();
    }
    // show / hide status / help
    if (key == TAB) {
      box_on = !box_on;
    }
    // use SPACE BAR to start and stop GMS
    if (key == ' ' && output != null ) {
      setStartStop(!playing);
    }
    if (key == '/') {
      dur_prob = !dur_prob;
      tg_preset[c_preset][3] = dur_prob;
      setDurationProbabilities();
    }
    if (key == ';') {
      note_prob = !note_prob;
      tg_preset[c_preset][4] = note_prob;
      setNoteProbabilities();
    }
    if (key == '-') {
      mirror_on = !mirror_on;
      tg_preset[c_preset][5] = mirror_on;
    }
    // key events not to be inclded in preset:
    // hide logo and cursor when controls are hidden
    if ( keyCode == 72 && keyEvent.isAltDown() ) {
      logo_on = !logo_on;
      if (!logo_on) {
        noCursor();
      }
      else {
        cursor();
      }
    }
    // toggle FullScreen mode
    if (key == ESC) {
      key = 0; // don't let them escape!
      fsm = !fsm;
      if (fsm) {
        if (sfsm) {
          sfs.leave();
        }
        fs.enter();
      }
      else {
        fs.leave();
      }
    }
    // toggle SoftFullScreen mode
    if (key == '`') {
      key = 0; // don't let them escape!
      sfsm = !sfsm;
      if (sfsm) {
        if (fsm) {
          fs.leave();
        }
        sfs.enter();
      }
      else {
        sfs.leave();
      }
    }
    // MIDI panic button (stop and turn off all notes on all channels)
    // causes a temporary delay in the video
    if (key == DELETE || key == BACKSPACE) {
      playing = false;
      play_status = "stopped";
      t2.setValue("[space] = stop / start ("+play_status+")");
      stopAllNotes(); 
    }
  }
}

// set methods for toggle controls stored in presets
void setDotted() {
  dotted = "";
  if (dotted_note) {
    if ( dur_key < nd.length-1 ) { // add -1 to prevent dotted 64th
      dotted = "Dotted ";
    }
    else {
      dotted_note = !dotted_note;
    }
  }
  tg_preset[c_preset][2] = dotted_note;
  t6.setValue("Current Duration: "+dotted+note_dur_name[dur_key]);
}

void setSustain(int cc) {
  switch(cc) {
    case -1:
      cc = 0;
      sus_status = "off";
      if (sustain) {
        sus_status = "on";
        cc = 127;
      }
      break;
    case 0:
      sustain = false;
      sus_status = "off";
      break;
    case 127:
      sustain = true;
      sus_status = "on";
      break;
  }
  if (output != null ) {
    output.sendController(midi_out, 64, cc);
  }
  tg_preset[c_preset][0] = sustain;
  t3.setValue("[shift] = toggle sustain ("+sus_status+")"); 
}

void setFreeStatus() {
  init_start = true;
  free_status = "bpm";
  if (free_time) {
    free_status = "free";
  }
  tg_preset[c_preset][1] = free_time;
  t5.setValue("Duration Mode: "+free_status);
}

void setDurationProbabilities() {
  init_start = true;
  dur_prob_status = "OFF";
  if (dur_prob) {
    previous_dur_key = dur_key;
    dur_prob_status = "ON";
  }
  else {
    dur_key = previous_dur_key;
  }
  t9.setValue("DURATION PROBABILITIES: "+dur_prob_status);
}

void setNoteProbabilities() {
  note_prob_status = "OFF";
  if (note_prob) {
    note_prob_status = "ON";
  }
  else {
    scale_key = previous_scale_key;
  }
  t10.setValue("NOTE PROBABILITIES: "+note_prob_status);
}

void setUserBPM() {
  controlP5.controller("BPM").setValue((float)user_bpm);
  interval = 1000.0 / (user_bpm / 60.0);
}

void setNoteRange() {
  note_range_max = 127 - ((10-octave_max)*12);
  note_range_min = (octave_min-1) * 12;
}

void setStartStop(boolean b) {
  playing = b;
  if (playing) {
    init_start = true;
    play_status = "playing";
  }
  else {
    play_status = "stopped";
    output.sendNoteOff(previous_midi_out, previous_note, 0);
    //output.sendController(previous_midi_out, 123, 1);
  }
  t2.setValue("[space] = stop / start ("+play_status+")");
}
