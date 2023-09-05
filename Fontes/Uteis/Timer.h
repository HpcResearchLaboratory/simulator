#ifndef __TIMER__
#define __TIMER__

struct Timer {
  
  private:
  
  cudaEvent_t begin, end;
  float parcial, total;
  
  public:
  
  Timer();
  void start();
  void stop();
  double getTime();
  
};

#endif
