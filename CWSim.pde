Hardware myPC;
SOS os;
int id=0;
int simSpeed;

int RAMsizeInBank = 64;
int RAMBanks = 4;
int rectW;

static final int SIMRUN=0;
static final int SIMPAUSE=1;
int simState;
int simStep;
static final int BLOCKTIME = 10;
ArrayList<Request> user;

//Process States
static final int NEW     = 0;
static final int RUNNING = 1;
static final int READY   = 2;
static final int BLOCKED = 3;
static final int EXITING = 4;

////////////////////////////////////////////////////////////
// setup, draw and keypressed functions
////////////////////////////////////////////////////////////
void setup() {
  size(900, 350);
  simState = SIMRUN;
  simStep = 0;
  surface.setLocation(3042-width, -175); //Do not write the code in this line
  myPC = new Hardware(RAMsizeInBank*RAMBanks);
  os = new SOS(myPC);
  simSpeed = 20;
  frameRate(30);
  user = new ArrayList<Request>();
  user.add(new Request(2, -1));
  user.add(new Request(5, -3));
  user.add(new Request(12, -2));
  user.add(new Request(14, -1));
  user.add(new Request(21, -3));
  user.add(new Request(24, -2));
  user.add(new Request(37, -1));
  user.add(new Request(56, -3));
  user.add(new Request(62, -1));
  user.add(new Request(68, -2));
  user.add(new Request(78, -3));
  user.add(new Request(86, -2));
  user.add(new Request(94, -2));
  user.add(new Request(96, -1));
  user.add(new Request(102, -3));
  user.add(new Request(112, -2));
  user.add(new Request(124, -3));
  user.add(new Request(132, -1));
}

void draw() {
  background(128);
  if (simStep % simSpeed == 0 && simState == SIMRUN) {
    runSimStep();
  }
  if (simState == SIMRUN) {
    simStep++;
  }
  drawPartitions(10, 10, width-10);
  drawRAM(10, 10, width-10);
  drawProcessTable(0, 150, 18);
  drawCPU(width/2-50, 150);
  drawQueue(600, 150);
  drawClock(width-100, 200);
  drawSystemState(0, height-20);
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      simSpeed -=5; //increases speed
    } else if (keyCode == DOWN) {
      simSpeed +=5; //decreases speed
    }
    simSpeed = constrain(simSpeed, 1, 3*int(frameRate));
  } else if (key == '1') {
    os.loadProgram(-1);
  } else if (key =='2') {
    os.loadProgram(-2);
  } else if (key =='3') {
    os.loadProgram(-3);
  } else if (key =='X' || key =='x') {
    exit();
  } else if (key =='P' || key =='p') {
    if (simState == SIMRUN) simState = SIMPAUSE;
    else simState = SIMRUN;
  } else if (key =='s' || key =='S') {
    if (simState == SIMPAUSE) {
      runSimStep();
    }
  }
}

////////////////////////////////////////////////////////////
//OTHER SUPPORTING FUNCTIONS
////////////////////////////////////////////////////////////
void runSimStep(){
  myPC.clock++;
    //checkRequests(); //Uncomment this line if you want to use the user requests
    checkForUnblocking();
    os.step();  
}

void checkRequests() {
  if (!user.isEmpty()) {
    if (myPC.clock >= user.get(0).time) {
      os.loadProgram(user.get(0).program);
      user.remove(0);
    }
  }
}

void checkForUnblocking() {
  for (ProcessInfo p : os.processTable) {
    if (p.state==BLOCKED) {
      if (p.blockTime+BLOCKTIME==myPC.clock) {
        p.state = READY;
        os.queue.add(p);
        if (os.runningProcess==null) {
          os.kernel.get("Scheduler").startRoutine();
        }
      }
    }
  }
}

////////////////////////////////////////////////////////////
//DRAWING SUPPORT FUNCTIONS
////////////////////////////////////////////////////////////
void drawRAM(int x, int y, int w) {
  pushMatrix();
  translate(x, y);
  rectW = (w / RAMsizeInBank);
  textSize(rectW*0.65);
  stroke(0);
  for (int j=0; j<RAMBanks; j++) {
    for (int i=0; i<RAMsizeInBank; i++) {
      if (myPC.RAM[i+j*RAMsizeInBank]=='_')
        fill(255);
      else {
        fill(getColor(i+j*RAMsizeInBank));
      }
      rect(i*rectW, rectW+j*rectW*2, rectW, rectW); 
      fill(0);
      text(myPC.RAM[i+j*RAMsizeInBank], i*rectW+rectW*0.4, rectW+j*rectW*2+rectW*0.8);
    }
  }
  fill(0);
  int col = os.currentAddress % RAMsizeInBank;
  int row = os.currentAddress / RAMsizeInBank;
  int PpositionX = col*rectW ;
  int PpositionY = rectW*2 + row*rectW*2;
  pushMatrix();
  translate(PpositionX, PpositionY);
  triangle(rectW/2, 0, 0, rectW, rectW, rectW);
  popMatrix();
  popMatrix();
}

void drawPartitions(int x, int y, int w) {
  color[] c = new color[2];
  c[0] = color(180);
  c[1] = color(100);
  pushMatrix();
  translate(x, y);
  strokeWeight(1);
  stroke(0);
  rectW = (w / RAMsizeInBank);
  int row;
  int col;
  int px;
  int py;
  int pw;
  int pLengthLeft;
  for (int i=0; i<os.partitionTable.length; i++) {
    fill(c[i%2]); 
    col = os.partitionTable[i].baseAddress % RAMsizeInBank;
    row = os.partitionTable[i].baseAddress / RAMsizeInBank;
    pLengthLeft = os.partitionTable[i].size;
    while (pLengthLeft > RAMsizeInBank-col) {
      pw = (RAMsizeInBank - col)*rectW;
      px = col*rectW;
      py = -2 + row*rectW*2+rectW;
      rect(px, py, pw, rectW+4);
      pLengthLeft = pLengthLeft - (RAMsizeInBank-col);
      col = 0;
      row++;
    }
    px = col*rectW;
    py = -2 + row*rectW*2+rectW;
    pw = pLengthLeft * rectW;
    rect(px, py, pw, rectW+4);
  }
  popMatrix();
}

void drawProcessTable(int x, int y, int txtsize) {
  fill(0);
  textSize(txtsize);
  text("Process table", x, y);
  text("PID : counter :    state    : blocked", x, y+txtsize);
  for (int i=0; i<os.processTable.size(); i++) {
    fill(os.processTable.get(i).c);
    text(os.processTable.get(i).toString(), x, y+(i+2)*txtsize);
  }
}

void drawCPU(int x, int y) {
  stroke(0);
  strokeWeight(5);
  fill(255);
  rect(x, y, 100, 100);
  if (os.runningProcess == null) {
    fill(255);
  } else {
    fill(os.runningProcess.c);
  }
  strokeWeight(1);
  rect(x+16, y+16, 68, 68, 7);
  fill(0);
  pushStyle();
  textSize(50);
  textAlign(CENTER, CENTER);
  text(myPC.executeInstruction(), x+50, y+50);
  popStyle();
  triangle(x+5, y+85, x+5, y+95, x+15, y+95);
  pushStyle();
  textAlign(CENTER, CENTER);
  textSize(10);
  strokeWeight(5);
  if (os.interruptsEnabled) {
    fill(#31C106); 
    rect(x, y+100, 100, 40);
    fill(0);
    text("Interrupts Enabled", x+50, y+120);
  } else {
    fill(#F51E3E);
    rect(x, y+100, 100, 40);
    fill(0);
    text("Interrupts Disabled", x+50, y+120);
  }
  popStyle();
}

void drawQueue(int x, int y) {
  text("Scheduler Queue", x, y);
  for (int i=0; i<os.queue.size(); i++) {
    stroke(0);
    fill(os.queue.get(i).c);
    rect(x, y+i*20+12, 100, 20);
    fill(255);
    int p=int(map(os.queue.get(i).counter, 0, os.queue.get(i).size, x, x+100)); 
    line(p, y+i*20+12, p, y+(i+1)*20+12);
  }
}

void drawClock(int x, int y) {
  stroke(0);
  fill(0, 255, 0);
  float inc = (simStep % simSpeed)*TWO_PI/simSpeed;
  arc(x, y, 50, 50, -HALF_PI, -HALF_PI+inc, PIE);
  pushStyle();
  textSize(20);
  fill(0);
  textAlign(CENTER, CENTER);
  text(myPC.clock, x, y);
  popStyle();
}

void drawSystemState(int x, int y) {
  fill(0);
  textSize(16);
  text(os.state, x, y);
}

color getColor(int p) {
  color c = color(255);  
  for (ProcessInfo pi : os.processTable) {
    if (p>=pi.baseAddress && p < pi.baseAddress+pi.size) {
      c = pi.c;
    }
  }
  return c;
}
