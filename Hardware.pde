public class Hardware {

  //CPU
  char CPU;
  //RAM
  char[] RAM;
  //HDD
  HashMap<Integer, String> HDD;
  //clock
  int clock;

  Hardware(int RAMsize) {
    RAM = new char[RAMsize];
    HDD = new HashMap<Integer, String>();
    mountHDD();
    RAMinit();
  }

  void RAMinit(){
    for(int i=0; i<RAM.length; i++){
      RAM[i]='_';  
    }
  }

  void mountHDD(){
    HDD.put(-1, new String("****@****$dddddddd"));
    HDD.put(-2, new String("*@***$ddd"));
    HDD.put(-3, new String("****@*****@*******$ddddddd"));
  }
  
  char executeInstruction(){
    return CPU;
  }
  
  void fetchInstruction(int address){
    CPU = RAM[address];
  }
}
