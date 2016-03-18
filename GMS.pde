/******************************************************
 * Title: GMS The Gestural Music Sequencer
 * Version: 0.11 Beta
 * Author: John Keston
 * Web: http://audiocookbook.org
 * Email: keston@audiocookbook.org
 *
 * This application will send a MIDI stream of notes via an available MIDI device driver
 * The pitch  of the notes is based on the brightest X position in the video.  
 * The velocity is based on the brightest Y position in the video.
 * 
 * This application uses ControlP5 for the interface:
 * http://www.sojamo.de/libraries/controlP5/
 *******************************************************/
// import necessary classes
import java.awt.*;
import processing.video.*;
import rwmidi.*; // http://ruinwesen.com/support-files/rwmidi/documentation/RWMidi.html
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import fullscreen.*; // http://www.superduper.org/processing/fullscreen_api/

// GMS setup
void setup() {
  frameRate(15);
  background(0);
  size(640, 480);
  fs = new FullScreen(this);
  sfs = new SoftFullScreen(this);

  // controlP5 interface
  controlP5 = new ControlP5(this);
  controlP5.setColorActive(color(255,107,107));
  controlP5.setColorBackground(color(21,24,51));
  controlP5.setColorForeground(color(111,160,206));

  // SETUP DEFAULTS
  setDefaultPresets();

  // SLIDERS
  controlP5.addSlider("BPM",20,999,user_bpm,20,20,50,14).setId(1);         // BPM
  controlP5.addSlider("MIDI_OUT",1,16,midi_out,260,20,25,14).setId(58);    // MIDI Out Channel
  controlP5.addSlider(" ",0,100,0,25,224,100,14).setId(50);                // Randomness

  // NUMBER BOXES (OCTAVE MIN / MAX)
  //controlP5.numberBox("OCTAVES", octave_min, octave_max, octave_min, octave_max, 68, 20, 50, 14).setId(51); // Octave Range
  controlP5.addNumberbox("octave_min", octave_min, 94, 20, 14, 14).setId(51);
  controlP5.addNumberbox("octave_max", octave_max, 112, 20, 14, 14).setId(52);
  controlP5.controller("octave_min").setLabel("");
  controlP5.controller("octave_max").setLabel("");

  // set up chooser for no filter
  // chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  // chooser.setCurrentDirectory(null);

  t11 = controlP5.addTextlabel("messages","",360,448);
  t11.setColorValue(color(111,160,206));

  controlP5.addButton("save presets",1,360,380,100,20).setId(53);
  controlP5.addButton("load presets",1,360,410,100,20).setId(54);
  controlP5.addButton("load video",1,470,380,100,20).setId(59);

  // Camera settings button
  controlP5.addButton("camera settings",1,170,20,80,14).setId(57);

  controlP5.addButton("Randomize",1,360,120,50,14).setId(80);
  controlP5.addButton("randomize",1,490,120,50,14).setId(81);

  // GMS HELP / KEYBOARD CONTROLS
  t1 = controlP5.addTextlabel("h3","KEYBOARD CONTROLS:",25,254);
  t1 = controlP5.addTextlabel("help","[alt+h] = show or hide status / help",25,266);
  t1 = controlP5.addTextlabel("presets","[ctrl+0-9] = Choose a preset from 0 to 9",25,278);
  t2 = controlP5.addTextlabel("started","[space] = stop / start ("+play_status+")",25,290);
  t3 = controlP5.addTextlabel("sustain","[shift] = toggle sustain ("+sus_status+")",25,302);
  t1 = controlP5.addTextlabel("box","[tab] = toggle box around brightest coordinates",25,314);
  t1 = controlP5.addTextlabel("free","[f] = toggle between free and bpm mode",25,326);
  t1 = controlP5.addTextlabel("calibrate","[up/down] = calibrate free mode or +/- bpm",25,338);
  t1 = controlP5.addTextlabel("midi_shift","[left/right] = change MIDI output channel",25,350);
  t1 = controlP5.addTextlabel("durations","[z,x,c,v,b,n,m] = set durations from whole to sixty fourth",25,362);
  t1 = controlP5.addTextlabel("dot","[.] = dot the current duration",25,374);
  t1 = controlP5.addTextlabel("transpose","[q,2,w,3,e,r,5,t,6,y,7,u] = transpose starting from C through B",25,386);
  t1 = controlP5.addTextlabel("scale","[g,h,j,k,l] = choose the scale",25,398);
  t1 = controlP5.addTextlabel("durp","[/] = toggle duration probability distributions",25,410);
  t1 = controlP5.addTextlabel("notep","[;] = toggle note probability distributions",25,422);
  t1 = controlP5.addTextlabel("mirror","[-] = toggle video mirror image",25,434);
  t1 = controlP5.addTextlabel("full","[esc] = toggle full screen mode",25,446);
  t1 = controlP5.addTextlabel("sfull","[`] = toggle soft full screen mode (multiple monitors)",25,458);
  t1 = controlP5.addTextlabel("panic","[delete] = panic button (stop all notes on all channels)",25,470);

  // GMS STATUS MENU
  t1 = controlP5.addTextlabel("h4","GMS STATUS ("+gms_version+"):",25,140);
  t5 = controlP5.addTextlabel("stat1","Duration Mode: "+free_status,25,152);
  t6 = controlP5.addTextlabel("stat2","Current Duration: "+dotted+note_dur_name[dur_key],25,164);
  t7 = controlP5.addTextlabel("stat3","Current Transposition: "+key_pos[transposition],25,176);
  t8 = controlP5.addTextlabel("stat4","Current Scale: "+scale_names[scale_key],25,188);
  t1 = controlP5.addTextlabel("stat7","RANDOMNESS: ",25,212);
  t1 = controlP5.addTextlabel("stat8","octaves",132,24);

  // HEADERS
  t9 = controlP5.addTextlabel("h5","DURATION PROBABILITIES: "+dur_prob_status,490,140);
  t12 = controlP5.addTextlabel("h8","REST PROBABILITY:",490,302);
  t10 = controlP5.addTextlabel("h6","NOTE PROBABILITIES: "+note_prob_status,360,140);
  t1 = controlP5.addTextlabel("h7","PRESET ",290,140);

  // Pitch Probability Distributions
  for (int i = 0; i < key_pos.length; ++i ) {
    controlP5.addSlider(key_pos[i],0,100,50,360,152+(18*i),100,14).setId(10+i);
  }
  // Duration Probability Distributions
  for (int i = 0; i < abbr_note_dur.length; ++i ) {
    controlP5.addSlider(abbr_note_dur[i],0,100,50,490,152+(18*i),100,14).setId(30+i);
    d = i;
  }
  // Dot Slider (dot_prob)
  ++d;
  controlP5.addSlider("Dot",0,100,0,490,152+(18*d),100,14).setId(30+d);
  
  // Add the rest probability slider (rest_prob)
  controlP5.addSlider("  ",0,100,0,490,188+(18*d),100,14).setId(83);

  // Internal / External Sync Radio Button
  midisync = controlP5.addRadio("radioSync",490,212+(18*d));
  midisync.deactivateAll(); // use deactiveAll to not make the first radio button active.
  midisync.addItem("Internal Sync",55);
  midisync.addItem("External Sync",56);
  
  // Sync / Ext Control Radio
  midiIn = controlP5.addRadio("radioMidiIn",604,50);
  // midisync.deactivateAll(); // use deactiveAll to not make the first radio button active.
  midiIn.addItem("sync",78);
  midiIn.addItem("ctrl",79);

  // Preset Radio Buttons
  presets = controlP5.addRadio("radioPresets",300,152,10,10,13);
  for(int i=61; i < 71; ++i) {
    String preset = Integer.toString(i-60);
    presets.addItem(preset,i);
  }

  // MIDI OUTPUT Device ScrollList
  ScrollList l = controlP5.addScrollList("MIDIDeviceList",180,60,200,280);
  l.setLabel("CHOOSE MIDI OUTPUT DEVICE");
  MidiOutputDevice devices[] = RWMidi.getOutputDevices();
  for (int i = 0; i < devices.length; i++) {
    // println(i + ": " + devices[i].getName());
    String outDev = devices[i].getName(); 
    if (outDev.length() > 25) {
      outDev = devices[i].getName().substring(0,25);
    }
    controlP5.Button b = l.addItem(outDev+" [out]",i);
    //b.setId(100 + i);
  }
  // MIDI INPUT Device ScrollList
  ScrollList l3 = controlP5.addScrollList("MIDIinDevList",400,60,200,280);
  l3.setLabel("CHOOSE EXTERNAL MIDI DEVICE");
  MidiInputDevice idev[] = RWMidi.getInputDevices();
  for (int i = 0; i < idev.length; i++) {
    // println(i + ": " + idev[i].getName());
    String inDev = idev[i].getName(); 
    if (inDev.length() > 25) {
      inDev = idev[i].getName().substring(0,25);
    }
    controlP5.Button a = l3.addItem(inDev + " [in]",i);
    //a.setId(300 + i);
  }
  // Video Input Device ScrollList
  // TODO: Allow use of external video files 
  ScrollList l2 = controlP5.addScrollList("CameraList",20,60,140,200);
  l2.setLabel("Choose a Camera");
  try {
    cameras = Capture.list();
    for (int i = 0; i < cameras.length; i++) {
      //println(i + ": " + cameras[i]);
      controlP5.Button c = l2.addItem(cameras[i],i);
      //c.setId(200 + i);
    }
  } catch (RuntimeException e){
    System.out.println(e.toString());
  }
  // load the GMS logo
  logo = loadImage("GMSimage.png");
}

void mousePressed() {
  // Visit ACB when logo is clicked
  if(logo_on && mouseX > 335 && mouseX < 635 && mouseY > 5 && mouseY < 45) {
    link("http://audiocookbook.org/tag/gms/", "_new");
  }
}

void draw() {
  if (video_on) {
    int[] bxy = {0,0};
    if (video_loaded) {
      bxy = processVideoLoop();
    }
    else {
      bxy = processVideoInput();
    }
    // TODO: Calculate distance between previous brightest pixel
    // use the value to adjust CCs like cutoff? time? modulation?
    brightestX = bxy[0];
    brightestY = bxy[1];

    // Draw a blue box at the brightness coords and display status text
    // when enabled (tab key)
    if (box_on) {
      noFill();
      stroke(0, 100, 200);
      // invert box position if mirror_on is true
      if (mirror_on) {
        rect(width-(brightestX+30), brightestY-30, 60, 60);
      }
      else {
        rect(brightestX, brightestY, 60, 60);
      }
    }
    // values for previous brightest pixels
    // TODO: move these to the bottom of Timer?
    pbX = brightestX;
    pbY = brightestY;
    // DEBUG
    // println(" octave: "+octave+" scale_pos: "+scale_pos+" nv: "+noteValue);
    // println("avg_brightness: "+avg_brightness+" brightestValue: "+brightestValue+" % "+multiplier);
    filterVideo();
  }
  else {
    // draw a black background until video is on
    background(0); 
  }
  if (logo_on) {
    // change cursor to hand over logo
    if(mouseX > 335 && mouseX < 635 && mouseY > 5 && mouseY < 45) {
      cursor(HAND);
    }
    else {
      cursor(ARROW); 
    }
    // display logo if logo_on = true (alt+h to toggle)
    image(logo,335,4);    
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isGroup()) {
    if(theEvent.name().equals("MIDIDeviceList")) {
      MIDIDeviceID = (int)(theEvent.group().value());
      output = RWMidi.getOutputDevices()[MIDIDeviceID].createOutput();
      t11.setValue(RWMidi.getOutputDevices()[MIDIDeviceID]+" selected.");
    }
    // MIDI SYNC INPUT device selection
    if (theEvent.name().equals("MIDIinDevList") && inDeviceType == "sync" ) {
      MIDIInputDeviceID = (int)theEvent.group().value();
      if(syncIn != null){
        syncIn.closeMidi();
      }
      //syncIn = RWMidi.getInputDevices()[MIDIInputDeviceID].createInput();
      syncIn =  RWMidi.getInputDevices()[MIDIInputDeviceID].createInput(pulses_per_quarter);
      t11.setValue(RWMidi.getInputDevices()[MIDIInputDeviceID]+" for "+inDeviceType);
    }
    // MIDI CTRL INPUT device selection
    if (theEvent.name().equals("MIDIinDevList") && inDeviceType == "ctrl") {
      MIDIInputDeviceID = (int)theEvent.group().value();
      if(ctrlIn != null){
        ctrlIn.closeMidi();
      }
      //syncIn = RWMidi.getInputDevices()[MIDIInputDeviceID].createInput();
      ctrlIn =  RWMidi.getInputDevices()[MIDIInputDeviceID].createInput();
      ctrlIn.plug(this, "processControlChange");
      ctrlIn.plug(this, "processProgramChange");
      ctrlIn.plug(this, "processTransposition");
      loadExternalControl();
      t11.setValue(RWMidi.getInputDevices()[MIDIInputDeviceID]+" for "+inDeviceType);
    }
    // camera selection
    if (theEvent.name().equals("CameraList")) { 
      //println("camera: "+(int)theEvent.controller().value());
      //try {
      video_on = false;
      video = new Capture(this, width, height,cameras[(int)theEvent.group().value()],15);
      t11.setValue(cameras[(int)theEvent.group().value()]+" selected.");
      // DELAY TWO SECONDS TO PREVENT EXCEPTION
      delay(2000);
      if(video.available()) {
        video_on = true;
        video_loaded = false;
        video_loop.stop();
      }
    }
  }
  if(theEvent.isController()) {
    //println("got a control event from controller with id "+theEvent.controller().id());
    // set the BPM
    if( theEvent.controller().id() == 1 ) {
      user_bpm = (int)theEvent.controller().value();
      int_preset[c_preset][0] = user_bpm;
      interval = 1000.0 / (user_bpm / 60.0);
    }
    // Set the note scale possibilities
    if ( theEvent.controller().id() >= 10 && theEvent.controller().id() < 22 ) {
      int index = theEvent.controller().id()-10;
      note_weights[index] = (int)theEvent.controller().value();
      np_preset[c_preset][index] = note_weights[index];
      nwsum = 0;
      for (int y=0; y < note_weights.length; y++) {
        nwsum += note_weights[y];
      } 
    }
    // Set the note duration possibilities
    if ( theEvent.controller().id() >= 30 && theEvent.controller().id() < 37 ) {
      int index = theEvent.controller().id()-30;
      dur_weights[index] = (int)theEvent.controller().value();
      dp_preset[c_preset][index] = dur_weights[index];
      wsum = 0;
      for (int y=0; y < dur_weights.length; y++) {
        wsum += dur_weights[y];
      } 
    }
    // Set dotted duration probability
    if ( theEvent.controller().id() == (30+d) ) {
      dot_prob = (int)theEvent.controller().value();
      int_preset[c_preset][5] = dot_prob;
    }
    // Set rest probability
    if ( theEvent.controller().id() == 83 ) {
      rest_prob = (int)theEvent.controller().value();
      int_preset[c_preset][9] = rest_prob;
    }
    // Set note randomness
    if ( theEvent.controller().id() == 50 ) {
      note_rand = (int)theEvent.controller().value();
      int_preset[c_preset][6] = note_rand;
    }
    // Set octave
    if ( theEvent.controller().id() == 51 ) {
      int n = int(theEvent.controller().value());
      setOctaveMin(n);
    }
    if ( theEvent.controller().id() == 52 ) {
      int n = int(theEvent.controller().value());
      setOctaveMax(n);
    }
    if ( theEvent.controller().id() == 53 ) {
      savePresetsFile();
    }
    if ( theEvent.controller().id() == 54 ) {
      loadPresetsFile();
    }
    if ( theEvent.controller().id() == 59 ) {
      loadVideoFile();
    }
    // Open up the camera settings
    if ( theEvent.controller().id() == 57 ) {
      // println("Yay buttons!");
      if (video != null) {
        video.settings();
      }
    }
    // Set the MIDI Out Channel
    if ( theEvent.controller().id() == 58 ) {
      midi_out = (int)theEvent.controller().value() - 1;
      int_preset[c_preset][4] = midi_out;
    }
    // Randomize note probs
    if ( theEvent.controller().id() == 80 ) {
      note_weights = randomizeProbabilities(note_weights);
      for (int i = 0; i < note_weights.length; ++i ) {
        controlP5.controller(key_pos[i]).setValue(note_weights[i]);
        np_preset[c_preset][i] = note_weights[i];
      }
    }
    // Randomize dur probs
    if ( theEvent.controller().id() == 81 ) {
      dur_weights = randomizeProbabilities(dur_weights);
      for (int i = 0; i < dur_weights.length; ++i ) {
        controlP5.controller(abbr_note_dur[i]).setValue(dur_weights[i]);
        dp_preset[c_preset][i] = dur_weights[i];
      }
    }
  }
}

void radioSync(int theID) {
  switch(theID) {
    case(55):
      // stop and kill int/ext sync threads
      setStartStop(false);
      if (syncIn != null) {
        syncIn.closeMidi();
        syncIn = null;
      } 
      external_sync = false;
      if (midi != null ) {
        midi.isActive = false;
        midi = null;
      }
      // Set up new MIDI Timing object
      midi = new MidiThread(user_bpm);
      midi.start();

      // setup durations as fractions of a whole note (1)
      nd = note_durations;
      midi.isActive = true; // activate the internal clock
      t11.setValue("Internal sync enabled.");
      break;  
    case(56):
      setStartStop(false);
      if (midi != null ) {
        midi.isActive = false;
        midi = null;
      }
      if (syncIn != null) {
        external_sync = true;
        //midi = new MidiThread(user_bpm);
        //midi.start();
        //midi.isActive = false;
        // setup durations in pulses
        nd = ext_note_durations;
        syncIn.plug(this, "processEvents");
        t11.setValue("External sync enabled.");
        break;
      }
      else {
        external_sync = false;
        midisync.deactivateAll();
        t11.setValue("Select a sync device before enabling external sync.");
        break;
      }
  }
  // println("A radio event. "+external_sync);
}

void radioMidiIn(int theID) {
  switch(theID) {
    case(78):
      inDeviceType = "sync";
      break;  
    case(79):
      inDeviceType = "ctrl";
      break;
  }
}

// SAVE PRESET FILE
void savePresetsFile() {
  FileDialog fd = new FileDialog(new Frame(),"Save Presets",FileDialog.SAVE);
  fd.setFile("*.gms");
  fd.setDirectory(".\\");
  // fd.setLocation(50, 50);
  // fd.show();
  fd.setVisible(true);
  String s = fd.getDirectory() + "/" + fd.getFile();
  if ( checkExtension(s,"gms")) {
    saveGMSSettings(s);
    t11.setValue("Presets saved: "+fd.getFile());
  }
  else {
    // println("bad filename");
    t11.setValue("Not saved. Preset files must end with .gms");
  } 
}

// LOAD PRESETS FILE
void loadPresetsFile() {
  FileDialog fd = new FileDialog(new Frame(),"Load Presets",FileDialog.LOAD);
  fd.setFile("*.gms");
  fd.setDirectory(".\\");
  // fd.setLocation(50, 50);
  //fd.show();
  fd.setVisible(true);
  String s = fd.getDirectory() + "/" + fd.getFile();
  if ( checkExtension(s,"gms")) {
    loadGMSSettings(s);
    t11.setValue("Presets loaded: "+fd.getFile());
  }
  else {
//  println("bad filename");
    t11.setValue("Not loaded. Preset files must end with .gms");
  }  
}

void loadVideoFile() {
  FileDialog fd = new FileDialog(new Frame(),"Load Presets",FileDialog.LOAD);
  fd.setFile("*.gms");
  fd.setDirectory(".\\");
  // fd.setLocation(50, 50);
  //fd.show();
  fd.setVisible(true);
  String s = fd.getDirectory() + "/" + fd.getFile();
  if ( checkExtension(s,"mov")) {
    video_loop = new Movie(this, s);
    video_loop.loop();
    // wait for movie to load???
    delay(2000);
    if( video_loop.available() ) {
      //video.stop();
      video_loaded = true;
      video_on = true;
      t11.setValue("Video loaded: "+fd.getFile());
    }
  }
  else {
    t11.setValue("Not loaded. Quicktime .mov files only");
  }
}

void radioPresets(int theID) {
  for(int i=61; i < 77; ++i) {
    if (theID == i) {
      println("Preset ID: "+theID);
      c_preset = theID-61;
      // reset note probs
      for(int p = 0; p < note_weights.length; ++p) {
        //println("NP p: "+p+" c_preset: "+c_preset);
        controlP5.controller(key_pos[p]).setValue(np_preset[c_preset][p]);
      }
      for(int p = 0; p < dur_weights.length; ++p) {
        //println("DP p: "+p+" c_preset: "+c_preset);
        controlP5.controller(abbr_note_dur[p]).setValue(dp_preset[c_preset][p]);
      }
    }  
  }
  // Set boolean preset values 
  sustain = tg_preset[c_preset][0];
  setSustain(-1);
  free_time = tg_preset[c_preset][1];
  setFreeStatus();
  dotted_note = tg_preset[c_preset][2];
  setDotted();
  dur_prob = tg_preset[c_preset][3];
  setDurationProbabilities();
  note_prob = tg_preset[c_preset][4];
  setNoteProbabilities();
  mirror_on = tg_preset[c_preset][5];
  // set integer preset values
  user_bpm = int_preset[c_preset][0]; // BPM
  setUserBPM();
  // println("415: radioPresets");  
  transposition = int_preset[c_preset][1]; // Transposition
  t7.setValue("Current Transposition: "+key_pos[transposition]);

  dur_key = int_preset[c_preset][2]; // Duration
  t6.setValue("Current Duration: "+dotted+note_dur_name[dur_key]);

  scale_key = int_preset[c_preset][3]; // Scale
  t8.setValue("Current Scale: "+scale_names[scale_key]);

  midi_out = int_preset[c_preset][4]; // MIDI Out Channel
  controlP5.controller("MIDI_OUT").setValue((float)midi_out+1);

  dot_prob = int_preset[c_preset][5]; // Dotted Probability
  controlP5.controller("Dot").setValue(dot_prob);

  note_rand = int_preset[c_preset][6]; // Randomness
  controlP5.controller(" ").setValue(note_rand);

  octave_min = int_preset[c_preset][7]; // Octave range min
  controlP5.controller("octave_min").setValue(octave_min);

  octave_max = int_preset[c_preset][8]; // Octave range max
  controlP5.controller("octave_max").setValue(octave_max);
  
  rest_prob = int_preset[c_preset][9]; // Rest Probability
  controlP5.controller("  ").setValue(rest_prob);

  // set note range based on octave min / max
  setNoteRange();
}

void setDefaultPresets() {
  for (int i = 0; i < 10; ++i ) {
    for(int p = 0; p < note_weights.length; ++p) {
      np_preset[i][p] = 50;
    }
    for(int p = 0; p < dur_weights.length; ++p) {
      dp_preset[i][p] = 50;
    }
    int_preset[i][0] = user_bpm;
    int_preset[i][2] = dur_key;
    int_preset[i][7] = octave_min;
    int_preset[i][8] = octave_max;
    tg_preset[i][5] = mirror_on;
  }
}

void saveGMSSettings(String filename) {
  int ln = 0;
  String[] lines = new String[350];
  for (int p = 0; p < 10; ++p) {
    // save note weights
    for (int i = 0; i < note_weights.length; i++) {
      lines[ln] = ln + "\t" + p + "\t" + i + "\t" + np_preset[p][i];
      ++ln;
    }
    // save duration weights
    for (int i = 0; i < dur_weights.length; i++) {
      lines[ln] = ln + "\t" + p + "\t" + i + "\t" + dp_preset[p][i];
      ++ln;
    }
    // save booleans
    lines[ln] = ln + "\t" + p + "\t" + tg_preset[p][0]; // sustain;
    lines[++ln] = ln + "\t" + p + "\t" + tg_preset[p][1]; // free_time
    lines[++ln] = ln + "\t" + p + "\t" + tg_preset[p][2]; // dotted_note
    lines[++ln] = ln + "\t" + p + "\t" + tg_preset[p][3]; // dur_prob
    lines[++ln] = ln + "\t" + p + "\t" + tg_preset[p][4]; // note_prob
    lines[++ln] = ln + "\t" + p + "\t" + tg_preset[p][5]; // mirror_on
    // save integer values
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][0]; // user_bpm
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][1]; // transposition
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][2]; // dur_key
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][3]; // scale_key
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][4]; // midi_out
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][5]; // dot_prob
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][6]; // note_rand
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][7]; // octave_min
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][8]; // octave_max
    lines[++ln] = ln + "\t" + p + "\t" + int_preset[p][9]; // rest_prob
    ++ln;
  }
  saveStrings(filename, lines);
  // sf.setValue(filename); /// THIS WAS DOING WEIRD SHIT
}

void loadGMSSettings( String filename ) {
  String[] lines;
  lines = loadStrings( filename );
  if (lines.length == 350) {
    int c = lines.length;
    println("c: "+c);
    int p = 0;
    int i = 0;
    for( int ln=0; ln < c; ++ln ) {
      println("ln: "+ln);
      String[] value = split(lines[ln], '\t');
      int pre = Integer.parseInt(value[1]);
      if ( i < 12 ) {
        println("v: "+value[2]+" pre: "+pre);
        np_preset[pre][i] = Integer.parseInt(value[3]);
      }
      else if ( i > 11 && i  < 19 ) {
        dp_preset[pre][i-12] = Integer.parseInt(value[3]);
      }
      // load booleans
      if ( i >  18 && i < 25 ) {
        tg_preset[pre][i-19] = boolean(value[2]);
      }
      // load ints
      if ( i >  24 && i < 35 ) {
        int_preset[pre][i-25] = Integer.parseInt(value[2]);
      }
      ++i;
      if (i > 35) {
        i = 0;
        --ln;
      }
    }
    // load preset 0 from the file into the UI controls
    // lf.setValue(filename); /// THIS WAS DOING WEIRD SHIT
    String pre = Integer.toString(0);
    presets.activate(pre);
    radioPresets(61);
  } 
  else {
//    println("File not valid: "+lines.length);
    //TODO: Put a file not found error someplace
  }
}

boolean checkExtension(String f, String e) {
  String parts[] = split(f, '.');
  if ( parts.length > 1 && parts[0].length() > 0 && parts[parts.length-1].equals(e) ) {
    return true;
  }
  else {
    return false;
  }
}

void setOctaveMax(int n) {
  if ( n >= octave_min && n > 0 && n < 11 ) {
    //println("n: " + n + " value: " + int(theEvent.controller().value()) );
    octave_max = n;
  }
  else if (n > 10) {
    octave_max = 10;
    //println("ELSE n: "+int(theEvent.controller().value())+" octave_max "+octave_max);
    // controlP5.controller("octave_max").setValue(10);      
  }
  else if (n < octave_min) {
    octave_max = octave_min;
    //println("ELSE n: "+int(theEvent.controller().value())+" octave_max "+octave_max);      
  }
  int_preset[c_preset][8] = octave_max;
  setNoteRange();
  controlP5.controller("octave_max").setValue(octave_max);
}

void setOctaveMin(int n) {
  if ( n <= octave_max && n > 0 && n < 11 ) {
    octave_min = n;
  }
  else if (n > octave_max) {
    octave_min = octave_max;          
  }
  else if (n < 1) {
    octave_min = 1;
  }
  int_preset[c_preset][7] = octave_min;
  setNoteRange();
  controlP5.controller("octave_min").setValue(octave_min);
}
