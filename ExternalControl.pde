// XML Variables
String MIDIControllerName;
int MidiChannel;
String MidiChannelType;

void loadExternalControl() {
  extCrtlXML = new XMLElement(this, "GMSMidiController.xml");
  // println("----------------------------------------------------> EXTCTRL XML Loaded");
}

void processTransposition(Note n) {
  if (n.getPitch() > 47 && n.getPitch() < 60) {
   transposition = n.getPitch() - 48;
   int_preset[c_preset][1] = transposition;
   t7.setValue("Current Transposition: "+key_pos[transposition]); 
  }
}

void processProgramChange(ProgramChange p) {
  // println("-----------------------------> pc: "+p.getNumber());
  if ( p.getNumber() < 10 ) {
    String pre = Integer.toString(p.getNumber()+1);
    presets.activate(pre);
    radioPresets(61+(p.getNumber()));
  }
}

void processControlChange(MidiEvent m) { // MidiEvent m (works)
  //println("input: "+m.getInput()+" data1: "+m.getData1()+" data2 "+m.getData2());
  int cc = 999;
  // Adjust Note Probability Distributions
  for( int i=0; i < 12; ++i) {
    cc = extCrtlXML.getChild("NotePD").getChild(i+1).getIntAttribute("CC");
    if (m.getData1() == cc) {
      int v = (int)(((m.getData2()/127.0)*100.0));
      controlP5.controller(key_pos[i]).setValue(v);
    }
  }
  // Toggle NotePD
  cc = extCrtlXML.getChild("NotePD").getChild(0).getIntAttribute("CC");
  if (m.getData1() == cc) {
    note_prob = !note_prob;
    tg_preset[c_preset][4] = note_prob;
    setNoteProbabilities();
  }

  // Adjust Duration Probability Distributions
  for ( int i=0; i < 7; ++i ) {
    cc = extCrtlXML.getChild("DurationPD").getChild(i+1).getIntAttribute("CC");
    if (m.getData1() == cc) {
      int v = (int)(((m.getData2()/127.0)*100.0));
      controlP5.controller(abbr_note_dur[i]).setValue(v);
    }    
  }
  // Dotted Probabilities
  cc = extCrtlXML.getChild("DurationPD").getChild(8).getIntAttribute("CC");
  if (m.getData1() == cc) {
    int v = (int)(((m.getData2()/127.0)*100.0));
    controlP5.controller("Dot").setValue(v);
  }
  // Toggle DurationPD
  cc = extCrtlXML.getChild("DurationPD").getChild(0).getIntAttribute("CC");
  if (m.getData1() == cc) {
    dur_prob = !dur_prob;
    tg_preset[c_preset][3] = dur_prob;
    setDurationProbabilities();
  }
  // Randomness
  cc = extCrtlXML.getChild("Randomness").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int v = (int)(((m.getData2()/127.0)*100.0));
    controlP5.controller(" ").setValue(v);
  }
  // MIDI Channel
  cc = extCrtlXML.getChild("MidiChannel").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int v = (int)(((m.getData2()/127.0)*15.0));
    controlP5.controller("MIDI_OUT").setValue((float)v+1);
  }
  // Top Octave Increment
  cc = extCrtlXML.getChild("TopOctaveIncrement").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int n = octave_max + 1;
    if (n > 10) { n = octave_min; }
    setOctaveMax(n);
  }
  // Bottom Octave Increment
  cc = extCrtlXML.getChild("BottomOctaveIncrement").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int n = octave_min + 1;
    if (n > octave_max) { n = 1; }
    setOctaveMin(n);
  }
  // Toggle Free Mode
  cc = extCrtlXML.getChild("ToggleFreeMode").getIntAttribute("CC");
  if (m.getData1() == cc) {
    free_time = !free_time;
    setFreeStatus();
  }
  // StartStop
  cc = extCrtlXML.getChild("StartStop").getIntAttribute("CC");
  if (m.getData1() == cc) {
    setStartStop(!playing);
  }
  // Sustain
  cc = extCrtlXML.getChild("Sustain").getIntAttribute("CC");
  if (m.getData1() == cc) {
    setSustain(m.getData2());
  }
  // SetDuration
  cc = extCrtlXML.getChild("SetDuration").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int v = (int)(((m.getData2()/127.0)*(abbr_note_dur.length-1)));
    dur_key = v;
    previous_dur_key = dur_key;
    int_preset[c_preset][2] = dur_key;
    t6.setValue("Current Duration: "+dotted+note_dur_name[dur_key]);
  }
  // ToggleDotted
  cc = extCrtlXML.getChild("ToggleDotted").getIntAttribute("CC");
  if (m.getData1() == cc) {
    dotted_note = !dotted_note;
    setDotted();
  }
  // SetScale
  cc = extCrtlXML.getChild("SetScale").getIntAttribute("CC");
  if (m.getData1() == cc) {
    int v = (int)(((m.getData2()/127.0)*(scale_names.length-1)));
    scale_key = v;
    int_preset[c_preset][3] = scale_key;
    previous_scale_key = scale_key;
    t8.setValue("Current Scale: "+scale_names[scale_key]);    
  }
  // ToggleMirroring
  cc = extCrtlXML.getChild("ToggleMirroring").getIntAttribute("CC");
  if (m.getData1() == cc) {
    mirror_on = !mirror_on;
    tg_preset[c_preset][5] = mirror_on;
  }
}
