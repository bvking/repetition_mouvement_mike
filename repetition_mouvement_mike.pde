int actualSec, lastSec, measure, measureToStartRecording;
boolean bRecording = false;
boolean mouseRecorded = true;
float movementInterpolated, angleToInterpolate;
int numberOfSample;

//--------------------        coordinates of an angle in radians // no need here

//--------------------        method of interpolation to return the position of (rotation) by adding modulo
float mlerp(float x0, float x1, float t, float M) {
  float dx = (x1 - x0 + 1.5 * M) % M - 0.5 * M;
  return (x0 + t * dx + M) % M;
}

class Sample {
  int t;
  float x, y;
  Sample(int t, float x, float y) {
    this.t = t;
    this.x = x;
    this.y = y;
  }
}

class Sampler {

  ArrayList<Sample> samples;
  ArrayList<Sample> samplesModified;
  int startTime;
  int playbackFrame;

  Sampler() {
    samples = new ArrayList<Sample>();
    samplesModified = new ArrayList<Sample>();
    startTime = 0;
  }
  void beginRecording() {
    samples = new ArrayList<Sample>();
    samplesModified = new ArrayList<Sample>();
    playbackFrame = 0;
  }
  void addSample(float x, float y) {  // add sample when bRecording
    int now = millis();
    if (samples.size() == 0) startTime = now;
    samples.add(new Sample(now - startTime, x, y));
  }
  int fullTime() {
    return (samples.size() > 1) ? samples.get(samples.size() - 1).t : 0;
  }
  void beginPlaying() {
    startTime = millis();
    playbackFrame = 0;
    println(samples.size(), "samples over", fullTime(), "milliseconds");
    if (samples.size() > 0) {
      numberOfSample = samples.size();

      float deltax = samples.get(0).x - samples.get(samples.size() - 1).x;
      float deltay = samples.get(0).y - samples.get(samples.size() - 1).y;
      float sumdist = 0;

      for (int i = 0; i < samples.size() - 1; i++) {
        sumdist += sqrt((samples.get(i).x - samples.get(i + 1).x) * (samples.get(i).x - samples.get(i + 1).x) + (samples.get(i).y - samples.get(i + 1).y) * (samples.get(i).y - samples.get(i + 1).y));
      }
      samplesModified.add(new Sample(samples.get(0).t, samples.get(0).x, samples.get(0).y));
      float dist = 0;
      for (int i = 0; i < samples.size() - 1; i++) {
        dist += sqrt((samples.get(i).x - samples.get(i + 1).x) * (samples.get(i).x - samples.get(i + 1).x) + (samples.get(i).y - samples.get(i + 1).y) * (samples.get(i).y - samples.get(i + 1).y));
        samplesModified.add(new Sample(samples.get(i + 1).t, (float)(samples.get(i + 1).x + (dist * deltax) / sumdist), (float)(samples.get(i + 1).y + (dist * deltay) / sumdist)));
        print(samples.get(i).x);
        print(",");
        print(samples.get(i).y);
        print(",");
        print(" good data x " + samplesModified.get(i).x);
        print(",");
        print(" good data y " + samplesModified.get(i).y);
        println("");
      }
    }
  }

  void draw() {
    stroke(255);
    //**RECORD
    beginShape(LINES);
    for (int i = 1; i < samples.size(); i++) {
      vertex(samplesModified.get(i - 1).x, samplesModified.get(i - 1).y);  // replace vertex with Pvector
      vertex(samplesModified.get(i).x, samplesModified.get(i).y);
    }
    endShape();
    //**ENDRECORD

    //**REPEAT
    int now = (millis() - startTime) % fullTime();
    if (now < samplesModified.get(playbackFrame).t) playbackFrame = 0;
    while (samplesModified.get(playbackFrame + 1).t < now)
      playbackFrame = (playbackFrame + 1) % (samples.size() - 1);
    Sample s0 = samplesModified.get(playbackFrame);
    Sample s1 = samplesModified.get(playbackFrame + 1);
    float t0 = s0.t;
    float t1 = s1.t;
    float dt = (now - t0) / (t1 - t0);

    //float x =lerp( s0.x, s1.x, dt );  // interpolation without modulo
    //float y =lerp( s0.y, s1.y, dt ); //

    float x = mlerp(s0.x, s1.x, dt, TWO_PI);  // interpolation with modulo, it's better
    float y = mlerp(s0.x, s1.x, dt, TWO_PI);

    movementInterpolated = y;
    text(" mov " + (movementInterpolated), 100, 500);
    fill(255, 255, 255);
    circle(100 * cos(movementInterpolated) + 200, 100 * sin(movementInterpolated) + 200, 20);
    stroke(255);
  }
}

Sampler sampler;

void setup() {
  size(800, 800, P3D);
  frameRate(30);  // when size is set as P3D (3 dimension) we have 27 or 28 frame (loop) per seconde
  sampler = new Sampler();
  mouseY = height / 2;
}

void draw() {
  background(50);
  for (int i = 0; i <= 8; i++) {
    stroke(2);
    line(0, height / 8 * i, width, height / 8 * i);  // horizon
    line(width / 8 * i, 0, width / 8 * i, height);   // vertical
  }
  textSize(20);
  //----------------------------------------
  angleToInterpolate = (float)map(mouseY, 0, 200, 0, TWO_PI) % TWO_PI;
  fill(100, 0, 0);
  circle(100 * cos(angleToInterpolate) + 200, 100 * sin(angleToInterpolate) + 200, 20);
  //----------------------------------------
  pushMatrix();
  translate(width / 2, height / 2);
  rotate(angleToInterpolate);
  translate(28, 0);
  rect(-30, -5, 60, 10);
  popMatrix();
  //----------------------------------------
  ellipse(width / 2, height / 2, 5, 5);
  text(" repeted  " + nf(movementInterpolated, 0, 2) + " original " + nf(angleToInterpolate, 0, 2), width / 2, height / 4);
  //  text( " repeted  " +nf (movementInterpolated, 0, 2) , 10, 0);
  textSize(20);
  /*
      for(int i = 0; i < samples.size() - 1; i++) {
       text (" angleModif " +    sampledModifiedChecking[i], 0, 100+ 20*i);
       text (" angleModif " + samplesModified.get(i).x, 100+ 20*i);
      }
    */

  if (actualSec != lastSec) {
    lastSec = actualSec;
    measure++;
  }

  text(measure, 100, 100);
  actualSec = (int)(millis() * 0.001);  //

  activeSampling();
  stopSampling();

  if (bRecording) {  // draw circle
                     //   circle( mouseX, mouseY, 10 );
                     //   sampler.addSample( mouseX, mouseY );
    textSize(100);
    fill(0, 255, 0);
    text(measure, 200, 100);
    sampler.addSample(angleToInterpolate, angleToInterpolate);
  }

  else {
    if (sampler.fullTime() > 0)
      sampler.draw();
  }

  if (numberOfSample > 0) {
    println(frameCount % numberOfSample + 1 + " " + movementInterpolated);
  }
}

void mousePressed() {
  bRecording = true;  // draw circle
  mouseRecorded = true;
  measure = 0;
}

void activeSampling() {
  if (measure == 0 && actualSec != lastSec && mouseRecorded == true) {
    textSize(100);
    fill(0, 255, 0);
    text(measure, 200, 100);
    sampler.beginRecording();
  }
}

void stopSampling() {
  if (measure == 2 && actualSec != lastSec) {
    textSize(100);

    fill(255, 0, 0);
    text(measure, 200, 100);
    mouseRecorded = false;
    //**REPEAT
    bRecording = false;
    sampler.beginPlaying();
  }
}
