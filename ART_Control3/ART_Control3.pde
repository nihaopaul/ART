#include <Ultrasonic.h>
#include <Servo.h> 
#include <limits.h>

// various directions we can go to
const int FORWARD =  2;      // the number of the LED pin
const int REVERSE =  3;  
const int LEFT = 4;  
const int RIGHT =  5;  

// Arduino pins mapping
const int SENSOR_SERVO = 11;
const int ULTRASONIC_TRIG = 8;
const int ULTRASONIC_ECHO = 9;

/*
We're sweeping the servo either left or right
DFR15 METAL GEAR SERVO
Voltage: +4.8-7.2V
Current: 180mA(4.8V)；220mA（6V）
Speed(no load)：0.17 s/60 degree (4.8V);0.25 s/60 degree (6.0V)
Torque：10Kg·cm(4.8V) 12KG·cm(6V) 15KG·cm(7.2V)
Temperature:0-60 Celcius degree
Size：40.2 x 20.2 x 43.2mm
Weight：48g
*/
const int SERVO_TURN_RATE_PER_SECOND = 300; // 60/(0.2*3) where 3 is caused by load?

/* 
HC-SR04 Ultrasonic sensor
effectual angle: <15°
ranging distance : 2cm – 500 cm
resolution : 0.3 cm
*/
const int SENSOR_LOOKING_FORWARD_ANGLE = 90; 
// rotating counterclockwise...
const int SENSOR_LOOKING_LEFT_ANGLE = 135; 
const int SENSOR_LOOKING_RIGHT_ANGLE = 45; 
const int SENSOR_ARC_DEGREES = 15; // 180, 90, 15 all divisible by 15
const int MAXIMUM_SENSOR_SERVO_ANGLE = 180;
const int MINIMUM_SENSOR_SERVO_ANGLE = 1;
const int NUMBER_READINGS = MAXIMUM_SENSOR_SERVO_ANGLE/SENSOR_ARC_DEGREES; // 180/15 = 12 reading values in front
const int SENSOR_LOOKING_FORWARD_READING_INDEX = SENSOR_LOOKING_FORWARD_ANGLE/SENSOR_ARC_DEGREES; // 90/15 = 6
const int SENSOR_PRECISION_CM = 1;
// speed of sound at sea level = 340.29 m / s
// spec range is 5m * 2 (return) = 10m
// 10 / 341 = ~0.029
const int SENSOR_MINIMAL_WAIT_ECHO_MILLIS = 29;

/*
Robot related information
*/
const int ROBOT_TURN_RATE_PER_SECOND = 90;
const int SAFE_DISTANCE = 50;
const int CRITICAL_DISTANCE = 20;
enum states {
  INITIAL = 'I',
  SWEEPING = 'S',
  GO = 'G',
  DECISION = 'D',
  STUCK = 'K',
  TURN = 'T',
};

// Global variable
// this contains readings from a sweep
int sensor_distance_readings_cm[NUMBER_READINGS];
const int NO_READING = -1;
// we start with a sweep
char current_state = SWEEPING;
// contains target angle
int turn_towards;

enum {
  WAIT_FOR_SERVO_TO_TURN,
  WAIT_FOR_ROBOT_TO_TURN,
  WAIT_FOR_ECHO,
  WAIT_ARRAY_SIZE
};

int timed_operation_initiated_millis[WAIT_ARRAY_SIZE];
int timed_operation_desired_wait_millis[WAIT_ARRAY_SIZE];

// variables to store the servo current and desired angle 
int current_sensor_servo_angle = 0;

// Two useful objects...
Servo sensor_servo;  // create servo object to control a servo 
Ultrasonic sensor = Ultrasonic(ULTRASONIC_TRIG, ULTRASONIC_ECHO);

void setup() { 
  // these map to the contact switches on the RF
  pinMode(FORWARD, OUTPUT);     
  pinMode(REVERSE, OUTPUT);    
  pinMode(LEFT, OUTPUT);  
  pinMode(RIGHT, OUTPUT);  
  full_stop();
  sensor_servo.attach(SENSOR_SERVO);
  for(int i=0; i<WAIT_ARRAY_SIZE; i++) {
    timed_operation_initiated_millis[i] = 0;  
    timed_operation_desired_wait_millis[i] = 0;
  }
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);   
  Serial.begin(9600);
}

/*
Makes sure that exclusive directions are prohibited
*/
void go(int dir) {
  switch(dir) {
  case FORWARD:
    digitalWrite(REVERSE, LOW);
    digitalWrite(FORWARD, HIGH);   
    break;
  case REVERSE:
    digitalWrite(FORWARD, LOW);   
    digitalWrite(REVERSE, HIGH);   
    break;  
  case LEFT:
    digitalWrite(RIGHT, LOW);   
    digitalWrite(LEFT, HIGH);   
    break;
  case RIGHT:
    digitalWrite(LEFT, LOW);   
    digitalWrite(RIGHT, HIGH);   
    break;            
  }
}

void suspend(int dir) {
  digitalWrite(dir, LOW);
}

void full_stop() {
  digitalWrite(FORWARD, LOW);
  digitalWrite(REVERSE, LOW);
  digitalWrite(LEFT, LOW);
  digitalWrite(RIGHT, LOW);
}

/*
record current time to compare to
*/
void start_timed_operation(int index, int duration) {
  timed_operation_initiated_millis[index] = millis();
  timed_operation_desired_wait_millis[index] = duration;
  /*
  Serial.print("Timer added type ");
  Serial.print(index);
  Serial.print(" wait in millis:");
  Serial.println(duration);
  */
}

/*
Check whether the timer has expired
if expired, returns true else returns false
*/
boolean timed_operation_expired(int index) {
  int current_time = millis();
  if((current_time - timed_operation_initiated_millis[index]) < timed_operation_desired_wait_millis[index]) {
    return false;
  }
  return true;
}

int expected_wait_millis(int turn_rate, int initial_angle, int desired_angle) {
  int delta;
  if(initial_angle < 1 || desired_angle < 1) { 
    return 0;
  } else if(initial_angle == desired_angle) {
    return 0;
  } else if(initial_angle > desired_angle) {
    delta = initial_angle - desired_angle;
  } else {
    delta = desired_angle - initial_angle;
  }
  return (float(delta)/float(turn_rate))*1000.0;
}

int convert_reading_index(int angle) {
  return angle/SENSOR_ARC_DEGREES;
}

int read_sensor() {
  if(!timed_operation_expired(WAIT_FOR_SERVO_TO_TURN)) {
    return NO_READING;
  }
  
  if(!timed_operation_expired(WAIT_FOR_ECHO)) {
    return NO_READING;
  }
  
  int measured_value = sensor.Ranging(CM);
  
  start_timed_operation(WAIT_FOR_ECHO, SENSOR_MINIMAL_WAIT_ECHO_MILLIS);
  
  int index = convert_reading_index(current_sensor_servo_angle);
  // only update if the value is different beyond precision of sensor
  if(abs(measured_value - sensor_distance_readings_cm[index]) > SENSOR_PRECISION_CM) {
    sensor_distance_readings_cm[index] = measured_value;
    Serial.print("Sensor reading:");
    Serial.print(current_sensor_servo_angle);
    Serial.print(":");
    Serial.println(sensor_distance_readings_cm[index]);
  }
  return sensor_distance_readings_cm[index];
}

int get_last_reading_for_angle(int angle) {
  return sensor_distance_readings_cm[convert_reading_index(angle)];
}

/*
Initialize sweep (setting state and position sensor to be ready)
*/
void init_sweep() {
  full_stop();
  current_state = SWEEPING;
  update_servo_position(MINIMUM_SENSOR_SERVO_ANGLE);
}

/*
Read the current angle and store it in the readings array
Find the next angle that has no reading
If found, set the desired angle to that and return false
If not found, returns true
*/
boolean sensor_sweep() {
  // read current value
  if(read_sensor() == NO_READING) {
    return false;
  }

  // we have a valid value, so move to the next  position
  int desired_sensor_servo_angle = current_sensor_servo_angle + SENSOR_ARC_DEGREES;
  
  // we've completed from MINIMUM_SENSOR_SERVO_ANGLE to MAXIMUM_SENSOR_SERVO_ANGLE
  if(desired_sensor_servo_angle >= MAXIMUM_SENSOR_SERVO_ANGLE) {
    return true;
  } 
  
  update_servo_position(desired_sensor_servo_angle);
  // keep doing the sweep
  return false; 
}

void update_servo_position(int desired_sensor_servo_angle) {  
  if(current_sensor_servo_angle != desired_sensor_servo_angle) {
    sensor_servo.write(desired_sensor_servo_angle-1);              // tell servo to go to position in variable 'pos' 

    int wait_millis = expected_wait_millis(SERVO_TURN_RATE_PER_SECOND, current_sensor_servo_angle, desired_sensor_servo_angle);
    start_timed_operation(WAIT_FOR_SERVO_TO_TURN, wait_millis);

    current_sensor_servo_angle = desired_sensor_servo_angle;

    Serial.print("SERVO:");
    Serial.println(desired_sensor_servo_angle);
  }
}

boolean potential_collision() {
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= SAFE_DISTANCE;
}

boolean imminent_collision() {
  return sensor_distance_readings_cm[SENSOR_LOOKING_FORWARD_READING_INDEX] <= CRITICAL_DISTANCE;
}

int find_best_direction_degrees() {
  int longest_value = -1;
  int longest_index = -1;
  for(int i=0; i<NUMBER_READINGS; i++) {
    if(sensor_distance_readings_cm[i] > longest_value && sensor_distance_readings_cm[i] >= SAFE_DISTANCE) {
      longest_value = sensor_distance_readings_cm[i];
      longest_index = i;
    }
  }
  if(longest_index != -1) {
    return longest_index * SENSOR_ARC_DEGREES;
  }
  return NO_READING;
}

void init_turn() {
  current_state = TURN;
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
  if(turn_towards < SENSOR_LOOKING_FORWARD_ANGLE) {
    go(RIGHT);
  } 
  else {
    go(LEFT);
  }
  go(FORWARD);
  int expected_wait = expected_wait_millis(ROBOT_TURN_RATE_PER_SECOND, SENSOR_LOOKING_FORWARD_ANGLE, turn_towards);
  start_timed_operation(WAIT_FOR_ROBOT_TO_TURN, expected_wait);
  Serial.print("Waiting for robot to turn millis: ");
  Serial.println(expected_wait);
}

void init_go() {
  current_state = GO;
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
}

void init_decision() {
  current_state = DECISION;
  update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
}

void init_stuck() {
  current_state = STUCK;
}

boolean handle_turn() {
  // turn until we expect to meet the desired angle
  return timed_operation_expired(WAIT_FOR_ROBOT_TO_TURN);
}

boolean check_left = true;

void loop(){
  int initial_state = current_state;
  switch(current_state) {
  case INITIAL:
    // wait for the first reading...
    if(read_sensor() != NO_READING) {
      init_go();
    }
    break;
  case SWEEPING:
    if(sensor_sweep()) {
      // sweep completed, decision time!
      init_decision();
    } // else keep sweeping!
    break;
  case GO: 
    if(potential_collision()) {
      // we're going to crash into something, stop and find an alternative
      init_sweep();
    } 
    else {
      // keep moving!
      go(FORWARD);
      
      // we check if we have an updated value here
      if(read_sensor() != NO_READING) {
        // we have an updated value, if it's a center value
        // move the servo to get left and right readings
        if(current_sensor_servo_angle == SENSOR_LOOKING_FORWARD_ANGLE) {
          // go left or right depending on check_left
          if(check_left) {
            update_servo_position(SENSOR_LOOKING_LEFT_ANGLE);
          } else {  
            update_servo_position(SENSOR_LOOKING_RIGHT_ANGLE);
          }
        } else {
          // check left toggles between true and false here
          check_left = !check_left;
          // return to center; this mean we read twice as often forward than left or right
          update_servo_position(SENSOR_LOOKING_FORWARD_ANGLE);
        }
        
        // one of the value has been updated, check to see if we should go left or right 
        // or just keep going forward
        int left_value = get_last_reading_for_angle(SENSOR_LOOKING_LEFT_ANGLE);
        int right_value = get_last_reading_for_angle(SENSOR_LOOKING_RIGHT_ANGLE);
        int forward_value = get_last_reading_for_angle(SENSOR_LOOKING_FORWARD_ANGLE);
        
        if(left_value > forward_value && left_value > right_value) {
          go(LEFT);
        } else if(right_value > forward_value && right_value > left_value) {
          go(RIGHT);
        } else {
          suspend(LEFT);
          suspend(RIGHT);
        }
      }
    }
    break;
  case DECISION:
    // we want to turn towards the longest opening
    turn_towards = find_best_direction_degrees();
    if(turn_towards != NO_READING) {
      init_turn();
    } 
    else {
      init_stuck();
    }
    break;
  case STUCK:
    // TODO: check if we can reverse...
    // for now... re-sweep, maybe the obstacle will go away...
    init_sweep();
    break;
  case TURN:
    read_sensor();
    if(imminent_collision()) {
      full_stop();
    }
    if(handle_turn()) {
      // we've turned! reset and try to move forward now
      full_stop();
      init_go();
    }
    break;
  default:
    Serial.println("BAD STATE!");
    break;
  }

  if(initial_state != current_state) {
    Serial.print("INITIAL STATE:");
    Serial.print((char)initial_state);
    Serial.print(" FINAL STATE:");
    Serial.println((char)current_state);
  }
}

