unit Keyboard;

interface

type

  keyblock = record
    L: integer;		{ left }
    T: integer;		{ top }
    W: integer;		{ width of the key }
    H: integer;		{ height of the key }
    SX: integer;	{ horizontal spacing }
    SY: integer;	{ vertical spacing }
    col: integer;	{ number of columns }
    cnt: integer;	{ number of keys in a block }
    OX: integer;	{ left in the Keys.bmp }
    OY: integer;	{ top in the Keys.bmp }
  end;


const

  KEYPADS = 13;		{index of the last item in the 'keypad' array}
  LASTKEYCODE = 81;

{ list of key codes for function keys }

  KC_NONE       = 0;
  KC_POWER      = 1;
  KC_TAB        = 4;
  KC_MEMO       = 11;
  KC_IN         = 12;
  KC_OUT        = 13;
  KC_CALC       = 14;
  KC_SHIFT      = 15;
  KC_CAPS       = 46;
  KC_ANS        = 47;
  KC_SPC        = 48;
  KC_INS        = 49;
  KC_UP         = 50;
  KC_DEL        = 51;
  KC_MENU       = 52;
  KC_LEFT       = 53;
  KC_DOWN       = 54;
  KC_RIGHT      = 55;
  KC_CAL        = 56;
  KC_BRK        = 57;
  KC_CLS        = 58;
  KC_BS         = 59;
  KC_EXE        = 75;
  KC_M1         = 76;
  KC_M2         = 77;
  KC_M3         = 78;
  KC_M4         = 79;
  KC_ETC        = 80;
  KC_KANA       = 81;
  KC_NEWALL     = 82;
  KC_LAST       = KC_NEWALL;
{ key code mappings for 'character' keys }

{ key code of first letter from list below }
    KC_FIRSTCHAR = 4;
{ characters which can be entered from keyboard as is }
    Letters: string[71] =
	#09'''()[]|aaaaaQWERTYUIOP=ASDFGHJKL;:ZXCVBNM,aa aaaaaaaaaaa/789*456-123+0.';
{ characters which require the [s] key (overlaid onto the above) }
    ShiftLetters: string[71] =
  	   'a!"#$%&aaaaa?@\_`{}~<>^aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';


  keypad: array[0..KEYPADS] of keyblock = (
{ power switch, code:1 }
    (	L:0;	T:27;	W:11;	H:99;	SX:40;	SY:120;	col:1;	cnt:1;	OX:0;	OY:0	),
{ application minimize and close, codes: 2..3 }
    (	L:636;	T:2;	W:17;	H:17;	SX:18;	SY:33;	col:2;	cnt:2;	OX:130;	OY:25	),
{ first row of small keys: TAB to red S, code: 4..15 }
    (	L:18;	T:165;	W:33;	H:21;	SX:40;	SY:33;	col:12;	cnt:12;	OX:22;	OY:46	),
{ second row of small keys: Q to =, code: 16..26 }
    (	L:29;	T:198;	W:33;	H:21;	SX:40;	SY:33;	col:11;	cnt:11;	OX:22;	OY:46	),
{ third row of small keys: A to :, code: 27..37 }
    (	L:58;	T:231;	W:33;	H:21;	SX:40;	SY:33;	col:11;	cnt:11;	OX:22;	OY:46	),
{ fourth row of small keys: Z to comma, code: 38..45 }
    (	L:69;	T:264;	W:33;	H:21;	SX:40;	SY:33;	col:8;	cnt:8;	OX:22;	OY:46	),
{ CAPS and ANS keys, code: 46..47 }
    (	L:18;	T:264;	W:33;	H:21;	SX:440;	SY:33;	col:2;	cnt:2;	OX:22;	OY:46	),
{ SPACE bar, code: 48 }
    (	L:393;	T:264;	W:54;	H:21;	SX:61;	SY:33;	col:1;	cnt:1;	OX:22;	OY:25	),
{ two rows of small keys on the right side, code: 49..56 }
    (	L:504;	T:32;	W:33;	H:21;	SX:40;	SY:33;	col:4;	cnt:8;	OX:22;	OY:46	),
{ five rows of large keys, code: 57..74 }
    (	L:504;	T:108;	W:33;	H:25;	SX:40;	SY:38;	col:4;	cnt:18;	OX:88;	OY:46	),
{ EXE key, code: 75 }
    (	L:584;	T:260;	W:73;	H:25;	SX:80;	SY:38;	col:1;	cnt:1;	OX:22;	OY:0	),
{ four white keys below the LCD, code: 76..79 }
    (	L:82;	T:135;	W:55;	H:12;	SX:96;	SY:33;	col:4;	cnt:4;	OX:22;	OY:71	),
{ ETC key, code: 80 }
    (	L:453;	T:135;	W:20;	H:12;	SX:96;	SY:33;	col:1;	cnt:1;	OX:22;	OY:83	),
{ KANA key, code: 81 }
    (	L:18;	T:231;	W:33;	H:21;	SX:40;	SY:33;	col:1;	cnt:1;	OX:22;	OY:46	)
  );


var
  KeyCode1: integer;		{ from the mouse }
  KeyCode2: integer;		{ from the keyboard }
  DelayedKeyCode2: integer = 0; { two-key combo, code sent on key release }
  function GetCharacterCode(c: char; var needsShift: boolean): integer;
  function ReadKy (Ko: byte) : word;
  procedure SendKeyCode(kc: integer);
  procedure KeyInterrupt;

implementation
uses cpu, def;
const

{ tables converting KeyCode1 and KeyCode2 to the KY state for given KO }

  KeyTab: array[0..15, 0..LASTKEYCODE+1] of word = (

( { KO code 0, none selected }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 46..48 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO1 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0080, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO2 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $8000, $4000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0002, $0001, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0004, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0010, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0020, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0008,
{ New All, code: 82 }
  $0000
),

( { KO3 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $8000, $4000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0002, $0001, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0008, $0004, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0020, $0010, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $1000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO4 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $8000, $4000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0002, $0001, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0008, $0004, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0020, $0010, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $1000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO5 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $8000, $4000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0002, $0001,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0008, $0004, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0020, $0010, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $1000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO6 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $8000, $4000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0002, $0001, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0008,
  $0004, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0020,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0010,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $1000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO7 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $8000, $0040,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0002,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0008, $0004,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0020, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $1000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO8 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0080, $0000, $0000, $0000,
  $0002, $0001, $0000, $0000,
  $0008, $0004, $0000, $0000,
  $0020, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $2000
),

( { KO9 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0080, $0000,
  $0000, $0000, $0002, $0001,
  $0000, $0000, $0008, $0004,
  $0000, $0020,
{ EXE key, code: 75 }
  $0010,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO10 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $8000, $4000,
  $0000, $0000, $0002, $0001,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0008, $0004,
  $0000, $0000, $0000, $0080,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO11 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $8000, $4000, $0000, $0000,
  $0002, $0001, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0004, $0000, $0000,
  $0000, $0080, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO12 }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO code 13, all columns selected }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $8000, $4000, $8000, $4000, $8000, $4000, $8000, $4000,
  $8000, $4000, $8000, $0040,
{ second row of small keys: Q to =, code: 16..26 }
  $0002, $0001, $0002, $0001, $0002, $0001, $0002, $0001,
  $0002, $0001, $0002,
{ third row of small keys: A to :, code: 27..37 }
  $0004, $0008, $0004, $0008, $0004, $0008, $0004, $0008,
  $0004, $0008, $0004,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0010, $0020, $0010, $0020, $0010, $0020, $0010, $0020,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0020, $0020, $0010,
{ two rows of small keys on the right side, code: 49..56 }
  $8000, $4000, $8000, $4000,
  $0002, $0001, $0002, $0001,
{ five rows of large keys, code: 57..74 }
  $0080, $0004, $0008, $0004,
  $0080, $0080, $0080, $0080,
  $0002, $0001, $0002, $0001,
  $0008, $0004, $0008, $0004,
  $0020, $0020,
{ EXE key, code: 75 }
  $0010,
{ four white keys below the LCD, code: 76..79 }
  $1000, $1000, $1000, $1000,
{ ETC key, code: 80 }
  $1000,
{ KANA key, code: 81 }
  $0008,
{ New All, code: 82 }
  $2000
),

( { KO code 14, undefined }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
),

( { KO code 15, undefined }
{ no key pressed }
  $0000,
{ power switch, code: 1 }
  $0000,
{ application minimize and close, codes: 2..3 }
  $0000, $0000,
{ first row of small keys: TAB to red S, code: 4..15 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ second row of small keys: Q to =, code: 16..26 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ third row of small keys: A to :, code: 27..37 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
  $0000, $0000, $0000,
{ fourth row of small keys: Z to comma, code: 38..45 }
  $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000,
{ CAPS, ANS, SPACE, code: 44..46 }
  $0000, $0000, $0000,
{ two rows of small keys on the right side, code: 49..56 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
{ five rows of large keys, code: 57..74 }
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000, $0000, $0000,
  $0000, $0000,
{ EXE key, code: 75 }
  $0000,
{ four white keys below the LCD, code: 76..79 }
  $0000, $0000, $0000, $0000,
{ ETC key, code: 80 }
  $0000,
{ KANA key, code: 81 }
  $0000,
{ New All, code: 82 }
  $0000
)

);

function GetCharacterCode(c: char; var needsShift: boolean): integer;
var
        n: integer;
begin
        Result := 0;
        needsShift := false;
        c := UpCase(c);
        n := pos(c, Letters);
        { key is on key face, return key code }
        if (n > 0) then
        begin
                Result := n + KC_FIRSTCHAR - 1;
                Exit;
        end;

        n := pos(c, ShiftLetters);
        { key is not on key face and requires shift, send shift (red S) first and send wanted key on release }
        if (n > 0) then
        begin
                Result := n + KC_FIRSTCHAR - 1;
                needsShift := True;
        end

end;

procedure SendKeyCode(kc: integer);
begin
        if (kc >= 0) and (kc < KC_LAST) then
        begin
                KeyCode2 := kc;
                KeyInterrupt;
        end;
end;

procedure KeyInterrupt;
const
{ table of interrupt capable KY bits for specified IA bits 5,4 }
  ktab: array [0..3] of word = ( $0000, $0080, $00C0, $F0FF );
begin
  if ((ia and $80) <> 0) and	{ key interrupt specified? }
     ((ReadKy (ia and $0F) and ktab[(ia shr 4) and 3]) <> 0) then
	SetIfl (KEYPULSE_bit);
end {KeyInterrupt};

function ReadKy (Ko: byte) : word;
begin
  ReadKy := KeyTab[Ko,KeyCode1] or KeyTab[Ko,KeyCode2];
end {ReadKy};


end.
