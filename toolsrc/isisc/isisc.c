#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>

unsigned char memory[0x4000][3];
#define	IN1	1
#define IN2	2

int getword(FILE *fp)
{
	int cl = getc(fp);
	int ch = getc(fp);
	if (cl == EOF || ch == EOF)
		return -1;
	return (ch << 8) + cl;
}

int main(int argc, char **argv)
{
	FILE *fp1, *fp2;
	int i;
    int exitCode = 0;
    int load1, load2, len, start;

	if (argc != 3) {
		fprintf(stderr, "usage: %s file1 file2\n", argv[0]);
		exit(1);
	}
	if ((fp1 = fopen(argv[1], "rb")) == NULL) {
		fprintf(stderr, "can't open %s\n", argv[1]);
		exit(2);
	}
	if ((fp2 = fopen(argv[2], "rb")) == NULL) {
		fprintf(stderr, "can't open %s\n", argv[2]);
		exit(3);
	}
	// load first file
	while (1) {
		len = getword(fp1);
		start = getword(fp1);
		if (len == 0) 
			break;
		while (len-- > 0) {
			memory[start][0] = IN1;
			memory[start++][1] = getc(fp1);
		}
	}
    load1 = start;
	fclose(fp1);
	// load second file
	while (1) {
		len = getword(fp2);
		start = getword(fp2);
		if (len == 0)
			break;
		while (len-- > 0) {
			memory[start][0] |= IN2;
			memory[start++][2] = getc(fp2);
		}
	}
    load2 = start;
	fclose(fp2);
	// now emit differences
	for (i = 0; i < 0x4000; i++) {
		switch (memory[i][0]) {
		case IN1:
			printf("%04X: %02X - XX\n", i, memory[i][1]);
            exitCode = 1;
			break;
		case IN2:
			printf("%04X: XX - %02X\n", i, memory[i][2]);
            exitCode = 1;
			break;
		case IN1 | IN2:
            if (memory[i][1] != memory[i][2]) {
                printf("%04X: %02X - %02X\n", i, memory[i][1], memory[i][2]);
                exitCode = 1;
            }
		}
	}
    if (load1 != load2) {
        printf("Load addresses different: %s(%04X) - %s(%04X)\n", argv[1], load1, argv[2], load2);
        exitCode = 1;
    }

    if (exitCode == 0)
        printf("%s equivalent to %s\n", argv[1], argv[2]);
	return exitCode;
}
