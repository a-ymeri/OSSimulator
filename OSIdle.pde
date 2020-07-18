class Idle extends Routine{
  
  SOS os;
  
  Idle(String c, String d, SOS os_){
    super(c, d);
    os = os_;
  }
  
  void startRoutine(){
    os.interruptsEnabled = true;
    os.physicalAddress = baseAddress;
  }
  
  void endRoutine(){
    os.physicalAddress = baseAddress;
    os.interruptsEnabled = true;
  }
}
