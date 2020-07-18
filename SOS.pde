class SOS {
  Hardware PC;
  int physicalAddress;
  int currentAddress;
  Partition[] partitionTable;
  ArrayList<ProcessInfo>processTable;
  ArrayList<ProcessInfo> queue;
  ArrayList<Integer>requests;
  ProcessInfo runningProcess;
  ProcessInfo tempPI;
  int tempPartitionIndex;
  String tempProcess;
  String state; //text explining what is happening
  boolean interruptsEnabled;
  HashMap<String, Routine> kernel;

  SOS(Hardware h) {
    PC = h;
    requests = new ArrayList<Integer>();
    kernel = new HashMap<String, Routine>();
    kernel.put("Idle", new Idle("+1", "IDLE", this) );
    kernel.put("Scheduler", new FCFS("++2", "FCFS scheduler", this) );
    interruptsEnabled = true;
    state = kernel.get("Idle").description;

    //Set memory partitions
    //2 partitions for OS thother 6 for user processes (2+6=8)
    partitionTable = new Partition[8]; 

    //calculate the total code length of the os 
    int osCodeLength =0;
    for (Routine r : kernel.values()) {
      osCodeLength += r.code.length();
    }

    //calculate the partition size of the user partitions (equal)
    int partitionSize = (PC.RAM.length - osCodeLength) / (partitionTable.length-kernel.size());

    //create the OS partitions and load the os programs
    int b =0;
    b = loadOSRoutine(kernel.get("Idle"), b, 0);
    b = loadOSRoutine(kernel.get("Scheduler"), b, 1);

    //create the user partitions
    for (int i=kernel.size(); i<partitionTable.length; i++) {
      partitionTable[i] = new Partition(b, partitionSize);
      b += partitionSize;
    }

    //Set process Table
    processTable = new ArrayList<ProcessInfo>();
    queue = new ArrayList<ProcessInfo>();
    physicalAddress = kernel.get("Idle").baseAddress;
    currentAddress = physicalAddress;
    runningProcess=null;
  }//END OF CONSTRUCTOR

  int loadOSRoutine(Routine r, int ba, int partitionIndex) {
    r.baseAddress = ba;
    partitionTable[partitionIndex] = new Partition(ba, r.code.length());
    for (int j=0; j<r.code.length(); j++) {
      PC.RAM[ba+j] = r.code.charAt(j);
    }
    partitionTable[partitionIndex].isFree=false;
    return ba+r.code.length();
  }


  void loadProgram(int p) {
    if (interruptsEnabled) {
      if (runningProcess != null) {
        runningProcess.state = READY;
        queue.add(runningProcess);
        runningProcess=null;
      }
      tempProcess = PC.HDD.get(p)+"hhhsss";
      int pindex = runMemoryManager(tempProcess.length());
      if (pindex != -1) {
        tempPI = createProcess(pindex, tempProcess);  
        admitProcess(tempPI);
      }
    } else {
      requests.add(p);
    }
  }  

  int runMemoryManager(int requestedSize) {
    int result =-1; //-1 did not find a partition
    for (int i=0; i<partitionTable.length; i++) {
      if (partitionTable[i].isFree && partitionTable[i].size>=requestedSize) { 
        result = i;
        break;
      }
    }
    return result;
  }

  ProcessInfo createProcess(int i, String p) {
    ProcessInfo pi = new ProcessInfo(partitionTable[i].baseAddress, p.length(), PC.clock);
    processTable.add(pi);
    for (int j=0; j<p.length(); j++) {
      PC.RAM[j+partitionTable[i].baseAddress] = p.charAt(j);
    }  
    partitionTable[i].isFree = false; 
    return pi;
  }

  void admitProcess(ProcessInfo p) {
    if (p!=null) {
      p.state = READY;
      queue.add(p);
      if (runningProcess==null) {
        kernel.get("Scheduler").startRoutine();
      }
    }
  }
  
  void deleteProcess(ProcessInfo pi) {
    pi.state = EXITING;

    //Find the partition
    for (int i=0; i<partitionTable.length; i++) {
      if (partitionTable[i].baseAddress == pi.baseAddress) {
        //delete data from that partition
        for (int j=0; j<partitionTable[i].size; j++) {
          PC.RAM[j+pi.baseAddress] = '_';
        }  
        //Set partition as free
        partitionTable[i].isFree=true;
        //delete the process from the process table
        processTable.remove(pi);
        break;
      }
    }
  }


  void step() {
    if (interruptsEnabled && !requests.isEmpty()) {
      if (runningProcess != null) {
        runningProcess.state = READY;
        queue.add(runningProcess);
        runningProcess=null;
      }
      loadProgram(requests.get(0));
      requests.remove(0);
    }
    currentAddress = physicalAddress;
    println("curr address is "+currentAddress);
    PC.fetchInstruction(currentAddress);
    char c = PC.executeInstruction();
    println("fetched "+c);
    if (c=='*') {
      state="Executing user process "+runningProcess.PID;
      runningProcess.counter++;
      physicalAddress = runningProcess.baseAddress+runningProcess.counter;
    } else if (c=='$') {
      state="Exiting user process "+runningProcess.PID;
      runningProcess.state = EXITING;
      deleteProcess(runningProcess);
      kernel.get("Scheduler").startRoutine();
    } else if ( c=='@') {
      runningProcess.counter++;
      //physicalAddress = runningProcess.baseAddress+runningProcess.counter;
      state="Blocking user process "+runningProcess.PID;
      runningProcess.state = BLOCKED;
      runningProcess.blockTime = PC.clock;
      runningProcess = null;
      kernel.get("Scheduler").startRoutine();
    } else if (c=='+') {
      physicalAddress++;
    } else if (c==kernel.get("Idle").command) {
      state=kernel.get("Idle").description;
      kernel.get("Idle").endRoutine();
    } else if (c==kernel.get("Scheduler").command) {
      kernel.get("Scheduler").endRoutine();
      if (runningProcess!=null) {
        physicalAddress = runningProcess.baseAddress+runningProcess.counter;
        state="Finished scheduling. Selected user process "+runningProcess.PID;
      } else {
        state="Finished scheduling. No user process found. Going to idle";
        kernel.get("Idle").startRoutine();
      }
    }
  }

}
