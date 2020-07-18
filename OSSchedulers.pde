class FCFS extends Routine {

  SOS os;

  FCFS(String c, String d, SOS os_) {
    super(c, d);
    os = os_;
  }

  void startRoutine() {
    os.interruptsEnabled = false;
    os.physicalAddress = baseAddress;
  }

  void endRoutine() {
    ProcessInfo found;
    if (os.queue.isEmpty()) os.runningProcess=null;
    else { 
      found = os.queue.get(0);
      for (ProcessInfo p : os.queue) {
        if (p.loadTime<found.loadTime) {
          found = p;
        }
      }
      found.state = RUNNING; //also updates it at the process table
      os.queue.remove(found);
      os.runningProcess=found;
    }
    os.interruptsEnabled = true;
  }
}
