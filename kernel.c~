// kernel.c 
// Follow C90 Standards. It helps. :)

// I did not link any standard c libraries
// as dynamic linking wouldn't work
// inside the emulator. 
#include "keyboard_map.h"

// display static globals
#define LINES 25
#define COLUMNS_IN_LINE 80
#define BYTES_FOR_EACH_ELEMENT 2
#define SCREENSIZE BYTES_FOR_EACH_ELEMENT * COLUMNS_IN_LINE * LINES

// Keyboard static globals
#define KEYBOARD_DATA_PORT 0x60
#define KEYBOARD_STATUS_PORT 0x64
#define IDT_SIZE 256
#define INTERRUPT_GATE 0x8e
#define KERNEL_CODE_SEGMENT_OFFSET 0x08
#define COLOR 0x03

// Stack globals
#define STACK_SIZE 100

// the map for the keys. keys have a code which 
// are mapped to the ascii codes.
extern unsigned char keyboard_map[128];

// the assembly function definition.
extern void keyboard_handler(void);

// current location of the textual pointer.
unsigned int current_loc = 0;

// line size copied to the buffer.
unsigned int line_iterator = 0;

// whether the keyboard has shift key down or not.
unsigned int shifted = 0;

// line buffer.
char line[80];

// The memory location which corresponds to 
// position of the display's pixels. Every two bytes 
// in the corresponding contiguous block refers 
// to a pixel. 
char *vidptr = (char*)0xb8000;

// Interrupt table entry struct.
struct IDT_entry{
	   unsigned short int offset_lowerbits;
	   unsigned short int selector;
	   unsigned char zero;
	   unsigned char type_attr;
	   unsigned short int offset_higherbits;
};

//
//
//
// Stack Implementation using Arrays.
// Can't use link lists because you 
// Can't add library headers. 
// Static Linking doesn't work either.  
// Normal compiling does dynamic linking.
// Static Linking libraries will result in the 
// library functions making syscalls, to "kernel"
// and thus you get the drift.
typedef struct Stack{
	unsigned int array[STACK_SIZE];
	unsigned int pointer;
}Stack;

// Initialize your stack,
// Don't be an idiot.
void 
init(Stack *s) {
	s->pointer = 0;
	unsigned int i = 0;
	for(i=0;i<STACK_SIZE;i++) {
		s->array[i] = 0;
	}
}

// Push into the stack.
unsigned int 
push(Stack *s,unsigned int value) {
	s->pointer++;
	s->array[s->pointer] = value;
}

// Pop out of the stack.
unsigned int 
pop(Stack *s) {
	unsigned int value = s->array[s->pointer];
	s->pointer--;
	return value;
}

// Take a peek into the topmost element.
unsigned int 
peek(Stack *s) {
	return s->array[s->pointer];
}

// Is stack empty ?
unsigned int 
is_empty(Stack *s) {
	if(s->pointer == 0)
		return 1;
	return 0;
}
//
//
// STACK IMPLEMENTATION ENDS.


// Creating the interrupt handler table.
// We add the intrrupt function 'keyboard_handler' 
// to the interrupt handler table.
// this table contains all the interrupts handlers 
// whenever an interrupt is raised by a device.
void
idt_init(void) {
	unsigned long keyboard_address;
	unsigned long idt_address;
	unsigned long idt_ptr[2];	
	struct IDT_entry IDT[IDT_SIZE];
	keyboard_address = (unsigned long)keyboard_handler;
	
	// 0x21 is the index where the keyboard 
	// interrupt handler should be present.
	IDT[0x21].offset_lowerbits = keyboard_address & 0xffff;
	IDT[0x21].selector = KERNEL_CODE_SEGMENT_OFFSET;
	IDT[0x21].zero = 0;
	IDT[0x21].type_attr = INTERRUPT_GATE;
	IDT[0x21].offset_higherbits = (keyboard_address & 0xffff0000) >> 16;
	
	// Specific ports are written 
	// to initialize vector table.
	write_port(0x20 , 0x11);
	write_port(0xA0 , 0x11);
	write_port(0x21 , 0x20);
	write_port(0xA1 , 0x28);
	write_port(0x21 , 0x00);  
	write_port(0xA1 , 0x00);  
	write_port(0x21 , 0x01);
	write_port(0xA1 , 0x01);
	write_port(0x21 , 0xff);
	write_port(0xA1 , 0xff);
	
	idt_address = (unsigned long)IDT;
	// This stores the size of 
	// the Interrupt Table.
	idt_ptr[0] = (sizeof (struct IDT_entry) * IDT_SIZE) + ((idt_address & 0xffff) << 16);
	
	// This stores the Interrupt Table
	// Address.
	idt_ptr[1] = idt_address >> 16 ;
	
	// Load Interrupt Table Information into memory 
	// using assembly level specific commands.
	load_idt(idt_ptr);
}

// keyboard initializer.
void
kb_init() {
	write_port(0x21 , 0xFD);
}



// Prints new line in the display terminal.
void
kprint_newline() {
	unsigned int line_size = BYTES_FOR_EACH_ELEMENT * COLUMNS_IN_LINE;
	current_loc = current_loc + (line_size - current_loc % (line_size));
}

// Prints string to the display terminal.
void 
kprint(const char *str) {
	unsigned int i = 0;
	while (str[i] != '\0') {
		if(str[i] == '\n') {
			kprint_newline();
			continue;
		}
		vidptr[current_loc++] = str[i++];
		vidptr[current_loc++] = COLOR;
	}
}

// Clears the display terminal.
void 
clear_screen() {
	unsigned int i = 0;
	while (i < SCREENSIZE) {
		vidptr[i++] = ' ';
		vidptr[i++] = COLOR; 
	}
}

// The line buffer is reset. 
// Gets called after Enter in pressed.
void 
reset_line() {
	unsigned int i = 0;
	for(i=0;i<line_iterator;i++) {
		line[i] = '\0';
	}
	line_iterator = 0;
}




// Convert array to unsigned integer.
unsigned int 
atoi(char *s) {
	char *string=s;
	unsigned int num=0;
	while(*string) {
		num = num*10 + (int)*string - '0';
		string++; 
	}
	return num;
}

// Convert unsigned integer to array.
char* 
itoa(unsigned int i, char *b,unsigned int base){
	char const digits[] = "0123456789ABCDEF";
	char* p = b;
	unsigned int shifter = i;
	do { 
		++p;
		shifter = shifter/base;
	}while(shifter);
	*p = '\0';
	do {
		*--p = digits[i%base];
		i = i/base;
	}while(i);
	return b;
}

// compare two strings and if they are equal
// or lexographically smaller or greater,
// return 0, -1 and 1 respectively.
unsigned int 
strcmp (const char *s1, const char *s2) {
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;

    while (*p1 != '\0') {
        if (*p2 == '\0') return  1;
        if (*p2 > *p1)   return -1;
        if (*p1 > *p2)   return  1;

        p1++;
        p2++;
    }

    if (*p2 != '\0') return -1;

    return 0;
}




// helper function. self-explanatory.
unsigned int 
is_whitespace(char c) {
	if (c == ' ' || c == '\t') 
		return 1;
	return 0;
}

// helper function. self-explanatory.
unsigned int 
is_a_number(char num) {
	if( num - '0' >= 0 && num - '0' <= 9)
		return 1;
	return 0;
}

// helper function. self-explanatory.
unsigned int 
is_an_operator(char op) {
	if( op == '+' )
		return 1;
	if( op == '-' )
		return 2;
	if( op == '*' )
		return 3;
	if( op == '/' )
		return 4;
	if( op == '&' )
		return 5;
	if( op == '|' )
		return 6;
	if( op == '%' )
		return 7;
	return 0;
}

// Gives the answer based on operation.
unsigned int 
get_answer(unsigned int operand1, unsigned int operand2,
			unsigned int operator) {
	if (operator == 1) 
		return operand1 + operand2;
	if (operator == 2)
		return operand1 - operand2;
	if (operator == 3)
		return operand1 * operand2;
	if (operator == 4)
		return operand1 / operand2;
	if (operator == 5)
		return operand1 & operand2;
	if (operator == 6)
		return operand1 | operand2;
	if (operator == 7)
		return operand1 % operand2;
}

//Tells precedence of the operations.
unsigned int
has_precedence(char op1, char op2) {
	if (op2 == '(' || op2 == ')')
            return 0;
        if ((op1 == '*' || op1 == '/') && (op2 == '+' || op2 == '-'))
            return 0;
	if(op2 == '&' || op2 == '|' || op2 == '%')
		return 0;
        else
            return 1;
}




// gets called whenever enter is pressed. 
// Handles Infix BODMAS Calculations.
// Tried to be wiser. 
// Use spaces in expressions.
void 
handle_line(char *line) {
	
	// Two stacks, one for operators, 
	// one for the operands.
	Stack operators,operands;

	// not being an idiot.
	init(&operators);
	init(&operators);

	char number[20];
	unsigned int i,j;

	// iterate over the whole expression.
	for( i=2 ; line[i] != '\0' ; i++ ) {

		// if it is a whitespace, let it be.
		if( is_whitespace(line[i]) ) {
			continue;
		}
		
		// if it is a number, 
		//	 push it to the operand stack.
		if( is_a_number(line[i]) ) {
			j = 0;
			while( is_a_number( line[i] ) && line[i] != '\0' ) {
				number[j++] = line[i++];
			}
			number[j] = '\0';
			push( &operands, atoi(number) );
		}
	
		// if it is an opening bracket,
		// 	push it to operator stack.
		else if(line[i] == '(')
			push( &operators, (unsigned int)line[i] );
		
		// if it is a closing bracket,
		// 	while operator stack has an opening brace
		// 		pop two operands and one operator, compute answer.
		// 		push answer to operand stack.
		// 	pop opening brace from operator stack
		else if(line[i] == ')') {
			while( peek(&operators) != (unsigned int)'(' ) {
				push( &operands, get_answer( pop(&operands), pop(&operands),
				     is_an_operator ((char) pop(&operators)) ) );
			}
			unsigned int dummy = pop( &operators );
		}
		
		//if it an operator,
		//	while the operator has precedence over the top of operator Stack
		// 		pop two operands and one operator, compute answer.
		// 		push answer to operand stack.
		//	push the operator to operator stack
		else if( is_an_operator(line[i]) ) {
			while( !is_empty( &operators ) && has_precedence(line[i],(char)peek(&operators))) {
				 push(&operands, get_answer( pop(&operands),pop(&operands),
                                     is_an_operator((char) pop(&operators))) );
			}
			push(&operators,(unsigned int)line[i]);
		}

	}
	
	// while there are operators left
	// 	pop two operands and one operator, compute answer.
	// 	push answer to operand stack.
	while ( !is_empty(&operators) ) {
		push( &operands, get_answer( pop(&operands),pop(&operands),
                                     is_an_operator((char) pop(&operators)) ) );
	}

	// There should be only one number left in the operand stack.
	// That is your answer.
	kprint(itoa(pop(&operands),number,10));
	kprint_newline();
}



// Shift Key Mappings.
char
get_key(char key) {
	if(key == '=')
		return '+';
	if(key == '1')
		return '!';
	if(key == '2')
		return '@';
	if(key == '3')
		return '#';
	if(key == '4')
		return '$';
	if(key == '5')
		return '%';
	if(key == '6')
		return '^';
	if(key == '7')
		return '&';
	if(key == '8')
		return '*';
	if(key == '9')
		return '(';
	if(key == '0')
		return ')';
	if(key == '\\') // backslash is '\' and override charecter hence \\ to produce \ .
		return '|';
	if(key == '.')
		return '>';
	if(key == ',')
		return '<';
	return key;
}

// the actual keyboard handling function. 
// keyboard_handler was just the wrapper.
void
keyboard_handler_main() {
	unsigned char status;
	char keycode;
	
	write_port(0x20, 0x20);
	
	// you read the status port to check 
	// if the device is ready or not.
	status = read_port(KEYBOARD_STATUS_PORT);

 	// condition to check - if(ready)
	if (status & 0x01) {
		// you read the keycode which is pressed.
		keycode = read_port(KEYBOARD_DATA_PORT);
		
		// invalid keycode.
		if(keycode < 0) {
			return;
		}

		//shift buttons are pressed.
		else if(keycode == 42 || keycode == 54) {
			// right shift or left shift button is pressed.
			// hence change global variable to one.
			shifted = 1;
		}

		// enter is pressed.
		// handle the whole line.
		else if(keyboard_map[keycode] == '\n') {
			kprint_newline();
			kprint(">>");	
			line[line_iterator++] = '\0';
			handle_line(line);
			kprint(">>");
			reset_line();
		}

		// Backspace is pressed.	
		else if(keyboard_map[keycode] == '\b') {
			if(current_loc - 2 >= 0)
				current_loc -= 2;
			vidptr[current_loc] = ' ';
			vidptr[current_loc + 1] = COLOR;
			line[line_iterator--] = '\0';
			if(line_iterator < 0)
				line_iterator = 0;
		}

		// if shifted in, mapping changes, right ? :P
		else if(shifted == 1) {
			shifted = 0;
			char key = get_key(keyboard_map[keycode]);
			line[line_iterator++] = key; 
			vidptr[current_loc++] = key;
			vidptr[current_loc++] = COLOR;
		}

		// any other button is pressed. 
		else {	
			line[line_iterator++] = keyboard_map[keycode]; 
			vidptr[current_loc++] = keyboard_map[keycode];
			vidptr[current_loc++] = COLOR;
		}
	}
}

void 
kmain() {
	char *str = "simple-kernel 0.8";
	char *feature = "Unsigned Int Calc.Add,Subtract,Multiply,Divide,And,Or,Mod.BODMAS.Use Spaces";
	
	clear_screen();
	kprint(str);
	kprint_newline();
	kprint(feature);
	
	kprint_newline();
	
	kprint(">>");
	idt_init();
	kb_init();
	
	// the kernel loop.	
	while(1);
}
