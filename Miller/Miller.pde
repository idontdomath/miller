//miller
//Apache License Version 2.0, January 2004 (MIT) - see LICENSE for details

//experimentation on images variation and 

//Copyright (c) 2013 Martin Ramos Mejia
//Copyright (c) 2013 Mick Grierson, Matthew Yee-King, Marco Gillies for the Maxim Library.
//Based on ACassells work on SimpleWebCamInteraction
//Processing.js is licensed under the MIT License, see LICENSE.

//Resources:
//sinewave900hz.wav sample from freesound.org (http://www.freesound.org/people/mjscox/sounds/174407/)
//ACassells work on SimpleWebCamInteraction (https://github.com/ACassells/processing.js.SimpleWebCamInteraction)

var ctx;

//Frame comparison
PImage currentFrame;
PImage previousFrame;
final int cameraWidth = 960;
final int cameraHeight = 640;
final float colorChangeThreshold = 30.0;  // arbitrary threshold for frame variation. 

//Audio Control
Maxim maxim;
AudioPlayer player;
int playHead = 0;

//diff Controls
float maxDiff;
int diffCounter;

void setup() { 
  
  size(960, 640);
  ctx = externals.context;
  
  //tick control to replay audio in around 120 bpms
  frameRate(30);
  
  //audio init
  maxim = new Maxim(this);
  player = maxim.loadFile("sinewave900hz.wav");
  player.setLooping(true);
  
}


void computePixelVariation(color p1, color p2) {
  return abs(red(p1) - red(p2)) + abs( green(p1) - green(p2)) + abs(blue(p1) - blue(p2));
}

void draw() {
  
  if (!video.available) {
    //we need the camera to access the interaction
    return;
  }

  //playback control
  playHead ++;
  if (playHead % 15 == 0){
    player.cue(0);
    player.play();
  } 
  
  //we change the sample of the sine wave speed based on the differences between both images
  //so the speed is changed base on the presence or lack of movement
  //the result sound random sequencing based on the movement.
  float speedRatio = diffCounter / 1000;
  player.speed(speedRatio);
  
  //random filtering 
  player.setFilter(diffCounter/16 * maxDiff, maxDiff);

  //comparison of the two frame to build the actual differences
  previousFrame = currentFrame;  

  pushMatrix();
  translate(width, 0);
  scale(-1, 1); //black mirror
  //using video.js definition to gather the video.
  ctx.drawImage(video, 0, 0, cameraWidth, cameraHeight);  
  popMatrix();

  //we grab the current frame
  currentFrame=get(0, 0, cameraWidth, cameraHeight);

  //pixel's to wait are set to 0 when we start the frame comparisons
  int wait = 0;
  
  //all values set to zero
  maxDiff = 0.0;
  diffCounter = 0; 
  
  PImage motionDetectionImage = createImage(cameraWidth, cameraHeight, RGB);
  if (currentFrame != null && previousFrame != null) {    
    
    j = 0;
    
    for (int i = 0 ; i <  previousFrame.pixels.length; i++) {

      if (wait == 0) {
        //we can compare given we are not waiting
        color p1 = previousFrame.pixels[i];
        color p2 = currentFrame.pixels[i];

        float totalDiff =  computePixelVariation(p1,p2);
        
        //motion detection given threshold        
        if (totalDiff > colorChangeThreshold) {
          //we set a red pixel in the motion 
          motionDetectionImage.pixels[j] = color(153, 0, 0);
          //we count a difference between the two frames
          diffCounter++;
        } 
        else {
          //there is no difference set the pixel in black
          motionDetectionImage.pixels[j] = color(0);
        }
        
        //we update the maxDiff value if it's bigger to use it 
        //on the next update of the frame
        if (totalDiff > maxDiff) {
          maxDiff = totalDiff;
        } 
        //let's skip some pixels
        wait = 4;
      }
      else {
        //let's wait less pixels
        wait--;
      }
      
      j = j + 1;
      
    }
    //let's draw the image that displays the motion in the canvas.
    image(motionDetectionImage, 0, 0);
  }
}

