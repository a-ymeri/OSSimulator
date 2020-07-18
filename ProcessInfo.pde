class ProcessInfo {
  int baseAddress;
  int counter;
  int PID;
  int loadTime;
  int blockTime;
  int state;
  int size;
  color c;

  ProcessInfo(int ba, int s, int t) {
    baseAddress = ba;
    counter = 0;
    PID = id++;
    loadTime = t;
    state = NEW;
    blockTime = -1;
    size = s;
    c = color(random(100, 255), random(100, 255), random(100, 255));
  }

  String toString() {
    String s="";
    switch(state) {
    case 0: 
      s="  NEW  ";
      break;
    case 1: 
      s="RUNNING";
      break;
    case 2: 
      s=" READY ";
      break;
    case 3: 
      s="BLOCKED";
      break;
    default:
      s="EXITING";
    }
    return " "+PID+"   :    "+counter+"     :   "+s+"   :   "+blockTime;
  }
}
