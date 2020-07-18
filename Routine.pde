abstract class Routine {
  String code;
  int baseAddress;
  char command;
  String description;

  Routine(String c, String d) {
    code = c;
    description = d;
    command = c.charAt(code.length()-1);
  }

  Partition register(int ba) {
    for (int j=0; j<code.length(); j++) {
      os.PC.RAM[ba+j] = code.charAt(j);
    }
    return new Partition(ba, code.length());
  }
  
  abstract void startRoutine();

  abstract void endRoutine();
}
