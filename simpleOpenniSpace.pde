
import saito.objloader.*;

import SimpleOpenNI.*;

OBJModel model;
float rotX3d, rotY3d;
 
SimpleOpenNI context;
float        zoomF =0.3f;
float        rotX = 0;//radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = 0;//radians(0);
int user;
color[] userColors = {color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,0),color(255,0,255),color(0,255,255)};
boolean playRecording=false;
ArrayList<PVector> userData = new ArrayList<PVector>();

PMatrix3D sm = new PMatrix3D(); //sensor matrix = where the sensor will be in real space

void setup(){
  size(1024,768,P3D);
  
    model = new OBJModel(this, "corridor.obj", "absolute", TRIANGLES);
    model.enableDebug();

    model.scale(20);
    model.translateToCenter();

    stroke(255);
    noStroke();

 
  
  textFont(createFont("Arial",48));
  
  //add sensor measurements here
  sm.translate(870,890,750);
  sm.rotateX(radians(15));
  
  context = new SimpleOpenNI(this);
  
  if(playRecording == true){
      
    // playing, this works without the camera
    if ( context.openFileRecording("test.oni") == false)
    {
      println("can't find recording !!!!");
      exit();
    }

    // it's possible to run the sceneAnalyzer over the recorded data strea   
    if ( context.enableScene() == false)
    {
      println("can't setup scene!!!!");
      exit();
      return;
    }
    
    println("This file has " + context.framesPlayer() + " frames.");
  
  }
  //else{
  
    context.enableRGB();
    context.alternativeViewPointDepthToImage();//aligns depth with rgb streams
    context.enableDepth();
    context.setMirror(false);
    context.enableScene();
    context.enableUser(SimpleOpenNI.SKEL_PROFILE_NONE);//enable user events, but no skeleton tracking, needed for the CoM functionality    
  //}

  stroke(255);
  smooth();
  perspective(radians(45),float(width)/float(height),10,150000);
}
 
void draw()
{
  context.update();//update kinect
  //clear and do scene transformation(translation,rotation,scale)
  background(0,0,0);
  lights();
  
  pushMatrix();//3D
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  
 
  int[]   depthMap = context.depthMap();//640*480 long array of ints from 0-2047
  int[]   sceneMap = context.sceneMap();//640*480 long array of ints, 0 is bg, 1 is user 1, 2 is user 2, etc.
  PImage  rgbImage = context.rgbImage();
  PVector[] realWorldMap = context.depthMapRealWorld();//convert raw depth values to real world 3D positions in space 
  PVector realWorldPoint;//we'll reuse this PVector when converting raw depth values to 3D position
  int     steps   = 3; 
  int     index   = 0;
  translate(0,0,-1000);  // set the rotation center of the scene 1000 in front of the camera
  
  userData.clear(); 
  beginShape(POINTS);
  for(int y=0;y < context.depthHeight();y+=steps)
  {
    for(int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = realWorldMap[index];
        stroke(rgbImage.pixels[index]);      
        int userPixel = sceneMap[index]; 
        if(userPixel > 0) {
          stroke(userColors[userPixel%userColors.length]);
          PVector ud;
          if(userData.size() >= userPixel) ud = userData.get(userPixel-1);
          else{
            ud = new PVector(Float.MAX_VALUE,0,-1);//hacky way to store data: x = minY,y = maxY, z = maxY-minY
            userData.add(ud);
          }
          if(realWorldPoint.y < ud.x) ud.x = realWorldPoint.y;
          if(realWorldPoint.y > ud.y) ud.y = realWorldPoint.y;
          ud.z = ud.y - ud.x;
        }
        //vertex(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
        PVector transformed = realWorldPoint.get();
        sm.mult(transformed,transformed);
        vertex(transformed.x,transformed.y,transformed.z);
      }
    } 
  } 
  endShape();
  
  pushMatrix();//3D
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
   model.draw();  
    
  translate(870,890,750);
  rotateX(radians(15));
    
  
  


 
  context.drawCamFrustum();
  popMatrix();
  
  int[] users = context.getUsers();
  for(int i = 0 ; i < users.length; i++){
    PVector com = new PVector();
    context.getCoM(users[i],com);
    //draw center of mass
    pushMatrix();
    translate(com.x,com.y,com.z);
    box(10);
    popMatrix();
    PVector ud;
    if(userData.size() >= users[i]) {
      ud = userData.get(users[i]-1);
      
      line(com.x,ud.x,com.z,com.x,ud.y,com.z);
      pushMatrix();
      translate(com.x,com.y,com.z);
      rotateX(PI);
      text("height: "+(ud.y-ud.x),0,0,0);
      popMatrix();
    }
  }
  
  // draw the kinect cam
  //context.drawCamFrustum();
  popMatrix();
  pushMatrix();//2D
  //image(context.sceneImage(),0,0,320,240);
  popMatrix();
  


  
    pushMatrix();
    translate(width/2, height/2, 0);
    //rotateX(rotY3d);
    //rotateY(rotX3d);

  //  model.draw();

    popMatrix();
 model.disableTexture();
            noStroke();
  model.shapeMode(TRIANGLES);
  
  
      if(key == '+') {
          zoomF+=0.2;
        } 
        else  if(key == '-') {
          zoomF-=0.2;
        }
   

  
}


void mouseDragged()
{
    rotX += (mouseX - pmouseX) * 0.01;
    rotY -= (mouseY - pmouseY) * 0.01;
}



