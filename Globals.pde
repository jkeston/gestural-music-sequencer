//////// Global Variables ////////

//// Initiate MidiOutput, MidiInput, video Capture, UI, and Timing objects ////
XMLElement extCrtlXML;
MidiOutput output;
MidiInput syncIn,ctrlIn;
Capture video;
Movie video_loop;
ControlP5 controlP5;
Radio presets,midisync,midiIn;
MidiThread midi;
FullScreen fs;
SoftFullScreen sfs;

Textlabel t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12;
// Textfield sf,lf,lvf;
PImage logo;

//// Global integer variables ////
int sf_activity, lf_activity, pbX,pbY,transposition,previous_note,d,dot_prob,rest_prob = 0;
int note_rand,brightestX,brightestY,durPC = 0;
int valid,noteValue,octave,scale_pos,velocity,the_note,MIDIDeviceID,MIDIInputDeviceID,c_preset,CameraList;
int[] dur_weights = {50,50,50,50,50,50,50};
int[] note_weights = {50,50,50,50,50,50,50,50,50,50,50,50};
int wsum = 350;
int nwsum = 600;
int midi_out = 0;
int MIDI_OUT = midi_out;
int previous_midi_out = midi_out;
int octave_min = 1;
int octave_max = 10;
int OCTAVES = octave_max;
int note_range_min = 1;
int note_range_max = 127;
int pulseStart = 1;
int pulseCount = pulseStart;
int pulses_per_quarter = 48;
// Set up scale matrix
int[][] scales = { {  0, 3, 5, 7, 10 }, // Pentatonic
                   { 0, 2, 4, 6, 8, 10 }, // Wholetone
                   { 0, 2, 4, 5, 7, 9, 11 }, // Major
                   { 0, 2, 3, 5, 7, 8, 10 }, // Minor
                   { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 } }; // Chromatic

// preset matrix for note probs and dur probs and booleans
int[][] np_preset = new int[10][12];
int[][] dp_preset = new int[10][7];
int[][] int_preset = new int[10][21];
boolean[][] tg_preset = new boolean[10][6];

// Default scale is 0 (pentatonic), and dur_key is 2 (1/4 note)
int scale_key = 0;
int previous_scale_key = scale_key;
int dur_key = 2;
int previous_dur_key = dur_key;
int max_bpm = 999;
int min_bpm = 20;
int user_bpm = 120;
int BPM = user_bpm;

//// Global boolean variables ////
boolean free_time = false;
boolean dotted_note = false;
boolean sustain = false;
boolean box_on = true;
boolean playing = false;
boolean dur_prob = false;
boolean note_prob = false;
boolean video_on = false;
boolean logo_on = true;
boolean mirror_on = true;
boolean external_sync = false;
boolean fsm = false;
boolean sfsm = false;
boolean video_loaded = false;
boolean init_start = false;
boolean filter_on[] = {false,false,false,false};

//// Global String and char variables ////
String gms_version = "v0.11";
String dotted = "";
String filter_names[] = {"GRAY","INVERT","POSTERIZE","THRESHOLD"};
String filter_keys[] = {"!","@","#","$"};
String play_status = "stopped";
String sus_status = "off";
String dur_prob_status = "OFF";
String note_prob_status = "OFF";
String free_status = "bpm";
String inDeviceType = "sync";
String preset_file = "presets.gms";
// String[] cameras = Capture.list();
String[] cameras = {""};


String scale_names[] = {"Pentatonic Minor","Whole Tone","Major","Minor","Chromatic"};
String note_dur_name[] = {"Whole Note","Half Note", "Quarter Note","Eighth Note",
                          "Sixteenth Note","Thirty Second Note","Sixty Fourth Note" };
String abbr_note_dur[] = {"1","1/2","1/4","1/8","1/16","1/32","1/64"};
String key_pos[] = { "C","C#","D","D#","E","F","F#","G","G#","A","A#","B" };
char piano_key[] = { 'q','2','w','3','e','r','5','t','6','y','7','u' };
char duration_key[] = { 'z','x','c','v','b','n','m' };
char scales_key[] = { 'g','h','j','k','l' };

//// Global float and double variables ////
double user_int,interval;
float user_dur;
float multiplier = 1;
float avg_brightness,ft_calib = 0;
float note_durations[] = { 4.0,2.0,1.0,0.5,0.25,0.125,0.0625 };
//float ext_note_durations[] = {96,48,24,12,6,3}; // for pulses_per_quarter = 24
float ext_note_durations[] = {192,96,48,24,12,6,3}; // for pulses_per_quarter = 48
//float ext_note_durations[] = {384,192,96,48,24,12,6}; // for pulses_per_quarter = 96
float[] nd = note_durations;

int[] processVideoInput() {
  video.read();

  // flip the video image to create a mirror image when enabled
  if (mirror_on) {
    pushMatrix();
    scale(-1.0, 1.0);
    image(video,-video.width,0);
    popMatrix();
  }
  else {
    image(video, 0, 0, width, height);
  }
  int bX = 0;
  int bY = 0;
  float brightestValue = 0; // Brightness of the brightest video pixel

  // Search for the brightest pixel: For each row of pixels in the video image and
  // for each pixel in the yth row, compute each pixel's index in the video
  video.loadPixels();
  int index = 0;
  float sum_brightness = 0;
  for (int y = 0; y < video.height; y++) {
    for (int x = 0; x < video.width; x++) {
      // Get the color stored in the pixel
      int pixelValue = video.pixels[index];
      // Determine the brightness of the pixel
      float pixelBrightness = brightness(pixelValue);
      sum_brightness += pixelBrightness;
      // If that value is brighter than any previous, then store the
      // brightness of that pixel, as well as its (x,y) location
      if (pixelBrightness > brightestValue) {
        brightestValue = pixelBrightness;
        bY = y;
        bX = x;
      }
      index++;
    }
    avg_brightness = sum_brightness / (video.height * video.width);
  }
  int[] bxy = {bX,bY};
  return bxy;
}

int[] processVideoLoop() {
  video_loop.read();
  
  // flip the video image to create a mirror image when enabled
  if (mirror_on) {
    pushMatrix();
    scale(-1.0, 1.0);
    image(video_loop,-width,0,width,height);
    popMatrix();
  }
  else {
    image(video_loop, 0, 0, width, height);
  }  
  int bX = 0;
  int bY = 0;
  float brightestValue = 0; // Brightness of the brightest video pixel

  // Search for the brightest pixel: For each row of pixels in the video image and
  // for each pixel in the yth row, compute each pixel's index in the video
  video_loop.loadPixels();
  int index = 0;
  float sum_brightness = 0;
  for (int y = 0; y < video_loop.height; y++) {
    for (int x = 0; x < video_loop.width; x++) {
      // Get the color stored in the pixel
      int pixelValue = video_loop.pixels[index];
      // Determine the brightness of the pixel
      float pixelBrightness = brightness(pixelValue);
      sum_brightness += pixelBrightness;
      // If that value is brighter than any previous, then store the
      // brightness of that pixel, as well as its (x,y) location
      if (pixelBrightness > brightestValue) {
        brightestValue = pixelBrightness;
        bY = y;
        bX = x;
      }
      index++;
    }
    avg_brightness = sum_brightness / (video_loop.height * video_loop.width);
  }
  int[] bxy = {bX,bY};
  return bxy;
}

void filterVideo() {
  // TODO: Add filtering controls 
  // http://processing.org/reference/filter_.html
  if (filter_on[0]) {
    filter(GRAY);
  }
  if (filter_on[1]) {
    filter(INVERT);
  }
  if (filter_on[2]) {
    filter(POSTERIZE,3);
  }
  if (filter_on[3]) {
    filter(THRESHOLD);
  }
}
