#include "Adafruit_MLX90395.h"

Adafruit_MLX90395 sensor = Adafruit_MLX90395();

void setup(void)
{
  Serial.begin(115200);

  /* Wait for serial on USB platforms. */
  while (!Serial) {
      delay(10);
  }

//Serial.println("Starting Adafruit MLX90395 Demo");
  
  if (! sensor.begin_I2C()) {          // hardware I2C mode, can pass in address & alt Wire
    Serial.println("No sensor found ... check your wiring?");
    while (1) { delay(10); }
  }


  sensor.setOSR(MLX90395_OSR_8);
  sensor.setResolution(MLX90395_RES_17);

}

void loop(void) {
  int media_num = 100;
  float mx=0;
  float my=0;
  float mz=0;
  for (int i=0; i<media_num; i++){
    /* Get a new sensor event, normalized to uTesla */
    sensors_event_t event; 
    sensor.getEvent(&event);
    /* Display the results (magnetic field is measured in uTesla) */
    mx+=event.magnetic.x*0.01;
    my+=event.magnetic.y*0.01;
    mz+=event.magnetic.z*0.01;
  
    delay(0.7);
  }
  mx=mx/media_num;
  my=my/media_num;
  mz=mz/media_num;
  Serial.print(mx);Serial.print(", ");
  Serial.print(my);Serial.print(", ");
  Serial.println(mz); 
}
