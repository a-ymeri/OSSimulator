class Partition {
  int baseAddress;
  int size;
  boolean isFree;

  Partition(int ba, int s) {
    baseAddress = ba;
    size = s;
    isFree = true;
  }
}
