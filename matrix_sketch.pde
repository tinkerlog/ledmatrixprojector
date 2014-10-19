/** 
 * Dualcolor matrix
 * http://tinkerlog.com 
 * email: alex at tinkerlog.com
 *
 * Reference:
 * http://www.arduino.cc/en/Tutorial/ShiftOut
 * http://www.uchobby.com/index.php/2007/11/24/arduino-interrupts/
 *
 */

#include <avr/pgmspace.h>
#include <string.h>

#define SHIFT_CLOCK_PIN 4
#define STORE_CLOCK_PIN 5
#define SER_DATA_PIN 6
#define SPEED_PIN 0


byte soft_prescaler = 0;

byte activeRow = 0;
byte screenMem[16];

byte sprites[][8] = {
  {
    0x18,    // ___XX___   A
    0x3C,    // __XXXX__
    0x7E,    // _XXXXXX_
    0xDB,    // X_XXXX_X
    0xFF,    // XXXXXXXX
    0x24,    // __X__X__
    0x5A,    // _X_XX_X_
    0xA5     // X_X__X_X
  },
  {
    0x18,    // ___XX___  B
    0x3C,    // __XXXX__
    0x7E,    // _XXXXXX_
    0xDB,    // X_XXXX_X
    0xFF,    // XXXXXXXX
    0x24,    // __X__X__
    0x42,    // _X____X_
    0x24     // __X__X__
  },
  {
    0x24,    // __X__X__  C
    0x7E,    // _XXXXXX_
    0xDB,    // XX_XX_XX
    0xFF,    // XXXXXXXX
    0xA5,    // X_X__X_X
    0x99,    // X__XX__X
    0x81,    // X______X
    0xC3     // XX____XX
  },
  {
    0x24,    // __X__X__  D
    0x18,    // ___XX___
    0x7E,    // X_XXXX_X
    0xDB,    // XX_XX_XX
    0xFF,    // XXXXXXXX
    0xDB,    // X_XXXX_X
    0x99,    // X__XX__X
    0xC3     // XX____XX
  },
  {
    0xCC,    // XX__XX__  E
    0xCC,    // XX__XX__
    0x33,    // __XX__XX
    0x33,    // __XX__XX
    0xCC,    // XX__XX__
    0xCC,    // XX__XX__
    0x33,    // __XX__XX
    0x33     // __XX__XX
  },
  {
    0x33,    // __XX__XX  F
    0x33,    // __XX__XX
    0xCC,    // XX__XX__
    0xCC,    // XX__XX__
    0x33,    // __XX__XX
    0x33,    // __XX__XX
    0xCC,    // XX__XX__
    0xCC     // XX__XX__
  },
  {
    0x00,    // ________  G
    0x00,    // ________
    0x00,    // ________
    0x18,    // ___XX___
    0x18,    // ___XX___
    0x00,    // ________
    0x00,    // ________
    0x00     // ________
  },
  {
    0x00,    // ________  H
    0x00,    // ________
    0x3C,    // __XXXX__
    0x3C,    // __XXXX__
    0x3C,    // __XXXX__
    0x3C,    // __XXXX__
    0x00,    // ________
    0x00     // ________
  },
  {
    0x00,    // ________  I
    0x7E,    // _XXXXXX_
    0x7E,    // _XXXXXX_
    0x7E,    // _XXXXXX_
    0x7E,    // _XXXXXX_
    0x7E,    // _XXXXXX_
    0x7E,    // _XXXXXX_
    0x00     // ________
  },
  {
    0xFF,    // XXXXXXXX  J
    0xFF,    // XXXXXXXX
    0xFF,    // XXXXXXXX
    0xFF,    // XXXXXXXX
    0xFF,    // XXXXXXXX
    0xFF,    // XXXXXXXX
    0xFF,    // XXXXXXXX
    0xFF     // XXXXXXXX
  },
  {
    0x0F,    // ____XXXX  K
    0x0F,    // ____XXXX
    0x0F,    // ____XXXX
    0x0F,    // ____XXXX
    0xF0,    // XXXX____
    0xF0,    // XXXX____
    0xF0,    // XXXX____
    0xF0,    // XXXX____
  },
  {
    0xF0,    // XXXX____  L
    0xF0,    // XXXX____
    0xF0,    // XXXX____
    0xF0,    // XXXX____
    0x0F,    // ____XXXX
    0x0F,    // ____XXXX
    0x0F,    // ____XXXX
    0x0F,    // ____XXXX
  },
  {
    0xFF,    // XXXXXXXX  M
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0xFF,    // XXXXXXXX 
  },
  {
    0xFF,    // XXXXXXXX  N
    0xFF,    // XXXXXXXX  
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0x00,    // ________
    0xFF,    // XXXXXXXX 
    0xFF,    // XXXXXXXX 
  },
  {
    0xFF,    // XXXXXXXX  O
    0xFF,    // XXXXXXXX 
    0xFF,    // XXXXXXXX 
    0x00,    // ________
    0x00,    // ________
    0xFF,    // XXXXXXXX 
    0xFF,    // XXXXXXXX 
    0xFF,    // XXXXXXXX 
  },
  {
    0x10,    // ___X____  P
    0x10,    // ___X____ 
    0x10,    // ___X____ 
    0x1F,    // ___XXXXX
    0xF8,    // XXXXX___
    0x08,    // ____X___ 
    0x08,    // ____X___ 
    0x08,    // ____X___ 
  },
  {
    0x70,    // _XXX____  Q
    0x31,    // __XX___X 
    0x13,    // ___X__XX 
    0x1F,    // ___XXXXX
    0xF8,    // XXXXX___
    0xC8,    // XX__X___ 
    0x8C,    // X___XX__ 
    0x0E,    // ____XXX_ 
  },
  {
    0xF1,    // XXXX___X  R
    0x73,    // _XXX__XX 
    0x37,    // __XX_XXX 
    0x1F,    // ___XXXXX
    0xF8,    // XXXXX___
    0xEC,    // XXX_XX__ 
    0xCE,    // XX__XXX_ 
    0x8F,    // X___XXXX 
  },
  {
    0x04,    // _____X__  S
    0x00,    // ________
    0x80,    // X_______
    0x00,    // ________
    0x00,    // ________
    0x01,    // _______X
    0x00,    // ________
    0x20,    // __X_____
  },
  {
    0x0E,    // ____XXX_  T
    0x84,    // X____X__
    0xC0,    // XX______
    0x80,    // X_______
    0x01,    // _______X
    0x03,    // ______XX
    0x21,    // __X____X
    0x70,    // _XXX____
  },
  {
    0x9F,    // X__XXXXX  U
    0xCE,    // XX__XXX_
    0xE4,    // XXX__X__
    0xC1,    // XX_____X
    0x83,    // X_____XX
    0x27,    // __X__XXX
    0x73,    // _XXX__XX
    0xF9,    // XXXXX__X
  }
};


// prog_char sequence_00[] PROGMEM = "_1Ap"; // "_ sb sd sw sx sc ss sj su 1smsm 2sg sf sc se sl sn sc";
prog_char sequence_00[] PROGMEM = "_ sb sd sw sx sc ss sj su 1smsm 2sg sf sc se sl sn sc";
prog_char sequence_01[] PROGMEM = " 2sksk 1Hsi 2sksk 1Ash"; // b, block <--
prog_char sequence_02[] PROGMEM = " _1Ep zzz2Fp zzz 1Fpz2Ep 1Fpz2Ep 1Fpz2Ep 1Fpz2Ep "; // c
prog_char sequence_03[] PROGMEM = " 1sese2sese "; // d 
prog_char sequence_04[] PROGMEM = " zGpHpIpJpIpHpGp "; // e square, 8 cycles 
prog_char sequence_05[] PROGMEM = " 1Kpzzz 2Lpzzz 1Kpzzz2Lpzzz 1Kpz 2Lpz 1Kpz2Lpz ";  // f
prog_char sequence_06[] PROGMEM = " _llllllllCprprprprprprprprpCpzzDpzzCpzzDpzzCpzzprprprprprprprpr"; // g
prog_char sequence_07[] PROGMEM = " _llllllllprprprprprprprprprprprprprprprprp"; // h left-right
prog_char sequence_08[] PROGMEM = " _rrrrrrrrplplplplplplplplplplplplplplplplp"; // i right-left
prog_char sequence_09[] PROGMEM = " _2Ep1svsvsv svsvsv "; // j
prog_char sequence_10[] PROGMEM = " _ zMpNpOpJpOpNpMp "; // k gate, close-open, 8 cycles 
prog_char sequence_11[] PROGMEM = " _rrrrrrrr2Aplplplplplplplplp3pzz 2pzz3pzz 2pzz 1pzz 2pzzlplplplplplplplp "; // l
prog_char sequence_12[] PROGMEM = " _Jpruprupruprupldpldpldpldp "; // m block
prog_char sequence_13[] PROGMEM = " 1sosesese2spsesese3sqsesese1sr"; // n
prog_char sequence_14[] PROGMEM = " _Gpupupupupdpdpdpdp"; // o
prog_char sequence_15[] PROGMEM = " _Gpdpdpdpdpupupupup"; // p
prog_char sequence_16[] PROGMEM = " _Gplplplplprprprprp"; // q
prog_char sequence_17[] PROGMEM = " _Gprprprprplplplplp"; // r
prog_char sequence_18[] PROGMEM = " 2stst 3stst "; // s
prog_char sequence_19[] PROGMEM = "zPpQpRpJpRpQpPp "; // t propeller, 8 cycles
prog_char sequence_20[] PROGMEM = " 1svsv 2svsv "; // u
prog_char sequence_21[] PROGMEM = "zSpTpUpJpUpTpSp"; // v arrows, 8 cycles
prog_char sequence_22[] PROGMEM = " 3sksk 2Hsi 3sksk 2Csh"; // w, block -->
prog_char sequence_23[] PROGMEM = " sysy "; // x
prog_char sequence_24[] PROGMEM = " 2Epuuuuuuuu1Jpdpdpdpdpdpdpdpupupupupupupupup"; // y
prog_char sequence_25[] PROGMEM = ""; // z


PGM_P PROGMEM sequences[] = {   
  sequence_00,
  sequence_01,
  sequence_02,
  sequence_03,
  sequence_04,
  sequence_05,
  sequence_06,
  sequence_07,
  sequence_08,
  sequence_09,
  sequence_10,
  sequence_11,
  sequence_12,
  sequence_13,
  sequence_14,
  sequence_15,
  sequence_16,
  sequence_17,
  sequence_18,
  sequence_19,
  sequence_20,
  sequence_21,
  sequence_22,
  sequence_23,
  sequence_24,
  sequence_25
};


struct context {
  byte sequence;
  byte sequencePtr;
  byte page;
  byte sprite;
  int x;
  int y;
};

char buffer[80];
byte bufferPtr = 0;
byte bufferSize = 0;

struct context stackSequences[8];
byte stackSequencePtrs[8];
byte stackPtr = 0;
byte actSequence = 0;
int x, y;
byte sprite = 0;
byte page = 0;
byte wait = 50;



void loadSequence(byte sequence) {
  strcpy_P(buffer, (char*)pgm_read_word(&(sequences[sequence])));
  bufferPtr = 0;
  bufferSize = strlen(buffer);
  actSequence = sequence;
}

void pushSequence(byte sequence) {
  // Serial.print("push: ");
  // Serial.print(actSequence, DEC);
  // Serial.print(" ");
  // Serial.println(bufferPtr, DEC);
  stackSequences[stackPtr].sequence = actSequence;
  stackSequences[stackPtr].sequencePtr = bufferPtr;
  stackSequences[stackPtr].x = x;
  stackSequences[stackPtr].y = y;
  stackSequences[stackPtr].sprite = sprite;
  stackSequences[stackPtr].page = page;
  stackPtr++;
  loadSequence(sequence);
}

void popSequence() {
  stackPtr--;
  actSequence = stackSequences[stackPtr].sequence;
  loadSequence(actSequence);
  bufferPtr = stackSequences[stackPtr].sequencePtr;
  x = stackSequences[stackPtr].x;
  y = stackSequences[stackPtr].y;
  sprite = stackSequences[stackPtr].sprite;
  page = stackSequences[stackPtr].page;
  bufferPtr++;
  // Serial.print("pop: ");
  // Serial.print(actSequence, DEC);
  // Serial.print(" ");
  // Serial.println(bufferPtr, DEC);
}

void setup() {

  // Calculation for timer 2
  // 16 MHz / 8 = 2 MHz (prescaler 8)
  // 2 MHz / 256 = 7812 Hz
  // soft_prescaler = 15 ==> 520.8 updates per second
  // 520.8 / 8 rows ==> 65.1 Hz for the complete display
  TCCR2A = 0;           // normal operation
  TCCR2B = (1<<CS21);   // prescaler 8
  TIMSK2 = (1<<TOIE2);  // enable overflow interrupt

  // define outputs for serial shift registers
  pinMode(SHIFT_CLOCK_PIN, OUTPUT);
  pinMode(STORE_CLOCK_PIN, OUTPUT);
  pinMode(SER_DATA_PIN, OUTPUT);

  // define outputs for 8 rows
  pinMode(8, OUTPUT);    // PB0, row 0
  pinMode(9, OUTPUT);    // PB1, row 1
  pinMode(10, OUTPUT);   // PB2, row 2
  pinMode(11, OUTPUT);   // PB3, row 3
  pinMode(12, OUTPUT);   // PB4, row 4
  pinMode(13, OUTPUT);   // PB5, row 5
  pinMode(2, OUTPUT);    // PD2, row 6
  pinMode(3, OUTPUT);    // PD3, row 7

  loadSequence(0);

  Serial.begin(9600);

}


/**
 * ISR TIMER2_OVF_vect
 * This is the timer interrupt service routine.
 * It gets called at 7812 times per second.
 */
ISR(TIMER2_OVF_vect) {

  soft_prescaler++;
  if (soft_prescaler == 15) {
    // display the next row
    displayActiveRow();
    soft_prescaler = 0;
  }
	
}



/**
 * displayActiveRow
 * The row is active low. But we are using a ULN2803, that is inverting. 
 * So we have to use high to switch a row on.
 */
void displayActiveRow() {

  // disable current row
  if (activeRow < 6) {
    digitalWrite(8 + activeRow, LOW);
  }
  else if (activeRow == 6) {
    digitalWrite(2, LOW);
  }
  else {
    digitalWrite(3, LOW);
  }
  
  // next row
  activeRow = (activeRow+1) % 8;

  // shift out values for this row
  shiftOutRow(screenMem[activeRow], screenMem[8+activeRow]);
  
  // switch to new row
  if (activeRow < 6) {
    digitalWrite(8 + activeRow, HIGH);
  }
  else if (activeRow == 6) {
    digitalWrite(2, HIGH);
  }
  else {
    digitalWrite(3, HIGH);
  }
}



void shiftOutRow(byte red, byte green) {
  digitalWrite(STORE_CLOCK_PIN, LOW);
  shiftOut(SER_DATA_PIN, SHIFT_CLOCK_PIN, LSBFIRST, red);   
  shiftOut(SER_DATA_PIN, SHIFT_CLOCK_PIN, LSBFIRST, green);   
  // return the latch pin high to signal chip that it 
  // no longer needs to listen for information
  digitalWrite(STORE_CLOCK_PIN, HIGH);
}


void clearDisplay() {
  byte i;
  for (i = 0; i < 16; i++) {
    screenMem[i] = 0x00;
  }
}


void copyToDisplay(char x, char y, byte page, byte sprite[8]) {
  char i, t;
  byte row;
  for (i = 0; i < 8; i++) {
    t = i-y;
    row = ((t >= 0) && (t < 8)) ? sprite[t] : 0x00;
    row = (x >= 0) ? (row >> x) : (row << -x);
    if ((page & 1) == 1) {
      screenMem[i] = row;
    }
    if ((page & 2) == 2) {
      screenMem[i+8] = row;
    }
  }
}



void loop() {

  int speed = analogRead(SPEED_PIN);
  wait = speed >> 2;

  char command;
  command = buffer[bufferPtr];
  /*
  Serial.print("ptr:");
  Serial.print(bufferPtr, DEC);
  Serial.print(" c:");
  Serial.println(command);
  
  delay(500);
  */
  
  bufferPtr++;

  switch (command) {
  case ' ':
    clearDisplay();
    break;
  case '_':
    x = 0;
    y = 0;
    break;
  case 'l':
    x -= 1;
    break;
  case 'r':
    x += 1;
    break;
  case 'u':
    y -= 1;
    break;
  case 'd':
    y += 1;
    break;
  case 's':
    pushSequence(buffer[bufferPtr] - 'a');
    break;
  case 'A':  case 'B':  case 'C':  case 'D':  case 'E':  case 'F':
  case 'G':  case 'H':  case 'I':  case 'J':  case 'K':  case 'L':
  case 'M':  case 'N':  case 'O':  case 'P':  case 'Q':  case 'R':
  case 'S':  case 'T':  case 'U':  case 'V':  case 'W':  case 'X':
  case 'Y':  case 'Z':
    sprite = command - 'A';
    break;
  case '0':  case '1':  case '2':  case '3':
    page = command - '0';
    break;
  case 'p':
    /*
    Serial.print(x);
    Serial.print(" ");
    Serial.print(y);
    Serial.print(" ");
    Serial.print(page, DEC);
    Serial.print(" ");
    Serial.print(sprite, DEC);
    Serial.println();
    */
    copyToDisplay(x, y, page, sprites[sprite]);
    delay(wait);
    break;
  case 'z':
    delay(wait);
    break;
  default:
    Serial.print("unknown command:");
    Serial.print(command);
    Serial.println();
  } 

  while (bufferPtr >= bufferSize) {
    if (actSequence != 0) {
      popSequence();
    }
    else {
      bufferPtr = 0;
    }
  }

}
